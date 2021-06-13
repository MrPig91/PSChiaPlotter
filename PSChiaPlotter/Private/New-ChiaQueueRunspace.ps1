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
        Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Classes -File | ForEach-Object {Import-Module $_.FullName}
        try{
            for ($runNumber = 1;($Job.CompletedRunCount + $Job.RunsInProgress.Count) -lt $Job.TotalPlotCount;$runNumber++){
                $ChiaProcess = $Null
                if ($Queue.Quit){
                    break
                }
                if ($Queue.Pause){
                    $Queue.Status = "Paused"
                    while ($Queue.Pause){
                        if ($Queue.Quit){
                            break
                        }
                        sleep 10
                    }
                    if (($Job.CompletedRunCount + $Job.RunsInProgress.Count) -ge $Job.TotalPlotCount){
                        break
                    }
                }

                if ($Job.BasicPlotting){
                    $TempVolume = [PSChiaPlotter.ChiaVolume]::new($Queue.PlottingParameters.BasicTempDirectory)
                    $FinalVolume = [PSChiaPlotter.ChiaVolume]::new($Queue.PlottingParameters.BasicFinalDirectory)
                    $SecondTempVolume = [PSChiaPlotter.ChiaVolume]::new($Queue.PlottingParameters.BasicSecondTempDirectory)
                }
                else{
                    #grab a volume that has enough space
                    Do {
                        Try{
                            if ($Queue.Quit){
                                break
                            }
                            $TempVolume = Get-BestChiaTempDrive -ChiaVolumes $Job.TempVolumes -ChiaJob $Job -ChiaQueue $Queue
                            $FinalVolume = Get-BestChiaFinalDrive $Job.FinalVolumes -ChiaJob $Job -ChiaQueue $Queue
                            if ($TempVolume -eq $Null){
                                $Queue.Status = "Waiting on Temp Space"
                                Start-Sleep -Seconds 60
                            }
                            elseif ($FinalVolume -eq $Null){
                                $Queue.Status = "Waiting on Final Dir Space"
                                Start-Sleep -Seconds 60
                            }
                        }
                        catch{
                            $Queue.Status = "Failed To Grab Volume Info"
                            Start-Sleep -Seconds 30
                        }
                    }
                    while ($TempVolume -eq $null -or $FinalVolume -eq $null)
                    if (($Job.CompletedRunCount + $Job.RunsInProgress.Count) -ge $Job.TotalPlotCount){
                        break
                    }
                } #else
                $Queue.Status = "Running"
                $plottingParameters = [PSChiaPlotter.ChiaParameters]::New($Queue.PlottingParameters)
                $plottingParameters.TempVolume = $TempVolume
                $plottingParameters.FinalVolume = $FinalVolume
                if ($Job.BasicPlotting){
                    $plottingParameters.SecondTempVolume = $SecondTempVolume
                }
                $newRun = [PSChiaPlotter.ChiaRun]::new($Queue,$runNumber,$plottingParameters)
                
                if ($Queue.Quit){
                    break
                }
                if ($DataHash.Debug){
                    Start-GUIDebugRun -ChiaRun $newRun -ChiaQueue $Queue -ChiaJob $Job
                }
                else{
                    #Show-Object $newRun
                    Start-GUIChiaPlotting -ChiaRun $newRun -ChiaQueue $Queue -ChiaJob $Job
                }
                #sleep to give some time for updating
                sleep 2
            } #for

            $Queue.Status = "Finished"
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