function Get-ChiaPlotProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$LogPath
    )

    #base code from https://github.com/swar/Swar-Chia-Plot-Manager/blob/7287eef4796dbfa4cc009086c6502d19f0706f3e/config.yaml.default
    $phase1_line_end = 801
    $phase2_line_end = 834
    $phase3_line_end = 2474
    $phase4_line_end = 2620
    $copyfile_line_end = 2627
    $phase1_weight = 33
    $phase2_weight = 20
    $phase3_weight = 42
    $phase4_weight = 3
    $copyphase_weight = 2

    $LogItem = Get-Item -Path $LogPath
    $StartTime = $LogItem.CreationTime
    $EndTime = Get-Date
    $ElaspedTime = New-TimeSpan -Start $StartTime -End $EndTime

    $LogFile = Get-Content -Path $LogPath
    $line_count = $LogFile.Count

    if ($line_count -ge $phase1_line_end){
        $progress += $phase1_weight
    }
    else{
        $progress += $phase1_weight * ($line_count / $phase1_line_end)
        $Est_TimeRemaining = ($ElaspedTime.TotalSeconds * 100) / $progress
        $secondsRemaining = [int]($Est_TimeRemaining - $ElaspedTime.TotalSeconds)
        return [PSCustomObject]@{
            Progress = [math]::Round($progress,2)
            Phase = "Phase 1"
            ElaspedTime = $ElaspedTime
            EST_TimeReamining = New-TimeSpan -Seconds $secondsRemaining
        }
    }
    if ($line_count -ge $phase2_line_end){
        $progress += $phase2_weight
    }
    else{
        $progress += $phase2_weight * (($line_count - $phase1_line_end) / ($phase2_line_end - $phase1_line_end))
        $Est_TimeRemaining = ($ElaspedTime.TotalSeconds * 100) / $progress
        $secondsRemaining = [int]($Est_TimeRemaining - $ElaspedTime.TotalSeconds)
        return [PSCustomObject]@{
            Progress = [math]::Round($progress,2)
            Phase = "Phase 2"
            ElaspedTime = $ElaspedTime
            EST_TimeReamining = New-TimeSpan -Seconds $secondsRemaining
        }
    }
    if ($line_count -ge $phase3_line_end){
        $progress += $phase3_weight
    }
    else{
        $progress += $phase3_weight * (($line_count - $phase2_line_end) / ($phase3_line_end - $phase2_line_end))
        $Est_TimeRemaining = ($ElaspedTime.TotalSeconds * 100) / $progress
        $secondsRemaining = [int]($Est_TimeRemaining - $ElaspedTime.TotalSeconds)
        return [PSCustomObject]@{
            Progress = [math]::Round($progress,2)
            Phase = "Phase 3"
            ElaspedTime = $ElaspedTime
            EST_TimeReamining = New-TimeSpan -Seconds $secondsRemaining
        }
    }
    if ($line_count -ge $phase4_line_end){
        $progress += $phase4_weight
    }
    else{
        $progress += $phase4_weight * (($line_count - $phase3_line_end) / ($phase4_line_end - $phase3_line_end))
        $Est_TimeRemaining = ($ElaspedTime.TotalSeconds * 100) / $progress
        $secondsRemaining = [int]($Est_TimeRemaining - $ElaspedTime.TotalSeconds)
        return [PSCustomObject]@{
            Progress = [math]::Round($progress,2)
            Phase = "Phase 4"
            ElaspedTime = $ElaspedTime
            EST_TimeReamining = New-TimeSpan -Seconds $secondsRemaining
        }
    }
    if ($line_count -lt $copyfile_line_end){
        $Est_TimeRemaining = ($ElaspedTime.TotalSeconds * 100) / $progress
        $secondsRemaining = [int]($Est_TimeRemaining - $ElaspedTime.TotalSeconds)
        return [PSCustomObject]@{
            Progress = [math]::Round($progress,2)
            Phase = "Copying"
            ElaspedTime = $ElaspedTime
            EST_TimeReamining = New-TimeSpan -Seconds $secondsRemaining
        }
    }
    $progress += $copyphase_weight
    return [PSCustomObject]@{
        Progress = [math]::Round($progress,2)
        Phase = "Completed"
        ElaspedTime = New-TimeSpan -Start $StartTime -End $LogItem.LastWriteTime
        EST_TimeReamining = 0
    }
}