function Show-ChiaPlottingStatistic{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string[]]$LogPath
    )

    $LogStats = Get-ChiaPlottingStatistic -Path $Logpath
    $newlogstats = foreach ($stat in $LogStats){
        try{
            $phase1 = New-TimeSpan -Seconds $stat.Phase_1_sec
            $phase2 = New-TimeSpan -Seconds $stat.Phase_2_sec
            $phase3 = New-TimeSpan -Seconds $stat.Phase_3_sec
            $phase4 = New-TimeSpan -Seconds $stat.Phase_4_sec
            $totaltime = New-TimeSpan -Seconds $stat.TotalTime_sec
            $copyTime = New-TimeSpan -Seconds $stat.CopyTime_sec
            $copyandplot = New-TimeSpan -Seconds $stat.PlotAndCopyTime_sec

            if ($stat.PlotId){
                $stat | Add-Member -NotePropertyMembers @{
                    Phase_1 = $phase1
                    Phase_2 = $phase2
                    Phase_3 = $phase3
                    Phase_4 = $phase4
                    PlotTime = $totaltime
                    CopyPhase = $copyTime
                    PlotAndCopy = $copyandplot
                }
                $stat
            }
        }
        catch{
            Write-Information "Unable to add time span properties"
        }
    }

    if ($logPath.Count -eq 1){
        $WPF = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath "WPFWindows"
        $XAMLPath = Join-Path -Path $WPF -ChildPath ChiaLogStats.xaml
        $ChiaLogWindow = Import-Xaml -Path $XAMLPath
        $ChiaLogWindow.DataContext = $newlogstats
        $ChiaLogWindow.ShowDialog() | Out-Null
    }
    else{
        $WPF = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath "WPFWindows"
        $XAMLPath = Join-Path -Path $WPF -ChildPath ChiaLogStatsGrid.xaml
        $ChiaLogWindow = Import-Xaml -Path $XAMLPath
        $DataGrid = $ChiaLogWindow.FindName("DataGrid")
        $DataGrid.ItemsSource = $newlogstats
        $ChiaLogWindow.ShowDialog() | Out-Null
    }
}