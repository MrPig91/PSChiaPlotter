function Invoke-QueueSelectionChange{
    [CmdletBinding()]
    param()

    try{
        $SelectedQueue = $UIHash.Queues_DataGrid.SelectedItem
        if ($SelectedQueue){
            $UIHash.PauseQueue_Button.Content = $SelectedQueue.ButtonContent
            $UIHash.PauseQueue_Button.IsEnabled = $SelectedQueue.ButtonEnabled
            $UIHash.QuitQueue_Button.IsEnabled = $SelectedQueue.QuitButtonEnabled
        }
    }
    catch{
        Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
    }
}