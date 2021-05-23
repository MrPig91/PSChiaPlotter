function Get-BestChiaTempDrive {
    [CmdletBinding()]
    param(
        $ChiaVolumes
    )

    $requiredTempSize = (239 * 1gb)
    foreach ($tempvol in $ChiaVolumes){
        $newVolumeInfo = Get-Volume -DriveLetter $tempvol.DriveLetter
        $tempvol.FreeSpace = $newVolumeInfo.SizeRemaining
    }
    $BestVolume = $ChiaVolumes | sort -Property FreeSpace -Descending | Select -First 1
    $MasterVolume = $DataHash.MainViewModel.AllVolumes | where DriveLetter -eq $BestVolume.DriveLetter
    if ($MasterVolume.CurrentChiaRuns.Count -lt $MasterVolume.MaxConCurrentTempChiaRuns){
        if (($tempvol.SizeRemaining - ($MasterVolume.PendingPlots * 101.4)) -gt $requiredTempSize){
            $BestVolume
        }
    }
}