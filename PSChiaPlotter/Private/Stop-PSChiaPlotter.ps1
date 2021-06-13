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
            Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
        }
    }
    $RunningRunspaces = $DataHash.Runspaces
    foreach ($runspace in $RunningRunspaces){
        try{
            $runspace.Stop()
        }
        catch{
            Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
        }
    }
}