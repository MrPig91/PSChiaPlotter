function Write-PSChiaPlotterLog {
    [CmdletBinding()]
    param(
        [ValidateSet("INFO","WARNING","ERROR")]
        [string]$LogType,
        [string]$Message,
        [int]$LineNumber,
        [string]$Line,
        $ErrorObject
    )

    try{
        $Date = Get-Date -Format "[yyyy-MM-dd.HH:mm:ss]"
        switch ($LogType){
            "ERROR" {
                $Message = $ErrorObject.Exception.Message
                $LineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
                $Line = $ErrorObject.InvocationInfo.Line
                Write-Host "[$LogType]$Date-$LineNumber-$Message`n  $Line"
                break
            }
            "WARNING" {
                if ($DataHash.MainViewModel.LogLevel -eq "WARNING"){
                    Write-Host "[$LogType]-$Date-$Message"
                }
                break
            }
            "INFO" {
                if ($DataHash.MainViewModel.LogLevel -eq "INFO" -or $DataHash.MainViewModel.LogLevel -eq "WARNING"){
                    Write-Host "[$LogType]-$Date-$Message"
                }
                break
            }
        }
    }
    catch{
        Write-Host $_.Exception.Message
    }
}