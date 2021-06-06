function Update-ChiaGUISummary{
    [CmdletBinding()]
    param(
        [switch]$Success,
        [switch]$Failed
    )

    if ($Success){
        $OneDayAgo = (Get-Date).AddDays(-1)
        $PlotsIn24Hrs = ($DataHash.MainViewModel.CompletedRuns | where ExitTime -GT $OneDayAgo | Measure-Object).Count
        $DataHash.MainViewModel.PlotPlottedPerDay = $PlotsIn24Hrs
        $DataHash.MainViewModel.TBPlottedPerDay = [math]::Round(($PlotsIn24Hrs * 101.4) / 1000,2)

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