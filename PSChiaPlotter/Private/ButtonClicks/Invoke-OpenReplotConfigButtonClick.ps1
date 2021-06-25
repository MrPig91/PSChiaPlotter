function Invoke-OpenReplotConfigButtonClick {
    [CmdletBinding()]
    param()

    try{
        $XAMLPath = Join-Path -Path $DataHash.WPF -ChildPath "ReplotConfigWindow.xaml"
        $ReplotConfig_Window = Import-Xaml -Path $XAMLPath

        $FinalVolume_DataGrid = $ReplotConfig_Window.FindName("FinalVolume_DataGrid")

        if ($DataHash.NewJobViewModel.NewChiaJob.BasicPlotting){
            if ([string]::IsNullOrEmpty($DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.BasicFinalDirectory.DirectoryPath)){
                [void](Show-MessageBox -Text "Please give a valid final directory path first!" -Icon Warning)
                return
            }
            $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.BasicFinalDirectory.ReplotEnabled = $true
            $BasicVolumeList = New-Object -TypeName System.Collections.Generic.List[PSChiaPlotter.ChiaVolume]
            $BasicVolumeList.Add($DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.BasicFinalDirectory)
            $FinalVolume_DataGrid.ItemsSource = $BasicVolumeList
        }
        else{
            $DataHash.NewJobViewModel.NewChiaJob.FinalVolumes | foreach {
                $_.ReplotEnabled = $true
                $FinalVolume_DataGrid.ItemsSource = $DataHash.NewJobViewModel.NewChiaJob.FinalVolumes
            }
        }

        $AddOldPlot_Grid = $ReplotConfig_Window.FindName("AddOldPlot_Grid")
        $OldPlotDirectory_Textbox = $ReplotConfig_Window.FindName("OldPlotDirectory_Textbox")
        $OldDirectories_ListBox = $ReplotConfig_Window.FindName("OldDirectories_ListBox")

        #Button
        $AddOldPlotDirectory_Button = $ReplotConfig_Window.FindName("AddOldPlotDirectory_Button")
        $ConfirmReplot_Button = $ReplotConfig_Window.FindName("ConfirmReplot_Button")
        $CancelReplot_Button = $ReplotConfig_Window.FindName("CancelReplot_Button")
        $HelpReplot_Button = $ReplotConfig_Window.FindName("HelpReplot_Button")

        $FinalVolume_DataGrid.Add_SelectionChanged({
            try{
                Invoke-ReplotVolumeSelectionChange
            }
            catch{
                Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
            }
        })

        $AddOldPlotDirectory_Button.Add_Click({
            try{
                $PathToAdd = Invoke-AddOldPlotDirectoryButtonClick -Path $OldPlotDirectory_Textbox.Text
                if ($null -ne $PathToAdd){
                    $OldDirectories_ListBox.DataContext.OldPlotDirectories.Add($PathToAdd)
                    $OldPlotDirectory_Textbox.Text = $OldDirectories_ListBox.DataContext.DirectoryPath
                    $OldDirectories_ListBox.DataContext.TotalReplotCount = ($OldDirectories_ListBox.DataContext.OldPlotDirectories | Measure-Object -Property PlotCount -Sum).Sum
                }
            }
            catch{
                Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
            }
        })

        $ConfirmReplot_Button.Add_Click({
            try{
                $Results = Test-ReplotParameters
                if ($Results -ne $true){
                    Show-Messagebox -Text $Results -Title "Invalid Replot Parameters" -Icon Warning
                    return
                }
                $ReplotConfig_Window.Close()
            }
            catch{
                Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
            }
        })
        
        $CancelReplot_Button.Add_Click({
            try{
                Invoke-CancelReplotButtonClick
            }
            catch{
                Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
            }
        })

        $HelpReplot_Button.Add_Click({
            try{
                Invoke-HelpReplotButtonClick
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