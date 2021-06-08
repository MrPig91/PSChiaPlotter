function Get-BestChiaTempDrive {
    [CmdletBinding()]
    param(
        $ChiaVolumes,
        $ChiaJob
    )

    $requiredTempSize = 239 * 1gb
    $finalplotsize = 101.4 * 1gb
    $AllVolumes = Get-ChiaVolume
    foreach ($tempvol in $ChiaVolumes){
        $newVolumeInfo = $AllVolumes | where UniqueId -eq $tempvol.UniqueId
        $tempvol.FreeSpace = $newVolumeInfo.FreeSpace
        $MasterVolume = $DataHash.MainViewModel.AllVolumes | where UniqueId -eq $tempvol.UniqueId
        $tempvol.CurrentChiaRuns = $MasterVolume.CurrentChiaRuns
        $tempvol.PendingFinalRuns = $MasterVolume.PendingFinalRuns
    }
    $sortedVolumes = $ChiaVolumes | sort -Property @{Expression = {$_.CurrentChiaRuns.Count}; Descending = $false},@{Expression = "FreeSpace"; Descending = $True}
    foreach ($volume in $sortedVolumes){
        #$MasterVolume = $DataHash.MainViewModel.AllVolumes | where UniqueId -eq $volume.UniqueId
        if (($Volume.CurrentChiaRuns.Count -lt $volume.MaxConCurrentTempChiaRuns) -or ($ChiaJob.IgnoreMaxParallel)){
            if (($volume.FreeSpace - ($Volume.PendingFinalRuns.Count * $finalplotsize)) -gt $requiredTempSize){
                return $volume
            }
        }
    } #foreach
}