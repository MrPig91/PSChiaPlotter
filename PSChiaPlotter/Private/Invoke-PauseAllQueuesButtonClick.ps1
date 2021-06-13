function Invoke-PauseAllQueuesButtonClick {
    [CmdletBinding()]
    param()

    try{
        $Message = "Pausing Queues does not end the current running chia process."
        $message += " It will only prevent new processes from starting."
        $message += "`n`nAre you sure you want to pause all queues?"
        $Response = Show-MessageBox -Text $message -Buttons YesNo -Icon Information
        if ($Response -eq [System.Windows.MessageBoxResult]::Yes){
            $AllCurrentQueues = $DataHash.MainViewModel.AllQueues | where Status -ne "Finished"
            foreach ($queue in $AllCurrentQueues){
                $queue.Pause = $true
                $queue.Status = "Pending Pause"
            }
        }
    }
    catch{
        Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
    }
}