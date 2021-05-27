function Get-BestChiaFinalDrive {
    [CmdletBinding()]
    param(
        $ChiaVolumes
    )
    $requiredFinalSize = 101.4 * 1gb

    foreach ($finalvol in $ChiaVolumes){
        $newVolumeInfo = Get-Volume -DriveLetter $finalvol.DriveLetter
        $finalvol.FreeSpace = $newVolumeInfo.SizeRemaining
    }
    $BestVolume = $ChiaVolumes | sort -Property FreeSpace -Descending | Select -First 1
    $MasterVolume = $DataHash.MainViewModel.AllVolumes | where DriveLetter -eq $BestVolume.DriveLetter
    if (($finalvol.FreeSpace - ($MasterVolume.PendingFinalRuns.Count * 101.425)) -gt $requiredFinalSize){
            $BestVolume
    }
}