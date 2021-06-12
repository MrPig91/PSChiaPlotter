function Invoke-LoadJobButtonClick {
    [CmdletBinding()]
    param()

    try{
        $JobFilePath = $SavedJobs_ComboBox.SelectedValue
        if (($JobFilePath -ne $null) -and (Test-Path $JobFilePath)){

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

            $SkipParameterProperties = @("SecondTempVolume","KSize")
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

            $NewSavedJobViewModel.AvailableKSizes = $NewJobViewModel.AvailableKSizes

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
                $FoundTempVolume = $NewSavedJobViewModel.FinalAvailableVolumes | where UniqueId -eq $Volume.UniqueId
                if ($FoundTempVolume){
                    $NewSavedJobViewModel.AddFinalVolume($FoundTempVolume)
                }
                $FoundTempVolume = $null
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
            $KSize_ComboBox.SelectedIndex = $Index
            $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.RAM = $ImportedJob.NewChiaJob.InitialChiaParameters.RAM
        }
    }
    catch{
        Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
        Show-MessageBox -Message "Unable to laod previous job :( Check logs for more info"
    }
}