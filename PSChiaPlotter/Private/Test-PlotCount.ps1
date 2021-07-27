function Test-PlotCount {
    [CmdletBinding()]
    param(
        $CurrentJob,
        [switch]$BreakLoop
    )

    if ($BreakLoop){
        (($CurrentJob.CompletedRunCount + $CurrentJob.RunsInProgress.Count) -ge $CurrentJob.TotalPlotCount) -and ($CurrentJob.PlotInfinite -eq $false)
    }
    else{
        (($CurrentJob.CompletedRunCount + $CurrentJob.RunsInProgress.Count) -lt $CurrentJob.TotalPlotCount) -or ($CurrentJob.PlotInfinite -eq $true)
    }
}