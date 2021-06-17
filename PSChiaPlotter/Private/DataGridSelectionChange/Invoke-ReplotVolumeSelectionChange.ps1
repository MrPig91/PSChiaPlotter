function Invoke-ReplotVolumeSelectionChange {
    [CmdletBinding()]
    param()

    try{
        $SelectedVolume = $FinalVolume_DataGrid.SelectedItem
        if ($SelectedVolume){
            $AddOldPlot_Grid.DataContext = $SelectedVolume
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