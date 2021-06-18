function Invoke-ReplotVolumeSelectionChange {
    [CmdletBinding()]
    param()

    try{
        $SelectedVolume = $FinalVolume_DataGrid.SelectedItem
        if ($SelectedVolume){
            $AddOldPlot_Grid.DataContext = $SelectedVolume
            $AddOldPlot_Grid.IsEnabled = $true
            $OldPlotDirectory_Textbox.Text = $SelectedVolume.DirectoryPath
        }
        else{
            $AddOldPlot_Grid.IsEnabled = $false
            $AddOldPlot_Grid.DataContext = $null
        }
    }
    catch{
        Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
    }
}