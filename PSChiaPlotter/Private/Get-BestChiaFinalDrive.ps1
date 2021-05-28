function Get-BestChiaFinalDrive {
    [CmdletBinding()]
    param(
        $ChiaVolumes
    )
    $finalplotsize = 101.4 * 1gb

    foreach ($finalvol in $ChiaVolumes){
        $newVolumeInfo = Get-Volume -DriveLetter $finalvol.DriveLetter
        $finalvol.FreeSpace = $newVolumeInfo.SizeRemaining
    }
    $sortedVolumes = $ChiaVolumes | sort -Property FreeSpace -Descending
    foreach ($volume in $sortedVolumes){
        $MasterVolume = $DataHash.MainViewModel.AllVolumes | where DriveLetter -eq $volume.DriveLetter
        if (($volume.FreeSpace - ($MasterVolume.PendingFinalRuns.Count * $finalplotsize)) -gt $finalplotsize){
                return $volume
        }
    }
}