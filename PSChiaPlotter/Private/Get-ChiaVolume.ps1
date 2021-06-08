function Get-ChiaVolume {
    [CmdletBinding()]
    param()

    #grabbing all volumes, partitions, disks, and physicaldisks at once since it has proven to be faster
    $AllVolumes = Get-Volume
    #filter out all paritions not are not accessible to the file system
    $AllPartitions = Get-Partition | Where {$_.AccessPaths.Count -gt 1}
    $AllDisks = Get-Disk
    $AllphysicalDisk = Get-PhysicalDisk

    foreach ($volume in $AllVolumes){
        try{
            $partition = $AllPartitions | where AccessPaths -Contains "$($volume.UniqueId)"
            $disk = $AllDisks | where DiskNumber -eq $partition.DiskNumber
            $physicalDisk = $AllphysicalDisk | where DeviceId -eq $disk.DiskNumber
            if ($physicalDisk -ne $null){
                $MediaType = $physicalDisk.MediaType
            }
            else{
                $MediaType = "Unknown"
            }

            $Label = $volume.FileSystemLabel
            if ([string]::IsNullOrEmpty($volume.FileSystemLabel)){
                $Label = "N/A"
            }
            $DriveLetter = $volume.DriveLetter
            if (-not[char]::IsLetter($DriveLetter)){
                $DriveLetter = '?'
            }
            if ($partition){
                $DirectoryPaths = $partition.AccessPaths | where {$_ -ne $volume.UniqueId}
                $ChiaVolume = [PSChiaPlotter.ChiaVolume]::new($volume.UniqueId,$Label,$volume.Size,$volume.SizeRemaining)
                $ChiaVolume.BusType = $physicalDisk.BusType
                $ChiaVolume.MediaType = $MediaType
                $MaxTempCount = [math]::Floor([decimal]($volume.size / (239 * 1gb)))
                $ChiaVolume.MaxConCurrentTempChiaRuns = $MaxTempCount
                $ChiaVolume.DriveLetter = $DriveLetter
                $ChiaVolume.DirectoryPath = $DirectoryPaths | select -First 1
                $DirectoryPaths | foreach {$ChiaVolume.AccessPaths.Add($_)}
                $ChiaVolume
                Clear-Variable PhysicalDisk,Disk,Partition,MaxTempCount -ErrorAction SilentlyContinue
            }
        }
        catch{
            Write-PSChiaPlotterLog -LogType "Error" -LineNumber $_.InvocationInfo.ScriptLineNumber -Message $_.Exception.Message -DebugLogPath $DataHash.LogPath
            #Write-Warning "Unable to create a ChiaVolume from driveletter $($volume.DriveLetter)"
        }
    } #volume

    $mappedDrives = Get-CimInstance -ClassName Win32_MappedLogicalDisk
    $BusType = "Network"
    $MediaType = "Unknown"
    foreach ($drive in $mappedDrives){
        try{
            if ([string]::IsNullOrEmpty($drive.ProviderName)){
                $Label = "N/A"
            }
            else{
                $Label = $drive.ProviderName
            }
            if (-not[string]::IsNullOrEmpty($drive.DeviceID)){
                $DriveLetter = $drive.DeviceID.TrimEnd(':')
                $ChiaVolume = [PSChiaPlotter.ChiaVolume]::new($drive.VolumeSerialNumber,$Label,$drive.Size,$drive.FreeSpace)
                $ChiaVolume.BusType = $BusType
                $ChiaVolume.MediaType = $MediaType
                $MaxTempCount = [math]::Floor([decimal]($drive.size / (239 * 1gb)))
                $ChiaVolume.MaxConCurrentTempChiaRuns = $MaxTempCount
                $ChiaVolume.DriveLetter = $DriveLetter
                $DirectoryPath = $DriveLetter + ':\'
                $ChiaVolume.DirectoryPath = $DirectoryPath
                $ChiaVolume.AccessPaths.Add($DirectoryPath)
                if (Test-Path $label){
                    $ChiaVolume.AccessPaths.Add($Label)
                }
                $ChiaVolume
                Clear-Variable DriveLetter
            }
        }
        catch{
            Write-PSChiaPlotterLog -LogType "Error" -LineNumber $_.InvocationInfo.ScriptLineNumber -Message $_.Exception.Message -DebugLogPath $DataHash.LogPath
            #Write-Warning "Unable to create a ChiaVolume from driveletter $($DriveLetter.DriveLetter)"
        }
    }
}