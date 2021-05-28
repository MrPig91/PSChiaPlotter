function Get-BestChiaTempDrive {
    [CmdletBinding()]
    param(
        $ChiaVolumes
    )

    $requiredTempSize = 239 * 1gb
    $finalplotsize = 101.4 * 1gb
    foreach ($tempvol in $ChiaVolumes){
        $newVolumeInfo = Get-Volume -DriveLetter $tempvol.DriveLetter
        $tempvol.FreeSpace = $newVolumeInfo.SizeRemaining
    }
    $sortedVolumes = $ChiaVolumes | sort -Property FreeSpace -Descending
    foreach ($volume in $sortedVolumes){
        $MasterVolume = $DataHash.MainViewModel.AllVolumes | where DriveLetter -eq $volume.DriveLetter
        if ($MasterVolume.CurrentChiaRuns.Count -lt $volume.MaxConCurrentTempChiaRuns){
            if (($volume.FreeSpace - ($MasterVolume.PendingFinalRuns.Count * $finalplotsize)) -gt $requiredTempSize){
                return $volume
            }
        }
    }
}