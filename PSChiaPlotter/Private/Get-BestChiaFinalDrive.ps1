function Get-BestChiaFinalDrive {
    [CmdletBinding()]
    param(
        $ChiaVolumes,
        $ChiaJob,
        $ChiaQueue
    )
    $finalplotsize = $ChiaQueue.PlottingParameters.KSize.FinalSize

    $AllVolumes = Get-ChiaVolume
    foreach ($finalvol in $ChiaVolumes){
        $newVolumeInfo = $AllVolumes | where UniqueId -eq $finalvol.UniqueId
        $finalvol.FreeSpace = $newVolumeInfo.FreeSpace
        $MasterVolume = $DataHash.MainViewModel.AllVolumes | where UniqueId -eq $finalvol.UniqueId
        $finalvol.PendingFinalRuns = $MasterVolume.PendingFinalRuns
    }
    if ($ChiaJob.ReplotEnabled){
        foreach ($replotVolume in $ChiaVolumes){
            foreach ($oldDirectory in $replotVolume.OldPlotDirectories){
                try{
                    $oldplotcount = (Get-ChildItem -Path $oldDirectory.Path -Filter "plot-k$($oldDirectory.KSizeValue)*.plot" | Measure-Object).Count
                    $oldDirectory.PlotCount = $oldplotcount
                }
                catch{
                    $oldDirectory.PlotCount = 0
                    Write-PSChiaPlotterLog -LogType "ERROR" -ErrorObject $_
                }
            }
            $replotVolume.TotalReplotCount = ($replotVolume.OldPlotDirectories | Measure-Object -Property PlotCount -Sum).Sum
        }
        $AvailableVolumes = $ChiaVolumes | where TotalReplotCount -gt 0 | sort -Property @{Expression = {$_.PendingFinalRuns.Count}; Descending = $false},@{Expression = "TotalReplotCount"; Descending = $True}
        return ($AvailableVolumes | select -First 1)
    }
    else{
        $sortedVolumes = $ChiaVolumes | Sort-Object -Property @{Expression = {$_.PendingFinalRuns.Count}; Descending = $false},@{Expression = "FreeSpace"; Descending = $True}
        foreach ($volume in $sortedVolumes){
            if (($volume.FreeSpace - ($Volume.PendingFinalRuns.Count * $finalplotsize)) -gt $finalplotsize){
                    return $volume
            }
        }
    }
}