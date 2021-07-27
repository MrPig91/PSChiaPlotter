function Invoke-RemovePlotLogDirectoryButtonClick {
    [CmdletBinding()]
    param()

    try{
        if ($null -ne $UIHash.PlotLog_ListBox.SelectedItem){
            $SelectedPath = $UIHash.PlotLog_ListBox.SelectedItem
            $DataHash.MainViewModel.PlotLogDirectoryPaths.Remove($UIHash.PlotLog_ListBox.SelectedItem)
            $RemoveItems = $DataHash.MainViewModel.AllPlottingLogStats | where ParentFolder -eq $SelectedPath
            foreach ($removelogstat in $RemoveItems){
                $DataHash.MainViewModel.AllPlottingLogStats.Remove($removelogstat)
            }
        }
        else{
            [void](Show-MessageBox -Text "Please select a directory to remove" -Icon Warning)
        }
    }
    catch{
        Write-PSChiaPlotterLog -LogType Error -ErrorObject $_
        [void](Show-MessageBox -Text $_.Exception.Message -Title "Remove Directory Error" -Icon Error)
    }
}