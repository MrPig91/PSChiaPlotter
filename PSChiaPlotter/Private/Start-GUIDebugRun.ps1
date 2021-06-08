function Start-GUIDebugRun{
    [CmdletBinding()]
    param(
        $ChiaRun,
        $ChiaQueue,
        $ChiaJob
    )
    try{
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
        $DataHash.MainViewModel.AllRuns.Add($ChiaRun)
        $ChiaJob.RunsInProgress.Add($ChiaRun)
        
        $TempMasterVolume = $DataHash.MainViewModel.AllVolumes | where UniqueId -eq $ChiaRun.PlottingParameters.TempVolume.UniqueId
        $TempMasterVolume.CurrentChiaRuns.Add($ChiaRun)
        $FinalMasterVolume = $DataHash.MainViewModel.AllVolumes | where UniqueId -eq $ChiaRun.PlottingParameters.FinalVolume.UniqueId
        $FinalMasterVolume.PendingFinalRuns.Add($ChiaRun)
    
        $ChiaQueue.CurrentRun = $ChiaRun
        $DataHash.MainViewModel.CurrentRuns.Add($ChiaRun)
        while (-not$ChiaProcess.HasExited){
            $ChiaQueue.CurrentTime = [DateTime]::Now
            $ChiaRun.CurrentTime = [DateTime]::Now
            $ChiaRun.Progress += 5
            sleep (10 + $ChiaQueue.QueueNumber)
        }

        $TempMasterVolume.CurrentChiaRuns.Remove($ChiaRun)
        $FinalMasterVolume.PendingFinalRuns.Remove($ChiaRun)
        $ChiaJob.RunsInProgress.Remove($ChiaRun)
        $ChiaJob.CompletedRunCount++

        $ChiaRun.ExitCode = $ChiaProcess.ExitCode
        if ($ChiaProcess.ExitTime -ne $null){
            $ChiaRun.ExitTime = $ChiaProcess.ExitTime
        }
        $ChiaRun.ExitTime = $ChiaProcess.ExitTime
        if ($ChiaProcess.ExitCode -eq 0){
            $ChiaRun.Status = "Completed"
            $ChiaJob.CompletedPlotCount++
            $ChiaQueue.CompletedPlotCount++
            $DataHash.MainViewModel.CompletedRuns.Add($ChiaRun)
            Update-ChiaGUISummary -Success
        }
        else{
            $ChiaRun.Status = "Failed"
            $ChiaJob.FailedPlotCount++
            $ChiaQueue.FailedPlotCount++
            $DataHash.MainViewModel.FailedRuns.Add($ChiaRun)
        }
        $DataHash.MainViewModel.CurrentRuns.Remove($ChiaRun)
    }
    catch{
        if (-not$DataHash.MainViewModel.FailedRuns.Contains($ChiaRun)){
            $DataHash.MainViewModel.FailedRuns.Add($ChiaRun)
        }
        if ($DataHash.MainViewModel.CurrentRuns.Contains($ChiaRun)){
            $DataHash.MainViewModel.CurrentRuns.Remove($ChiaRun)
        }
        if ($ChiaJob.RunsInProgress.Contains($ChiaRun)){
            $ChiaJob.RunsInProgress.Remove($ChiaRun)
        }
        if ($FinalMasterVolume){
            if ($FinalMasterVolume.PendingFinalRuns.Contains($ChiaRun)){
                $FinalMasterVolume.PendingFinalRuns.Remove($ChiaRun)
            }
        }
        $PSCmdlet.WriteError($_)
    }
}