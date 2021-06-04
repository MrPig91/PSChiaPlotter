function Stop-PSChiaPlotter{
    [CmdletBinding()]
    param()

    $RunningQueues = $DataHash.MainViewModel.AllQueues | Where-Object Status -eq "Running"
    foreach ($Queue in $RunningQueues){
        $queue.Status = "Paused"
    }

    $ALLChiaProcesses = $DataHash.MainViewModel.CurrentRuns
    foreach ($run in $ALLChiaProcesses){
        try{
            Stop-Process $run.ProcessID
        }
        catch{
            $logParam = @{
                LogType = "Error"
                Message = $_.Exception.Message
                LineNumber = $_.InvocationInfo.ScriptLineNumber
                DebugLogPath = $DataHash.LogPath
            }
            Write-PSChiaPlotterLog @logParam
        }
    }
    $RunningRunspaces = $DataHash.Runspaces
    foreach ($runspace in $RunningRunspaces){
        try{
            $runspace.Stop()
        }
        catch{
            $logParam = @{
                LogType = "Error"
                Message = $_.Exception.Message
                LineNumber = $_.InvocationInfo.ScriptLineNumber
                DebugLogPath = $DataHash.LogPath
            }
            Write-PSChiaPlotterLog @logParam
        }
    }
}