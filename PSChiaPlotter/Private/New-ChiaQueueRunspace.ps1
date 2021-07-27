function New-ChiaQueueRunspace {
    param(
        [Parameter(Mandatory)]
        $Queue,
        $Job
    )
    [powershell]::Create().AddScript{
        Param (
            $Job,
            $Queue
        )
        $ErrorActionPreference = "Stop"
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName System.Windows.Forms

        #Import required assemblies and private functions
        Get-childItem -Path $DataHash.PrivateFunctions -File -Recurse | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Classes -File | ForEach-Object {Import-Module $_.FullName}
        try{
            for ($runNumber = 1;Test-PlotCount $Job;$runNumber++){
                $ChiaProcess = $Null

                while ($Queue.IsBlocked -or $Queue.Pause){
                    if ($Queue.Quit){
                        break
                    }
                    if (Test-PlotCount $Job -BreakLoop){
                        break
                    }
                    if ($Queue.Pause){
                        $Queue.Status = "Paused"
                    }
                    else{
                        $Queue.Status = "Waiting"
                    }
                    Start-Sleep -Seconds 10
                }
                $Job.QueueLooping = $true;
                $Queue.IsBlocked = $false

                if ($Job.BasicPlotting){
                    $TempVolume = $Queue.PlottingParameters.BasicTempDirectory
                    $FinalVolume = $Queue.PlottingParameters.BasicFinalDirectory
                    if ($Queue.PlottingParameters.EnableBasicSecondTempDirectory){
                        $SecondTempVolume = [PSChiaPlotter.ChiaVolume]::new($Queue.PlottingParameters.BasicSecondTempDirectory)
                    }
                    $PhaseOneIsOpen = Test-PhaseOneIsOpen -ChiaJob $Job
                    while ($PhaseOneIsOpen -eq $false){
                        $Queue.Status = "Waiting - Phase 1 Limit"
                        if (Test-PlotCount $Job -BreakLoop){
                            break
                        }
                        if ($Queue.Quit){
                            break
                        }
                        Start-Sleep -Seconds 15
                        $PhaseOneIsOpen = Test-PhaseOneIsOpen -ChiaJob $Job
                    }
                }
                else{
                    #grab a volume that has enough space
                    Do {
                        Try{
                            if ($Queue.Quit){
                                break
                            }
                            if (Test-PlotCount $Job -BreakLoop){
                                break
                            }
                            Start-Sleep -Seconds 6
                            $PhaseOneIsOpen = Test-PhaseOneIsOpen -ChiaJob $Job
                            if (-not$PhaseOneIsOpen){
                                $Queue.Status = "Waiting - Phase 1 Limit"
                                Start-Sleep -Seconds 17
                                #do not need to check the drives if phase 1 is not open for another plot
                                continue
                            }

                            $TempVolume = Get-BestChiaTempDrive -ChiaVolumes $Job.TempVolumes -ChiaJob $Job -ChiaQueue $Queue
                            $FinalVolume = Get-BestChiaFinalDrive $Job.FinalVolumes -ChiaJob $Job -ChiaQueue $Queue
                            if ($TempVolume -eq $Null){
                                $Queue.Status = "Waiting on Temp Space"
                                Start-Sleep -Seconds 60
                            }
                            if ($FinalVolume -eq $Null){
                                $Queue.Status = "Waiting on Final Dir Space"
                                Start-Sleep -Seconds 60
                            }
                        }
                        catch{
                            $Queue.Status = "Failed To Grab Volume Info"
                            Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
                            Start-Sleep -Seconds 30
                        }
                    }
                    while ($TempVolume -eq $null -or $FinalVolume -eq $null -or $PhaseOneIsOpen -eq $false)
                } #else

                $Job.QueueLooping = $false
                $BlockedQueue = $Job.Queues | where {$_.IsBlocked -and !$_.Pause} | sort QueueNumber | select -First 1
                if ($BlockedQueue -ne $Null){
                    $BlockedQueue.IsBlocked = $false
                    $BlockedQueue = $null
                }
                if (Test-PlotCount $Job -BreakLoop){
                    break
                }
                if ($Queue.Quit){
                    break
                }

                $Queue.Status = "Running"
                $plottingParameters = [PSChiaPlotter.ChiaParameters]::New($Queue.PlottingParameters)
                $plottingParameters.TempVolume = $TempVolume
                $plottingParameters.FinalVolume = $FinalVolume
                if ($Job.BasicPlotting -and $Queue.PlottingParameters.EnableBasicSecondTempDirectory){
                    $plottingParameters.SecondTempVolume = $SecondTempVolume
                }
                $newRun = [PSChiaPlotter.ChiaRun]::new($Queue,$runNumber,$plottingParameters)
                if ($DataHash.Debug){
                    Start-GUIDebugRun -ChiaRun $newRun -ChiaQueue $Queue -ChiaJob $Job
                }
                else{
                    Start-GUIChiaPlotting -ChiaRun $newRun -ChiaQueue $Queue -ChiaJob $Job
                }

                $QueuesBlocked = ($Job.Queues | where {$_.IsBlocked -and !$_.pause} | Measure-Object).Count
                if ($QueuesBlocked -eq 0 -and $Job.QueueLooping -eq $false -and !$Queue.Pause){
                    $Queue.IsBlocked = $false
                }
                else{
                    $Queue.IsBlocked = $true
                }
                #sleep to give some time for updating
                sleep 2
            } #for
            $Queue.IsBlocked = $false

            $Queue.Status = "Finished"
            if ($Job.PlotInfinite -eq $true){
                $QueueFinishedCount = ($Job.Queues | where Status -ne "Finished" | Measure-Object).Count
                if ($QueueFinishedCount -eq 0){
                    $Job.Status = "Completed"
                }
            }
        }
        catch{
            Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
            Show-Messagebox -Text $_.Exception.Message -Title "Queue - $($Queue.QueueNumber)" | Out-Null
            if ($ChiaProcess){
                Show-Messagebox -Text "The Following Chia Process may be running and might need to killed - PID $($ChiaProcess.Id)" -Title "Queue" | Out-Null
            }
            $Queue.Status = "Failed"
        }
    }.AddParameters($PSBoundParameters)
}
