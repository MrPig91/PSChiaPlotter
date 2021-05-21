function Get-BestChiaTempDrive {
    [CmdletBinding()]
    param(
        $ChiaVolumes
    )

    foreach ($tempvol in $ChiaVolumes){
        $newVolumeInfo = Get-Volume -DriveLetter $tempvol.DriveLetter
        $tempvol.FreeSpace = $newVolumeInfo.SizeRemaining
    }
    $ChiaVolumes | sort -Property FreeSpace -Descending | Select -First 1
}