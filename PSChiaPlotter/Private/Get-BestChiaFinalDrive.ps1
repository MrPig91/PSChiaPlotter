function Get-BestChiaFinalDrive {
    [CmdletBinding()]
    param(
        $ChiaVolumes,
        $ChiaJob,
        $ChiaQueue
    )
    $finalplotsize = $ChiaQueue.InitialChiaParameters.KSize.FinalSize

    $AllVolumes = Get-ChiaVolume
    foreach ($finalvol in $ChiaVolumes){
        $newVolumeInfo = $AllVolumes | where UniqueId -eq $finalvol.UniqueId
        $finalvol.FreeSpace = $newVolumeInfo.FreeSpace
        $MasterVolume = $DataHash.MainViewModel.AllVolumes | where UniqueId -eq $finalvol.UniqueId
        $finalvol.PendingFinalRuns = $MasterVolume.PendingFinalRuns
    }
    $sortedVolumes = $ChiaVolumes | Sort-Object -Property @{Expression = {$_.PendingFinalRuns.Count}; Descending = $false},@{Expression = "FreeSpace"; Descending = $True}
    foreach ($volume in $sortedVolumes){
        if (($volume.FreeSpace - ($Volume.PendingFinalRuns.Count * $finalplotsize)) -gt $finalplotsize){
                return $volume
        }
    }
}