function Invoke-OpenReplotConfigButtonClick {
    [CmdletBinding()]
    param()

    try{
        $XAMLPath = Join-Path -Path $DataHash.WPF -ChildPath "ReplotConfigWindow.xaml"
        $ReplotConfig_Window = Import-Xaml -Path $XAMLPath

        $FinalVolume_DataGrid = $ReplotConfig_Window.FindName("FinalVolume_DataGrid")
        $FinalVolume_DataGrid.ItemsSource = $DataHash.NewJobViewModel.NewChiaJob.FinalVolumes

        $AddOldPlot_Grid = $ReplotConfig_Window.FindName("AddOldPlot_Grid")

        $FinalVolume_DataGrid.Add_SelectionChanged({
            try{
                Invoke-ReplotVolumeSelectionChange
            }
            catch{
                Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
            }
        })

        $ReplotConfig_Window.ShowDialog()
    }
    catch{
        Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
        Show-MessageBox -Text $_.Exception.Message -Icon Error -Title "Open Replot Config Error"
    }
}