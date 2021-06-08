function Get-BestChiaTempDrive {
    [CmdletBinding()]
    param(
        $ChiaVolumes
    )

    $requiredTempSize = 239 * 1gb
    $finalplotsize = 101.4 * 1gb
    $AllVolumes = Get-ChiaVolume
    foreach ($tempvol in $ChiaVolumes){
        $newVolumeInfo = $AllVolumes | where UniqueId -eq $tempvol.UniqueId
        $tempvol.FreeSpace = $newVolumeInfo.FreeSpace
    }
    $sortedVolumes = $ChiaVolumes | sort -Property FreeSpace -Descending
    foreach ($volume in $sortedVolumes){
        $MasterVolume = $DataHash.MainViewModel.AllVolumes | where UniqueId -eq $volume.UniqueId
        if ($MasterVolume.CurrentChiaRuns.Count -lt $volume.MaxConCurrentTempChiaRuns){
            if (($volume.FreeSpace - ($MasterVolume.PendingFinalRuns.Count * $finalplotsize)) -gt $requiredTempSize){
                return $volume
            }
        }
    }
}