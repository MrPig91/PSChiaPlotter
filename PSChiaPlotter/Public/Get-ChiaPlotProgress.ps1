function Get-ChiaPlotProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$LogPath
    )

    if ([System.IO.Directory]::Exists($LogPath)){
        Write-Error "You provided a directory path and not a file path to the log file" -ErrorAction Stop
    }

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
    $plotId = $LogFile | Select-String -SimpleMatch "ID: " | foreach {$_.ToString().Split(" ")[1]}
    $line_count = $LogFile.Count

    $plotProgressObject = [PSCustomObject]@{
        Progress = 0
        Phase = "Phase 1"
        ElaspedTime = $ElaspedTime
        EST_TimeRemaining = New-TimeSpan
        PlotId = $plotId
        Phase1Progess = 0
        Phase2Progess = 0
        Phase3Progess = 0
        Phase4Progess = 0
        CopyProgess = 0
    }

    if ($line_count -ge $phase1_line_end){
        $plotProgressObject.Phase1Progess = 100
        $plotProgressObject.Progress += $phase1_weight
    }
    else{
        $Phase1Progess = ($line_count / $phase1_line_end)
        $plotProgressObject.Phase1Progess = [math]::Round(($Phase1Progess * 100),2)
        $plotProgressObject.Progress += $phase1_weight * $Phase1Progess
        $plotProgressObject.Phase = "Phase 1"
        $Est_TimeRemaining = ($ElaspedTime.TotalSeconds * 100) / $plotProgressObject.Progress
        $plotProgressObject.EST_TimeRemaining = New-TimeSpan -Seconds EST_TimeRemaining

        return $plotProgressObject
    }
    if ($line_count -ge $phase2_line_end){
        $plotProgressObject.Phase2Progess = 100
        $plotProgressObject.Progress += $phase2_weight
    }
    else{
        $phase2Progress = ($line_count - $phase1_line_end) / ($phase2_line_end - $phase1_line_end)
        $plotProgressObject.Phase2Progess = [math]::Round(($phase2Progress * 100),2)
        $plotProgressObject.Progress += $phase2_weight * $phase2Progress
        $plotProgressObject.Phase = "Phase 2"

        $Est_TimeRemaining = ($ElaspedTime.TotalSeconds * 100) / $plotProgressObject.Progress
        $plotProgressObject.EST_TimeRemaining = New-TimeSpan -Seconds EST_TimeRemaining

        return $plotProgressObject
    }
    if ($line_count -ge $phase3_line_end){
        $plotProgressObject.Phase3Progess = 100
        $plotProgressObject.Progress += $phase3_weight
    }
    else{
        $phase3Progess = ($line_count - $phase2_line_end) / ($phase3_line_end - $phase2_line_end)
        $plotProgressObject.Phase3Progess = [math]::Round(($phase3Progess * 100),2)
        $plotProgressObject.Progress += $phase3_weight * $phase3Progess
        $plotProgressObject.Phase = "Phase 3"

        $Est_TimeRemaining = ($ElaspedTime.TotalSeconds * 100) / $plotProgressObject.Progress
        $plotProgressObject.EST_TimeRemaining = New-TimeSpan -Seconds EST_TimeRemaining
        return $plotProgressObject
    }
    if ($line_count -ge $phase4_line_end){
        $plotProgressObject.Phase4Progess = 100
        $plotProgressObject.Progress += $phase4_weight
    }
    else{
        $phase4Progess = ($line_count - $phase3_line_end) / ($phase4_line_end - $phase3_line_end)
        $plotProgressObject.Phase4Progess = [math]::Round(($phase4Progess * 100),2)
        $plotProgressObject.Progress += $phase4_weight * $phase4Progess
        $plotProgressObject.Phase = "Phase 4"
        
        $Est_TimeRemaining = ($ElaspedTime.TotalSeconds * 100) / $plotProgressObject.Progress
        $plotProgressObject.EST_TimeRemaining = New-TimeSpan -Seconds EST_TimeRemaining

        return $plotProgressObject
    }
    if ($line_count -lt $copyfile_line_end){
        $Est_TimeRemaining = ($ElaspedTime.TotalSeconds * 100) / $plotProgressObject.Progress
        $plotProgressObject.EST_TimeRemaining = New-TimeSpan -Seconds EST_TimeRemaining
        $plotProgressObject.Phase = "Copying"

        return $plotProgressObject
    }
    $plotProgressObject.Progress += $copyphase_weight
    $plotProgressObject.CopyProgess = 100
    $plotProgressObject.Phase = "Complete"
    $plotProgressObject.ElaspedTime = New-TimeSpan -Start $StartTime -End $LogItem.LastWriteTime
    $plotProgressObject.EST_TimeRemaining = 0
    return $plotProgressObject
}