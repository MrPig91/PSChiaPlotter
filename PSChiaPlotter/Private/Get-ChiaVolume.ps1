function Get-ChiaVolume {
    [CmdletBinding()]
    param()

    #grabbing all volumes, partitions, disks, and physicaldisks at once since it has proven to be faster
    $AllVolumes = Get-CimInstance -Namespace "ROOT/Microsoft/Windows/Storage" -ClassName MSFT_Volume |
        Where {$_.DriveLetter -ne $Null} | sort -Property DriveLetter
    $AllPartitions = Get-Partition
    $AllDisks = Get-Disk
    $AllphysicalDisk = Get-PhysicalDisk

    foreach ($volume in $AllVolumes){
        try{
            $partition = $AllPartitions | where DriveLetter -eq $volume.DriveLetter
            $disk = $AllDisks | where DiskNumber -eq $partition.DiskNumber
            $physicalDisk = $AllphysicalDisk | where DeviceId -eq $disk.DiskNumber

            $Label = $volume.FileSystemLabel
            if ([string]::IsNullOrEmpty($volume.FileSystemLabel)){
                $Label = "N/A"
            }
            if ($physicalDisk){
                $ChiaVolume = [PSChiaPlotter.ChiaVolume]::new($volume.DriveLetter,$Label,$volume.Size,$volume.SizeRemaining)
                $ChiaVolume.BusType = $physicalDisk.BusType
                $ChiaVolume.MediaType = $physicalDisk.MediaType
                $MaxTempCount = [math]::Floor([decimal]($volume.size / (239 * 1gb)))
                $ChiaVolume.MaxConCurrentTempChiaRuns = $MaxTempCount
                $ChiaVolume
                Clear-Variable PhysicalDisk,Disk,Partition,MaxTempCount
            }
        }
        catch{
            Write-PSChiaPlotterLog -LogType "Error" -LineNumber $_.InvocationInfo.ScriptLineNumber -Message $_.Exception.Message -DebugLogPath $DataHash.LogPath
            Write-Warning "Unable to create a ChiaVolume from driveletter $($volume.DriveLetter)"
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
                $ChiaVolume = [PSChiaPlotter.ChiaVolume]::new($DriveLetter,$Label,$drive.Size,$drive.FreeSpace)
                $ChiaVolume.BusType = $BusType
                $ChiaVolume.MediaType = $MediaType
                $MaxTempCount = [math]::Floor([decimal]($drive.size / (239 * 1gb)))
                $ChiaVolume.MaxConCurrentTempChiaRuns = $MaxTempCount
                $ChiaVolume
                Clear-Variable DriveLetter
            }
        }
        catch{
            Write-PSChiaPlotterLog -LogType "Error" -LineNumber $_.InvocationInfo.ScriptLineNumber -Message $_.Exception.Message -DebugLogPath $DataHash.LogPath
            Write-Warning "Unable to create a ChiaVolume from driveletter $($DriveLetter.DriveLetter)"
        }
    }
}