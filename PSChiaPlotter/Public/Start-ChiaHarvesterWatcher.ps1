<#
.SYNOPSIS
    This will display your harvesters lookup times in graphical heatmap. 
.DESCRIPTION
    This function will display harvesters lookup times in graphcial heatmap by scaling the seconds to an RGB color and creating a color block with that color.
    
    The number of eligible proofs are placed inside the color block and proof found block will be blue.
    
    A summary is also generated and placed in the title of powershell window. The function will continue to look at the log file and update the heatmap with new harvester activities as they come in.
.EXAMPLE
    PS C:\> Start-ChiaHarvesterWatcher
    
    |1| | | | |2| | | |....
    | | |2|1|3| | | |1|....

    This will create the default heat map. With good time showing up as bright green and transitions to yellow then orange then red as the get closer to or above 5 seconds.
.EXAMPLE
    PS C:\> Start-ChiaHarvesterWatcher -DarkMode

    |1| | | | |2| | | |....
    | | |2|1|3| | | |1|....

    This will create a dark mode version of the heatmap that goes from gray (closer to 0 seconds) to yellow/orange/red as it gets clsoer to 5 seconds.
.EXAMPLE
    PS C:\>Start-ChiaHarvesterWatcher -MaxLookUpSeconds 2 -NoWalls

    1 11   2 3   ...
      21 1   3 1 ...
    
    This example will have lookup times close to 0 still be bright green, but the color transitions faster to red since the MaxLookUpSeconds is set to 2.
    Nowall switch takes away the | between color blocks.
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    Requires Chia log levels to be set to INFO.
#>
function Start-ChiaHarvesterWatcher {
    [CmdletBinding()]
    param(
        [string]$DebugLogFilePath = (Get-ChildItem -Path "$ENV:USERPROFILE\.chia\mainnet\log" -filter "debug.log").FullName,
        [ValidateRange(0,1000)]
        [double]$MaxLookUpSeconds = 5,
        [Parameter()]
        [ValidateScript({[System.IO.Directory]::Exists((Split-Path -Path $_ -Parent))})]
        [string]$ExportCSVPath,
        [switch]$DarkMode,
        [switch]$NoWalls
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
                    EligiblePlots = [int]$Matches[2]
                    LookUpTime = [double]$Matches[5]
                    ProofsFound = [int]$Matches[4]
                    TotalPlots = [int]$Matches[6]
                    FilterRatio = 0
                } #psobject
                try { #Prevent the divide by zero error message
                    $harvesterActivity.FilterRatio = $Matches[2] / $Matches[6]
                } catch { }
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
                $eligibleplots = " "
                if ($harvesterActivity.EligiblePlots -gt 0){
                    $eligibleplots = $harvesterActivity.EligiblePlots
                }
                $host.UI.RawUI.WindowTitle = "Total Attempts: $TotalAttempts  ||  LookUp Time - Best: $BestSpeed , Worst: $WorstSpeed , Avg: $AverageSpeed || Over 1 Sec:$Over1Seconds, Over 5 Sec: $Over5Seconds, Over 30 Sec: $Over30Seconds  ||  FilterRatio: $newRatio  ||  Proofs Found: $proofsFound || Last Look up Time: $($harvesterActivity.LookUpTime)"

                $RGB = [math]::Round((255 * $harvesterActivity.LookUpTime) / $MaxLookUpSeconds)
                $RGBText = @{
                    bRed = ([math]::Min($RGB,255))
                    bGreen = ([math]::max([math]::Min(255,(510 - $RGB)),0))
                    UnderLine = $true
                    Text = "$eligibleplots|"
                    NoNewLine = $true
                }

                if ($DarkMode){
                    if ($harvesterActivity.LookUpTime -le $MaxLookUpSeconds){
                            $RGBText["bred"] = [math]::Min(($RGB / 2)+20,255)
                            $RGBText["bgreen"] = [math]::Min(($RGB / 2)+20,255)
                            $RGBText["bblue"] = 20
                    }
                } #Darkmode
                if ($NoWalls){
                    $RGBText["UnderLine"] = $false
                    $RGBText["Text"] = $eligibleplots
                } #NoWalls
                if ($harvesterActivity.ProofsFound){
                    $RGBText["bred"] = 0
                    $RGBText["bgreen"] = 0
                    $RGBText["bblue"] = 255
                } #if proofs found

                Write-RGBText @RGBText
            } #chia activity
        } #switch
    } #foreach
}