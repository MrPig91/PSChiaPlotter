function Start-ChiaHarvesterWatcher {
    [CmdletBinding()]
    param(
        [string]$DebugLogFilePath = (Get-ChildItem -Path "$ENV:USERPROFILE\.chia\mainnet\log" -filter "debug.log").FullName,
        [ValidateRange(1,1000)]
        [int]$Sensitivity = 1,
        [Parameter()]
        [ValidateScript({[System.IO.Directory]::Exists((Split-Path -Path $_ -Parent))})]
        [string]$ExportCSVPath
    )

    if ($PSBoundParameters.ContainsKey("ExportCSVPath")){
        if (-not($ExportCSVPath.EndsWith('.csv'))){
            Write-Warning "Export CSV Path does not end with .csv, please provide a valid CSV path and run the command again... exiting."
            return
        }
    }


    $chiaharvesterlog = "([0-9:.\-T]*) harvester chia.harvester.harvester: INFO\s*([0-9]*) plots were eligible for farming ([a-z0-9.]*) Found ([0-9]*) proofs. Time: ([0-9.]*) s. Total ([0-9]*) plots"
    $BestSpeed = 1000
    $WorstSpeed = 0
    $Over1Seconds = 0
    $Over5Seconds = 0
    $Over30Seconds = 0
    $TotalAttempts = 0
    $TotalFilterRatio = 0
    $TotalLookupTime = 0
    $proofsFound = 0

    Get-Content -Path $DebugLogFilePath -Wait | foreach-object {
        switch -Regex ($_){
            $chiaharvesterlog {
                $harvesterActivity = [pscustomobject]@{
                    Time = [datetime]::parse($Matches[1])
                    EligiblePlots = $Matches[2]
                    LookUpTime = [double]$Matches[5]
                    ProofsFound = $Matches[4]
                    TotalPlots = $Matches[6]
                    FilterRatio = $Matches[2] / $Matches[6]
                }
                $TotalAttempts++
                switch ($harvesterActivity.LookUpTime) {
                    {$_ -lt $BestSpeed} {$BestSpeed = $_}
                    {$_ -gt $WorstSpeed} {$WorstSpeed = $_}
                    {$_ -ge 1} {$Over1Seconds++}
                    {$_ -ge 5} {$Over5Seconds++}
                    {$_ -ge 30} {$Over30Seconds++}
                }
                if ($PSBoundParameters.ContainsKey("ExportCSVPath")){
                    $harvesterActivity | Export-Csv -Path $ExportCSVPath -Append
                }
                $proofsFound += $harvesterActivity.ProofsFound
                $TotalLookupTime += $harvesterActivity.LookUpTime
                $AverageSpeed = [math]::Round(($TotalLookupTime / $TotalAttempts),5)
                $TotalFilterRatio += $harvesterActivity.FilterRatio
                $newRatio = [math]::Round(($TotalFilterRatio / $TotalAttempts),5)
                $RGB = [math]::Round((255 * $harvesterActivity.LookUpTime * $Sensitivity) / 5)
                $eligibleplots = " "
                if ($harvesterActivity.EligiblePlots -gt 0){
                    $eligibleplots = $harvesterActivity.EligiblePlots
                }
                $host.UI.RawUI.WindowTitle = "Total Attempts: $TotalAttempts  ||  LookUp Time - Best: $BestSpeed, Worst: $WorstSpeed, Avg: $AverageSpeed || Over 1 Sec:$Over1Seconds, Over 5 Sec: $Over5Seconds, Over 30 Sec: $Over30Seconds  ||  FilterRatio: $newRatio  ||  Proofs Found: $proofsFound || RGB: $RGB"
                Write-RGBText -Text "$eligibleplots|" -bRed ([math]::Min($RGB,255)) -bGreen ([math]::max([math]::Min(255,(510 - $RGB)),0)) -NoNewLine -UnderLine
            }
        } #switch
    } #foreach
}