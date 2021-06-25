function Invoke-LoadJobButtonClick {
    [CmdletBinding()]
    param()

    try{
        $JobFilePath = $SavedJobs_ComboBox.SelectedValue
        if (($null -ne $JobFilePath) -and (Test-Path $JobFilePath)){

            #Have to transfer the properties over since the imported job is Desesersilzed Object

            $ImportedJob = Import-Clixml -Path $JobFilePath
            Write-PSChiaPlotterLog -LogType "INFO" -Message "Imported Job"

            $newSavedJob = [PSChiaPlotter.ChiaJob]::new()
            $newSavedJob.JobNumber = $jobNumber
            $newSavedJob.Status = "Waiting"
            $NewSavedJobViewModel = [PSChiaPlotter.NewJobViewModel]::new($newSavedJob)

            $SkipJobProperties = @("InitialChiaParameters","Queues","RunsInProgress","TempVolumes","FinalVolumes")
            $JobProperties = ($ImportedJob.NewChiaJob | Get-Member -MemberType Property).Name
            $JobProperties = $JobProperties | where {$_ -notin $SkipJobProperties}
            foreach ($property in $JobProperties){
                try{
                    $NewSavedJobViewModel.NewChiaJob.$property = $ImportedJob.NewChiaJob.$property
                }
                catch{
                    Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
                }
            }

            $SkipParameterProperties = @("SecondTempVolume","KSize","BasicFinalDirectory","BasicTempDirectory")
            $ParameterProperties = ($ImportedJob.NewChiaJob.InitialChiaParameters | Get-Member -MemberType Property).Name
            $ParameterProperties = $ParameterProperties | where {$_ -notin $SkipParameterProperties}
            foreach ($property in $ParameterProperties){
                try{
                    $NewSavedJobViewModel.NewChiaJob.InitialChiaParameters.$property = $ImportedJob.NewChiaJob.InitialChiaParameters.$property
                }
                catch{
                    Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
                }
            }

            $NewSavedJobViewModel.NewChiaJob.JobNumber = $jobNumber
            $NewSavedJobViewModel.NewChiaJob.Status = "Waiting"
            $NewSavedJobViewModel.NewChiaJob.StartTime = Get-Date

            Get-ChiaVolume | foreach {
                $NewSavedJobViewModel.FinalAvailableVolumes.Add($_)
            }
            $NewSavedJobViewModel.FinalAvailableVolumes | foreach {
                $NewSavedJobViewModel.SecondTempVolumes.Add([PSChiaPlotter.ChiaVolume]::new($_))
                $NewSavedJobViewModel.TempAvailableVolumes.Add([PSChiaPlotter.ChiaVolume]::new($_))
            }

            #need to update directory paths for each volume...
            $NewSavedJobViewModel.TempAvailableVolumes | foreach {
                $FoundVolume = $ImportedJob.TempAvailableVolumes | where UniqueId -eq $_.UniqueId
                if ($FoundVolume -ne $Null){
                    $_.DirectoryPath = $FoundVolume.DirectoryPath
                }
                else{
                    $FoundVolume = $ImportedJob.NewChiaJob.TempVolumes | where UniqueId -eq $_.UniqueId
                    if ($FoundVolume -ne $Null){
                        $_.DirectoryPath = $FoundVolume.DirectoryPath
                    }
                }
                $FoundVolume = $Null
            }
            $NewSavedJobViewModel.FinalAvailableVolumes | foreach {
                $FoundVolume = $ImportedJob.FinalAvailableVolumes | where UniqueId -eq $_.UniqueId
                if ($FoundVolume -ne $Null){
                    $_.DirectoryPath = $FoundVolume.DirectoryPath
                }
                else{
                    $FoundVolume = $ImportedJob.NewChiaJob.FinalVolumes | where UniqueId -eq $_.UniqueId
                    if ($FoundVolume -ne $Null){
                        $_.DirectoryPath = $FoundVolume.DirectoryPath
                    }
                }
                $FoundVolume = $Null
            }
            $NewSavedJobViewModel.SecondTempVolumes | foreach {
                $FoundVolume = $ImportedJob.SecondTempVolumes | where UniqueId -eq $_.UniqueId
                if ($FoundVolume -ne $Null){
                    $_.DirectoryPath = $FoundVolume.DirectoryPath
                }
                $FoundVolume = $Null
            }

            #Basic Volumes
            $FinalDirString = [string]$ImportedJob.NewChiaJob.InitialChiaParameters.BasicFinalDirectory.DirectoryPath
            $TempDirString = [string]$ImportedJob.NewChiaJob.InitialChiaParameters.BasicTempDirectory.DirectoryPath
            $NewSavedJobViewModel.NewChiaJob.InitialChiaParameters.BasicFinalDirectory = [PSChiaPlotter.ChiaVolume]::new($FinalDirString)
            $NewSavedJobViewModel.NewChiaJob.InitialChiaParameters.BasicFinalDirectory.ReplotEnabled = $ImportedJob.NewChiaJob.InitialChiaParameters.BasicFinalDirectory.ReplotEnabled
            $NewSavedJobViewModel.NewChiaJob.InitialChiaParameters.BasicTempDirectory = [PSChiaPlotter.ChiaVolume]::new($TempDirString)

            if ($ImportedJob.NewChiaJob.InitialChiaParameters.ReplotEnabled){
                foreach ($replotVolume in $ImportedJob.NewChiaJob.FinalVolumes){
                    $FoundFinalVolume = $Null
                    $FoundFinalVolume = $NewSavedJobViewModel.FinalAvailableVolumes | where UniqueId -eq $replotVolume.UniqueId
                    if ($null -ne $FoundFinalVolume){
                        foreach ($oldplotdirectory in $replotVolume.OldPlotDirectories){
                            try{
                                $totaloldplots = (Get-ChildItem -Path $oldplotdirectory.Path -Filter "plot-k$($oldplotdirectory.KSizeValue)*.plot" | Measure-Object).Count
                                $oldplot = [PSChiaPlotter.OldPlotDirectory]::New($oldplotdirectory.Path,$totaloldplots,$oldplotdirectory.KSizeValue)
                                $FoundFinalVolume.OldPlotDirectories.Add($oldplot)
                            }
                            catch{
                                Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
                            }
                        }
                    }
                    else{
                        $FoundFinalVolume = $NewSavedJobViewModel.FinalVolumes | where UniqueId -eq $replotVolume.UniqueId
                        if ($null -ne $FoundFinalVolume){
                            foreach ($oldplotdirectory in $replotVolume.OldPlotDirectories){
                                try{
                                    $totaloldplots = (Get-ChildItem -Path $oldplotdirectory.Path -Filter "plot-k$($oldplotdirectory.KSizeValue)*.plot" | Measure-Object).Count
                                    $oldplot = [PSChiaPlotter.OldPlotDirectory]::New($oldplotdirectory.Path,$totaloldplots,$oldplotdirectory.KSizeValue)
                                    $FoundFinalVolume.OldPlotDirectories.Add($oldplot)
                                }
                                catch{
                                    Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
                                }
                            }
                        }
                    }
                    $FoundFinalVolume.TotalReplotCount = ($FoundFinalVolume.OldPlotDirectories | Measure-Object -Property PlotCount -Sum).Sum
                } #foreach final volume

                foreach ($oldplotdirectory in $ImportedJob.NewChiaJob.InitialChiaParameters.BasicFinalDirectory.OldPlotDirectories){
                    try{
                        $totaloldplots = (Get-ChildItem -Path $oldplotdirectory.Path -Filter "plot-k$($oldplotdirectory.KSizeValue)*.plot" | Measure-Object).Count
                        $oldplot = [PSChiaPlotter.OldPlotDirectory]::New($oldplotdirectory.Path,$totaloldplots,$oldplotdirectory.KSizeValue)
                        $NewSavedJobViewModel.NewChiaJob.InitialChiaParameters.BasicFinalDirectory.OldPlotDirectories.Add($oldplot)
                    }
                    catch{
                        Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
                    }
                }
                $NewSavedJobViewModel.NewChiaJob.InitialChiaParameters.BasicFinalDirectory.TotalReplotCount = ($NewSavedJobViewModel.NewChiaJob.InitialChiaParameters.BasicFinalDirectory.OldPlotDirectories | Measure-Object -Property PlotCount -Sum).Sum
            }

            $NewSavedJobViewModel.AvailableKSizes = $DataHash.NewJobViewModel.AvailableKSizes

            $SecondTempVolume = $NewSavedJobViewModel.SecondTempVolumes | where UniqueId -eq $ImportedJob.NewChiaJob.InitialChiaParameters.SecondTempVolume.UniqueId
            $NewSavedJobViewModel.NewChiaJob.InitialChiaParameters.SecondTempVolume = $SecondTempVolume

            foreach ($Volume in $ImportedJob.NewChiaJob.TempVolumes){
                $FoundTempVolume = $NewSavedJobViewModel.TempAvailableVolumes | where UniqueId -eq $Volume.UniqueId
                if ($FoundTempVolume){
                    $NewSavedJobViewModel.AddTempVolume($FoundTempVolume)
                }
                $FoundTempVolume = $null
            }
            $Volume = $null
            foreach ($Volume in $ImportedJob.NewChiaJob.FinalVolumes){
                $FoundFinalVolume = $NewSavedJobViewModel.FinalAvailableVolumes | where UniqueId -eq $Volume.UniqueId
                if ($FoundFinalVolume){
                    $NewSavedJobViewModel.AddFinalVolume($FoundFinalVolume)
                    if ($volume.ReplotEnabled){
                        $FoundFinalVolume.ReplotEnabled = $true
                    }
                }
                $FoundFinalVolume = $null
            }

            $DataHash.NewJobViewModel = $NewSavedJobViewModel
            $UIHash.NewJob_Window.DataContext = $NewSavedJobViewModel

            #Combobox wouldn't automatically update for some reason
            switch ($ImportedJob.NewChiaJob.InitialChiaParameters.KSize.KSizeValue){
                25 {$Index = 0;break}
                32 {$Index = 1;break}
                33 {$Index = 2;break}
                34 {$Index = 3;break}
                35 {$Index = 4;break}
                default {$Index = 1}
            }
            $UIHash.KSize_ComboBox.SelectedIndex = $Index
            $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.KSize = $UIHash.KSize_ComboBox.SelectedItem
            $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.RAM = $ImportedJob.NewChiaJob.InitialChiaParameters.RAM

            if ($DataHash.NewJobViewModel.NewChiaJob.BasicPlotting){
                $AdvancedBasic_Button.Content = "Switch To Advance"
                $AdvancedPlotting_TabControl.Visibility = [System.Windows.Visibility]::Collapsed
                $BasicPlotting_Grid.Visibility = [System.Windows.Visibility]::Visible
            }
            else{
                $AdvancedBasic_Button.Content = "Switch To Basic"
                $BasicPlotting_Grid.Visibility = [System.Windows.Visibility]::Collapsed
                $AdvancedPlotting_TabControl.Visibility = [System.Windows.Visibility]::Visible
            }
        }
    }
    catch{
        Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
        Show-MessageBox -Text "Unable to laod previous job :( Check logs for more info"
    }
}