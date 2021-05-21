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
                $Queue.Status = "Running"

                $TempVolume = Get-BestChiaTempDrive $Job.TempVolumes
                $FinalVolume = Get-BestChiaTempDrive $Job.FinalVolumes
                $plottingParameters = [PSChiaPlotter.ChiaParameters]::New($Queue.PlottingParameters)
                $plottingParameters.TempVolume = $TempVolume
                $plottingParameters.FinalVolume = $FinalVolume
                $newRun = [PSChiaPlotter.ChiaRun]::new($job.JobNumber,$Queue.QueueNumber,$runNumber,$plottingParameters)
                if ($DataHash.Debug){
                    $ChiaProcess = start-process -filepath notepad.exe -PassThru
                    $newRun.ChiaProcess = $ChiaProcess
                    $newRun.ProcessId = $ChiaProcess.Id
                    $Job.RunsInProgress.Add($newRun)
                    $TempVolume.CurrentChiaRuns.Add($newRun)
                    #$FinalVolume.CurrentChiaRuns.Add($newRun)
                    $Queue.CurrentRun = $newRun
                    $DataHash.MainViewModel.CurrentRuns.Add($newRun)
                    while (-not$ChiaProcess.HasExited){
                        $Queue.CurrentTime = [DateTime]::Now
                        $newRun.CurrentTime = [DateTime]::Now
                        $newRun.Progress += 5
                        sleep (10 + $Queue.QueueNumber)
                    }
                    $Job.RunsInProgress.Remove($newRun)
                    $Job.CompletedPlotCount++
                    $newRun.ExitCode = $ChiaProcess.ExitCode
                    $newRun.ExitTime = $ChiaProcess.ExitTime
                    if ($ChiaProcess.ExitCode -eq 0){
                        $newRun.Status = "Completed"
                    }
                    else{
                        $newRun.Status = "Failed"
                    }
                    $Queue.CompletedPlotCount++
                    $DataHash.MainViewModel.CurrentRuns.Remove($newRun)
                    $DataHash.MainViewModel.CompletedRuns.Add($newRun)
                    #sleep to give some time for updating
                    sleep 2
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