function Stop-PSChiaPlotter{
    [CmdletBinding()]
    param(
        [switch]$EndChiaProcess
    )

    $RunningQueues = $DataHash.MainViewModel.AllQueues | Where-Object Status -eq "Running"
    foreach ($Queue in $RunningQueues){
        $queue.Status = "Paused"
    }

    if ($EndChiaProcess){
        $ALLChiaProcesses = $DataHash.MainViewModel.CurrentRuns
        foreach ($run in $ALLChiaProcesses){
            try{
                Stop-Process $run.ProcessID
            }
            catch{
                Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
            }
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