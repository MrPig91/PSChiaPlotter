function Invoke-NewJobButtonClick {
    [CmdletBinding()]
    param()

    try{
        $SavedJobsPath = Join-Path -Path $ENV:LOCALAPPDATA -ChildPath 'PSChiaPlotter\SavedJobs'
        $SavedJobsList = New-Object -TypeName System.Collections.Generic.List[Object]
        if ([System.IO.Directory]::Exists($SavedJobsPath)){
            Get-ChildItem -Path $SavedJobsPath | foreach {
                try{
                    $savedjob = [pscustomobject]@{
                        Name = $_.BaseName
                        FullName = $_.FullName
                    }
                    $SavedJobsList.Add($savedjob)
                }
                catch{
                    Write-Error -LogType "Error" -ErrorObject $_
                }
            }
        }

        $XAMLPath = Join-Path -Path $DataHash.WPF -ChildPath NewJobWindow.xaml
        $UIHash.NewJob_Window = Import-Xaml -Path $XAMLPath
        $jobNumber = $DataHash.MainViewModel.AllJobs.Count + 1

        $newJob = [PSChiaPlotter.ChiaJob]::new()
        $newJob.JobNumber = $jobNumber
        $newJob.JobName = "Job $jobNumber"
        $newJob.Status = "Waiting"
        $NewJobViewModel = [PSChiaPlotter.NewJobViewModel]::new($newJob)
        $DataHash.NewJobViewModel = $NewJobViewModel
        $UIHash.NewJob_Window.DataContext = $NewJobViewModel

        #Combobox
        $KSize_ComboBox = $UIHash.NewJob_Window.FindName("KSize_ComboBox")
        $KSize_ComboBox.SelectedIndex = 1

        $SavedJobs_ComboBox = $UIHash.NewJob_Window.FindName("SavedJobs_Combobox")
        $SavedJobs_ComboBox.ItemsSource = $SavedJobsList

        #Buttons
        $AdvancedBasic_Button = $UIHash.NewJob_Window.FindName("AdvancedBasic_Button")
        $LoadJob_Button = $UIHash.NewJob_Window.FindName("LoadJob_Button")
        $CreateJob_Button = $UIHash.NewJob_Window.FindName("CreateJob_Button")
        $CancelJobCreation_Button = $UIHash.NewJob_Window.FindName("CancelJobCreation_Button")
        $SaveJob_Button = $UIHash.NewJob_Window.FindName("SaveJob_Button")
        $ClearTempVolume_Button = $UIHash.NewJob_Window.FindName("RemoveTempVolumeButton")
        $ReplotConfig_Button = $UIHash.NewJob_Window.FindName("ReplotButton")

        #TabControl
        $AdvancedPlotting_TabControl = $UIHash.NewJob_Window.FindName("AdvancedPlotting_TabControl")
        
        #Grid
        $BasicPlotting_Grid = $UIHash.NewJob_Window.FindName("BasicPlotting_Grid")

        #need to run get-chiavolume twice or the temp and final drives will be the same object in the application and will update each other...
        Get-ChiaVolume | foreach {
            $NewJobViewModel.FinalAvailableVolumes.Add($_)
        }
        $NewJobViewModel.FinalAvailableVolumes | foreach {
            $NewJobViewModel.SecondTempVolumes.Add([PSChiaPlotter.ChiaVolume]::new($_))
            $NewJobViewModel.TempAvailableVolumes.Add([PSChiaPlotter.ChiaVolume]::new($_))
        }

        $AdvancedBasic_Button.Add_Click({
            try{
                if ($AdvancedBasic_Button.Content -eq "Switch To Basic"){
                    $AdvancedBasic_Button.Content = "Switch To Advance"
                    $DataHash.NewJobViewModel.NewChiaJob.BasicPlotting = $true
                    $AdvancedPlotting_TabControl.Visibility = [System.Windows.Visibility]::Collapsed
                    $BasicPlotting_Grid.Visibility = [System.Windows.Visibility]::Visible
                }
                else{
                    $AdvancedBasic_Button.Content = "Switch To Basic"
                    $DataHash.NewJobViewModel.NewChiaJob.BasicPlotting = $false
                    $BasicPlotting_Grid.Visibility = [System.Windows.Visibility]::Collapsed
                    $AdvancedPlotting_TabControl.Visibility = [System.Windows.Visibility]::Visible
                }
            }
            catch{
                Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
            }
        })

        $LoadJob_Button.Add_Click({
            try{
                Invoke-LoadJobButtonClick
            }
            catch{
                Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
            }
        })

       $KSize_ComboBox.Add_SelectionChanged({
            try{
                $KSizeTempSize = $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.KSize.TempSize
                $KSizeFinalSize = $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.KSize.FinalSize
                $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.RAM = $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.KSize.MinRAM
                foreach ($volume in $DataHash.NewJobViewModel.TempAvailableVolumes){
                    $max = [math]::Floor([decimal]($volume.size / $KSizeTempSize))
                    $volume.MaxConCurrentTempChiaRuns = $max
                }
                foreach ($volume in $DataHash.NewJobViewModel.NewChiaJob.TempVolumes){
                    $max = [math]::Floor([decimal]($volume.size / $KSizeTempSize))
                    $volume.MaxConCurrentTempChiaRuns = $max
                }

                foreach ($volume in $DataHash.NewJobViewModel.FinalAvailableVolumes){
                    $max = [math]::Floor([decimal]($volume.FreeSpace / $KSizeFinalSize))
                    $volume.PotentialFinalPlotsRemaining = $max
                }
                foreach ($volume in $DataHash.NewJobViewModel.NewChiaJob.FinalVolumes){
                    $max = [math]::Floor([decimal]($volume.FreeSpace / $KSizeFinalSize))
                    $volume.PotentialFinalPlotsRemaining = $max
                }

                foreach ($volume in $DataHash.NewJobViewModel.SecondTempVolumes){
                    $max = [math]::Floor([decimal]($volume.size / $KSizeTempSize))
                    $volume.MaxConCurrentTempChiaRuns = $max
                }
            }
            catch{
                Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
            }
        })

        $CreateJob_Button.add_Click({
            try{
                if ($DataHash.NewJobViewModel.NewChiaJob.DelayInMinutes -eq 60){
                    $response = Show-Messagebox -Text "You left the default delay time of 60 Minutes, continue?" -Button YesNo
                    if ($response -eq [System.Windows.MessageBoxResult]::No){
                        return
                    }
                }
                if ($DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.KSize.KSizeValue -eq 25){
                    $response = Show-Messagebox -Text "KSize 25 is only for testing and cannot farm XCH, continue?" -Button YesNo -Icon Warning
                    if ($response -eq [System.Windows.MessageBoxResult]::No){
                        return
                    }
                }
                if ($DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.PoolContractEnabled){
                    $response = Show-MessageBox -Text "Portable plots are not currently supported on mainnet! This plot is not guranteed to work in the future, continue?" -Button YesNo -Icon Warning
                    if ($response -eq [System.Windows.MessageBoxResult]::No){
                        return
                    }
                }

                $Results = Test-ChiaParameters $DataHash.NewJobViewModel.NewChiaJob
                if ($Results -ne $true){
                    Show-Messagebox -Text $Results -Title "Invalid Parameters" -Icon Warning
                    return
                }
                $DataHash.MainViewModel.AllJobs.Add($DataHash.NewJobViewModel.NewChiaJob)
                $newJobRunSpace = New-ChiaJobRunspace -Job $DataHash.NewJobViewModel.NewChiaJob
                $newJobRunSpace.Runspacepool = $ScriptsHash.RunspacePool
                [void]$newJobRunSpace.BeginInvoke()
                $DataHash.Runspaces.Add($newJobRunSpace)
                $UIHash.NewJob_Window.Close()
            }
            catch{
                Write-PSChiaPlotterLog -LogType "ERROR" -ErrorObject $_
                Show-Messagebox -Text $_.Exception.Message -Title "Create New Job Error" -Icon Error
            }
        })

        $CancelJobCreation_Button.Add_Click({
            try{
                $UIHash.NewJob_Window.Close()
            }
            catch{
                Show-Messagebox -Text $_.Exception.Message -Title "Exit New Job Window Error" -Icon Error
            }
        })

        $SaveJob_Button.Add_Click({
            try{
                $PSChiaPlotterFolderPath = Join-Path -Path $ENV:LOCALAPPDATA -ChildPath 'PSChiaPlotter\SavedJobs'
                if (-not[System.IO.Directory]::Exists($PSChiaPlotterFolderPath)){
                    New-Item -Path $PSChiaPlotterFolderPath -ItemType Directory | Out-Null
                }
                if ([string]::IsNullOrWhiteSpace($DataHash.NewJobViewModel.NewChiaJob.JobName)){
                    Show-Messagebox -Text "Please give your a job a name first" | Out-Null
                    return
                }
                $SaveJobPath = Join-Path -Path $PSChiaPlotterFolderPath -ChildPath "$($DataHash.NewJobViewModel.NewChiaJob.JobName).xml"
                if (Test-Path $SaveJobPath){
                    $Response = Show-MessageBox -Text "Job $($DataHash.NewJobViewModel.NewChiaJob.JobName) already exists, would you like to overwrite it?" -Buttons YesNo
                    if ($Response -eq [System.Windows.MessageBoxResult]::Yes){
                        $DataHash.NewJobViewModel | Export-Clixml -Path $SaveJobPath -Depth 10 -Force
                        Show-MessageBox "$($DataHash.NewJobViewModel.NewChiaJob.JobName) job saved to $PSChiaPlotterFolderPath"
                        return
                    }
                }
                $DataHash.NewJobViewModel | Export-Clixml -Path $SaveJobPath -Depth 10
                Show-MessageBox "$($DataHash.NewJobViewModel.NewChiaJob.JobName) job saved to $PSChiaPlotterFolderPath"
            }
            catch{
                Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
            }
        })

        $ClearTempVolume_Button.Add_Click({
            try{
                $tempVolume = $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.SecondTempVolume
                if ($tempVolume -ne $Null){
                    Write-PSChiaPlotterLog -LogType "INFO" -Message "Clearing Temp Volume Selection"
                    $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.SecondTempVolume = $null
                }
            }
            catch{
                Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
            }
        })

        $ReplotConfig_Button.Add_Click({
            try{
                Invoke-OpenReplotConfigButtonClick
            }
            catch{
                Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
                Show-MessageBox -Text $_.Exception.Message -Icon Error -Title "Open Replot Config Error"
            }
        })

        $UIHash.NewJob_Window.ShowDialog()
    }
    catch{
        Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
        Show-Messagebox -Text $_.Exception.Message -Title "Create New Job Error" -Icon Error
    }
}