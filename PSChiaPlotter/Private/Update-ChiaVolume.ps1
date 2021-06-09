function Update-ChiaVolume {
    [CmdletBinding()]
    param()
    $Volumes = Get-ChiaVolume
    $CurrentVolumes = $Volumes | where UniqueId -in $DataHash.MainViewModel.AllVolumes.UniqueId
    foreach ($volume in $CurrentVolumes){
        $matchedVolume = $DataHash.MainViewModel.AllVolumes | where UniqueId -eq $volume.UniqueId
        if ($matchedVolume){
            $matchedVolume.FreeSpace = $volume.FreeSpace
            $matchedVolume = $null
        }
    }

    $newVolumes = $Volumes | where UniqueId -notin $DataHash.MainViewModel.AllVolumes.UniqueId
    foreach ($newvolume in $newVolumes){
        $DataHash.MainViewModel.AllVolumes.Add($newvolume)
    }

    $removedVolumes = $DataHash.MainViewModel.AllVolumes | where UniqueId -NotIn $Volumes.UniqueId
    foreach ($removedvolume in $removedVolumes){
        $DataHash.MainViewModel.AllVolumes.Remove($removedvolume)
    }
}