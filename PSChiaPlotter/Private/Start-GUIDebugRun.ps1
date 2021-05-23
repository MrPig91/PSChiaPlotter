function Start-GUIDebugRun{
    [CmdletBinding()]
    param(
        $ChiaRun,
        $ChiaQueue,
        $ChiaJob
    )
    $PlottingParameters = $ChiaRun.PlottingParameters
    $KSize = $PlottingParameters.KSize
    $Buffer = $PlottingParameters.RAM
    $Threads = $PlottingParameters.Threads
    $DisableBitfield = $PlottingParameters.DisableBitField
    $ExcludeFinalDirectory = $PlottingParameters.ExcludeFinalDirectory
    $TempDirectoryPath = $PlottingParameters.TempVolume.DirectoryPath
    $FinalDirectoryPath = $PlottingParameters.FinalVolume.DirectoryPath
    $LogDirectoryPath = $PlottingParameters.LogDirectory
    $SecondTempDirecoryPath = $PlottingParameters.TempVolume.DirectoryPath

    $E = if ($DisableBitfield){"-e"}
    $X = if ($ExcludeFinalDirectory){"-x"}

    if (Test-Path $LogDirectoryPath){
        $LogPath = Join-Path $LogDirectoryPath ((Get-Date -Format yyyy_MM_dd_hh-mm-ss-tt_) + "plotlog" + ".log")
    }
    $ChiaProcess = start-process -filepath notepad.exe -PassThru -RedirectStandardOutput $LogPath
    $handle = $ChiaProcess.Handle
    $ChiaRun.ChiaProcess = $ChiaProcess
    $ChiaRun.ProcessId = $ChiaProcess.Id
    $ChiaJob.RunsInProgress.Add($ChiaRun)
    $TempVolume.CurrentChiaRuns.Add($ChiaRun)
    
    $TempMasterVolume = $DataHash.MainViewModel.AllVolumes | where DriveLetter -eq $ChiaRun.PlottingParameters.TempVolume.DriveLetter
    $TempMasterVolume.CurrentChiaRuns.Add($ChiaRun)
    $FinalMasterVolume = $DataHash.MainViewModel.AllVolumes | where DriveLetter -eq $ChiaRun.PlottingParameters.FinalVolume.DriveLetter
    $FinalMasterVolume.PendingPlots++

    $ChiaQueue.CurrentRun = $ChiaRun
    $DataHash.MainViewModel.CurrentRuns.Add($ChiaRun)
    while (-not$ChiaProcess.HasExited){
        $ChiaQueue.CurrentTime = [DateTime]::Now
        $ChiaRun.CurrentTime = [DateTime]::Now
        $ChiaRun.Progress += 5
        sleep (10 + $ChiaQueue.QueueNumber)
    }
    $TempMasterVolume.CurrentChiaRuns.Remove($ChiaRun)
    $FinalMasterVolume.PendingPlots--
    $ChiaJob.RunsInProgress.Remove($ChiaRun)
    $ChiaJob.CompletedPlotCount++
    $ChiaRun.ExitCode = $ChiaProcess.ExitCode
    $ChiaRun.ExitTime = $ChiaProcess.ExitTime
    if ($ChiaProcess.ExitCode -eq 0){
        $ChiaRun.Status = "Completed"
        $DataHash.MainViewModel.CompletedRuns.Add($ChiaRun)
    }
    else{
        $ChiaRun.Status = "Failed"
        $DataHash.MainViewModel.FailedRuns.Add($ChiaRun)
    }
    $ChiaQueue.CompletedPlotCount++
    $DataHash.MainViewModel.CurrentRuns.Remove($ChiaRun)
}