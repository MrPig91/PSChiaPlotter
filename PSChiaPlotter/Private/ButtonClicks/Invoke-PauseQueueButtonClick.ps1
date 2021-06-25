function Invoke-PauseQueueButtonClick{
    [CmdletBinding()]
    param()

    try{
        $SelectedQueue = $UIHash.Queues_DataGrid.SelectedItem
        $Pauseable = $SelectedQueue.Status -eq "Running" -or $SelectedQueue.Status -eq "Waiting" -or $SelectedQueue.Pause
        if ($SelectedQueue -ne $Null){
            if ($Pauseable){
                $SelectedQueue.PauseResumeQueue()
                $UIHash.PauseQueue_Button.Content = $SelectedQueue.ButtonContent
            }
            else{
                Show-MessageBox -Text "Only Queues that are currenting running or waiting can be paused" -Icon Warnin
            }
        }
        else{
            Show-MessageBox -Text "No Queue was selected!" -Icon Warning
        }
    }
    catch{
        Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
        Show-MessageBox -Text "Unable To Pause Queue! Check logs for more info" -Icon Error
    }
}