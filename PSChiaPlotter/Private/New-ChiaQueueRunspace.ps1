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
            for ($runNumber = 1;($Job.CompletedPlotCount + $Job.RunsInProgress.Count) -lt $Job.TotalPlotCount;$runNumber++){
                $ChiaProcess = $Null
                if ($Queue.Pause){
                    $Queue.Status = "Paused"
                    while ($Queue.Pause){
                        sleep 10
                    }
                    if (($Job.CompletedPlotCount + $Job.RunsInProgress.Count) -ge $Job.TotalPlotCount){
                        break
                    }
                }

                #grab a volume that has enough space
                Do {
                    $TempVolume = Get-BestChiaTempDrive $Job.TempVolumes
                    $FinalVolume = Get-BestChiaFinalDrive $Job.FinalVolumes
                    if ($TempVolume -eq $Null){
                        $Queue.Status = "Waiting on Temp Space"
                        Start-Sleep -Seconds 60
                    }
                    elseif ($FinalVolume -eq $Null){
                        $Queue.Status = "Waiting on Final Dir Space"
                        Start-Sleep -Seconds 60
                    }
                }
                while ($TempVolume -eq $null -or $FinalVolume -eq $null)
                if (($Job.CompletedPlotCount + $Job.RunsInProgress.Count) -ge $Job.TotalPlotCount){
                    break
                }
                $Queue.Status = "Running"
                $plottingParameters = [PSChiaPlotter.ChiaParameters]::New($Queue.PlottingParameters)
                $plottingParameters.TempVolume = $TempVolume
                $plottingParameters.FinalVolume = $FinalVolume
                $newRun = [PSChiaPlotter.ChiaRun]::new($job.JobNumber,$Queue.QueueNumber,$runNumber,$plottingParameters)
                
                if ($DataHash.Debug){
                    Start-GUIDebugRun -ChiaRun $newRun -ChiaQueue $Queue -ChiaJob $Job
                }
                else{
                    #Show-Object $newRun
                    Start-GUIChiaPlotting -ChiaRun $newRun -ChiaQueue $Queue -ChiaJob $Job
                }
                #sleep to give some time for updating
                sleep 2
            }
            $Queue.Status = "Finished"
        }
        catch{
            Show-Messagebox -Text $_.Exception.Message -Title "Queue - $($Queue.QueueNumber)"
            if ($ChiaProcess){
                Show-Messagebox -Text "The Following Chia Process may be running and might need to killed - PID $($ChiaProcess.Id)" -Title "Queue"
            }
        }
    }.AddParameters($PSBoundParameters)
}