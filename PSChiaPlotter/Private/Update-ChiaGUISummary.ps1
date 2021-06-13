function Update-ChiaGUISummary{
    [CmdletBinding()]
    param(
        [switch]$Success,
        [switch]$Failed
    )

    if ($Success){
        $OneDayAgo = (Get-Date).AddDays(-1)
        $PlotsIn24Hrs = $DataHash.MainViewModel.CompletedRuns | where ExitTime -GT $OneDayAgo
        $DataHash.MainViewModel.PlotPlottedPerDay = ($PlotsIn24Hrs | Measure-Object).Count
        $totalTBPlotted = 0
        foreach ($plot in $PlotsIn24Hrs){
            $totalTBPlotted += ($plot.PlottingParameters.KSize.FinalSize / 1gb)
        }
        $DataHash.MainViewModel.TBPlottedPerDay = [math]::Round($totalTBPlotted / 1000,2)

        $SortedRuns = $DataHash.MainViewModel.CompletedRuns | Sort-Object -Property Runtime
        $Fastest = $SortedRuns | Select-Object -First 1
        $Slowest = $SortedRuns | Select-Object -Last 1
        $Average = $SortedRuns.RunTime | Measure-Object -Property TotalSeconds -Average

        if ($Fastest){
            $DataHash.MainViewModel.FastestRun = $Fastest.Runtime
        }
        if ($Slowest){
            $DataHash.MainViewModel.SlowestRun = $Slowest.Runtime
        }
        if ($Average){
            $AverageRun = New-TimeSpan -Seconds $Average.Average
            $DataHash.MainViewModel.AverageTime = $AverageRun
        }
    }
}