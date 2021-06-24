function Test-PhaseOneIsOpen {
    [CmdletBinding()]
    param(
        $ChiaJob
    )

    try{
        if ($ChiaJob.EnablePhaseOneLimitor){
            $phaseOneCount = ($ChiaJob.RunsInProgress | where Phase -eq "Phase 1" | Measure-Object).Count
            if ($phaseOneCount -ge $ChiaJob.PhaseOneLimit){
                return $false
            }
            else{
                return $true
            }
        }
        else{
            return $true
        }
    }
    catch{
        Write-PSChiaPlotterLog -LogLevel "Warning" -Message "Unable to check if phase one is open!"
    }
}