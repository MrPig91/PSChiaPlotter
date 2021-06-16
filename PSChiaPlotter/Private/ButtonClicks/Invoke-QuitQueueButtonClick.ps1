function Invoke-QuitQueueButtonClick{
    [CmdletBinding()]
    param()

    try{
        $SelectedQueue = $UIHash.Queues_DataGrid.SelectedItem
        if ($SelectedQueue){
            if ($SelectedQueue.Status -ne "Finished"){
                $SelectedQueue.QuitQueue()
                $UIHash.QuitQueue_Button.IsEnabled = $false
                $UIHash.PauseQueue_Button.IsEnabled = $false
            }
            else{
                Show-MessageBox -Text "Queue has already Finished!" -Icon Information
            }
        }
        else{
            Show-MessageBox -Text "No Queue was selected!" -Icon Warning
        }
    }
    catch{
        Show-MessageBox -Text "Unable To Quit Queue. Check logs for more info!" -Icon Error
        Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
    }
}