function Get-BestChiaTempDrive {
    [CmdletBinding()]
    param(
        $ChiaVolumes,
        $ChiaJob,
        $ChiaQueue
    )

    $requiredTempSize = $ChiaQueue.PlottingParameters.KSize.TempSize
    $finalplotsize = $ChiaQueue.PlottingParameters.KSize.FinalSize

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
        if (($Volume.CurrentChiaRuns.Count -lt $volume.MaxConCurrentTempChiaRuns) -or ($ChiaJob.IgnoreMaxParallel)){
            if (($volume.FreeSpace - ($Volume.PendingFinalRuns.Count * $finalplotsize)) -gt $requiredTempSize){
                return $volume
            }
        }
    } #foreach
}