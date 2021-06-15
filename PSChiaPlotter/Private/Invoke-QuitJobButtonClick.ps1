function Invoke-QuitJobButtonClick{
    [CmdletBinding()]
    param()

    try{
        $SelectedJob = $Null
        $SelectedJob = $UIHash.Jobs_DataGrid.SelectedItem
        if ($SelectedJob){
            if ($SelectedJob.Status -eq "Completed" -or $SelectedJob.Status -eq "Quitting"){
                Show-MessageBox -Text "This Job is either completed or in the process of quitting" -Icon Information
                return
            }
            $Message = "Are you sure you want to quit job - $($SelectedJob.JobName)?"
            $Message += "`nAll running chia processes under this job will be cancelled!"
            $Response = Show-MessageBox -Text $Message -Buttons YesNo
            if ($Response -eq [System.Windows.MessageBoxResult]::Yes){
                $runningQueues = $SelectedJob.Queues | where Status -ne "Finished"
                foreach ($queue in $runningQueues){
                    $queue.Quit = $true
                    $queue.Status = "Quitting"
                }
                foreach ($run in $SelectedJob.RunsInProgress){
                    $run.ChiaProcess.Kill()
                }
                $SelectedJob.Status = "Completed"
            }
        }
        else{
            Show-MessageBox -Text "No Job Selected!" -Icon Warning
        }
    }
    catch{
        Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
    }
}