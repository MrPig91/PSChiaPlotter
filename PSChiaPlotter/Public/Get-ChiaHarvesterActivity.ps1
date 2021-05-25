function Get-ChiaHarvesterActivity {
    [CmdletBinding()]
    param(
        [string[]]$DebugLogFilePath = (Get-ChildItem -Path "$ENV:USERPROFILE\.chia\mainnet\log" -filter "debug.log*").FullName,
        [switch]$Summary
    )
    $chiaharvesterlog = "([0-9:.\-T]*) harvester chia.harvester.harvester: INFO\s*([0-9]*) plots were eligible for farming ([a-z0-9.]*) Found ([0-9]*) proofs. Time: ([0-9.]*) s. Total ([0-9]*) plots"
    foreach ($logfile in $DebugLogFilePath){
        try{
            $SummaryLog = New-Object 'System.Collections.Generic.List[System.Object]'
            Get-Content -Path $logfile | foreach-object {
                switch -Regex ($_){
                    $chiaharvesterlog {
                        $harvesterActivity = [pscustomobject]@{
                            PSTypeName = "PSChiaPlotter.ChiaHarvesterActivity"
                            Time = [datetime]::parse($Matches[1])
                            EligiblePlots = $Matches[2]
                            LookUpTime = [double]$Matches[5]
                            ProofsFound = $Matches[4]
                            TotalPlots = $Matches[6]
                            FilterRatio = $Matches[2] / $Matches[6]
                        } #psobject
                        if (-not$Summary){
                            $harvesterActivity
                        }
                        else{
                            $SummaryLog.Add($harvesterActivity)
                        }
                    }
                } #switch
            } #foreach line
            if ($Summary){
                $FirstandLast = $SummaryLog | sort Time -Descending | select -First 1 -Last 1 | sort -Descending
                $RunTime = $FirstandLast[1].Time - $FirstandLast[0].Time
                if ($RunTime -ne 0){$ChallengesPerMinute = $SummaryLog.Count / $RunTime.TotalMinutes}
                [PSCustomObject]@{
                    PSTypeName = "PSChiaPlotter.ChiaHarvesterSummary"
                    RunTime = $RunTime
                    TotalEligiblePlots = ($SummaryLog | Measure-Object EligiblePlots -Sum).Sum
                    BestLookUpTime = ($SummaryLog | Measure-Object LookUpTime -Minimum).Minimum
                    WorstLookUpTime = ($SummaryLog | Measure-Object LookUpTime -Maximum).Maximum
                    AverageLookUpTime = ($SummaryLog | Measure-Object LookUpTime -Average).Average
                    ProofsFound = ($SummaryLog | Measure-Object -Property ProofsFound -Sum).Sum
                    FilterRatio = ($SummaryLog | Measure-Object -Property FilterRatio -Average).Average
                    ChallengesPerMinute = $ChallengesPerMinute
                }
            }
        }
        catch{
            $PSCmdlet.WriteError($_)
        }
    } #foreach
}