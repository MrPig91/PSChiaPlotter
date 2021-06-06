function Update-ChiaVolume {
    [CmdletBinding()]
    param()
    $Volumes = Get-ChiaVolume
    $CurrentVolumes = $Volumes | where DriveLetter -in $DataHash.MainViewModel.AllVolumes.DriveLetter
    foreach ($volume in $CurrentVolumes){
        $matchedVolume = $DataHash.MainViewModel.AllVolumes | where DriveLetter -eq $volume.DriveLetter
        if ($matchedVolume){
            $matchedVolume.FreeSpace = $volume.FreeSpace
            $matchedVolume = $null
        }
    }

    $newVolumes = $Volumes | where DriveLetter -notin $DataHash.MainViewModel.AllVolumes.DriveLetter
    foreach ($newvolume in $newVolumes){
        $DataHash.MainViewModel.AllVolumes.Add($newvolume)
    }

    $removedVolumes = $DataHash.MainViewModel.AllVolumes | where DriveLetter -NotIn $Volumes.DriveLetter
    foreach ($removedvolume in $removedVolumes){
        $DataHash.MainViewModel.AllVolumes.Remove($removedvolume)
    }
}