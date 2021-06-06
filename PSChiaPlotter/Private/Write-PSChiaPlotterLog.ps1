function Write-PSChiaPlotterLog {
    [CmdletBinding()]
    param(
        [ValidateSet("INFO","Warning","ERROR")]
        [string]$LogType,
        [string]$Message,
        [int]$LineNumber,
        [string]$DebugLogPath
    )

    try{
        $Date = Get-Date -Format "[yyyy-MM-dd.HH:mm:ss]"
        $LogLine = "$Date-$LogType-$LineNumber-$Message"
        $LogLine | Out-File $DebugLogPath -Append
    }
    catch{
        $PSCmdlet.WriteError($_)
    }
}