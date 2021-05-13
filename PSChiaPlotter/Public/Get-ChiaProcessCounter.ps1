function Get-ChiaProcessCounter{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int[]]$ChiaPID
    )

    foreach ($ID in $ChiaPID){
        $QueryString += "OR IDProcess=$ID "
    }

    $Performance = Get-CimInstance -Query "Select workingSetPrivate,PercentProcessorTime,IDProcess FROM Win32_PerfFormattedData_PerfProc_Process WHERE NAME='_Total' $QueryString"
    $TotalCPU = $Performance | where {$_.Name -eq '_Total'}
    $ChiaProcesses = $Performance | where {$_.Name -ne '_Total'}
    foreach ($process in $ChiaProcesses){
        if ($process.PercentProcessorTime -ne 0){
            $CPUPer = ($process.PercentProcessorTime / $TotalCPU.PercentProcessorTime) * 100
            $RoundedCPU = [math]::Round($CPUPer,2)
        }
        else{$CPUPer = 0}

        [PSCustomObject]@{
            ChiaPID = $process.IDProcess
            CPUPercent = $RoundedCPU
        }
    }
}