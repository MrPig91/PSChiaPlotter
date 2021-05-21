function Get-BestChiaFinalDrive {
    [CmdletBinding()]
    param(
        $ChiaVolumes
    )

    foreach ($finalpvol in $ChiaVolumes){
        $newVolumeInfo = Get-Volume -DriveLetter $finalvol.DriveLetter
        $finalvol.FreeSpace = $newVolumeInfo.SizeRemaining
    }
    $ChiaVolumes | sort -Property FreeSpace -Descending | Select -First 1
}