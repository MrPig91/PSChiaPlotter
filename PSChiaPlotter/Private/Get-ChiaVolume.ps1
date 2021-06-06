function Get-ChiaVolume {
    [CmdletBinding()]
    param()

$LocalVolumes = Get-CimInstance -Namespace "ROOT/Microsoft/Windows/Storage" -ClassName MSFT_Volume | Where {$_.DriveLetter -ne $Null} | sort -Property DriveLetter
$RemoteVolumes = Get-PSDrive | where {$_.DisplayRoot -match "\\"}

#grabbing all volumes, partitions, disks, physicaldisks, and mapped drives at once since it has proven to be faster

$AllVolumes = $LocalVolumes + $RemoteVolumes
$AllPartitions = Get-Partition
$AllDisks = Get-Disk
$AllMappedDrives = $RemoteVolumes
$AllphysicalDisk = Get-PhysicalDisk

    foreach ($volume in $AllVolumes){
        try{
            $partition = $AllPartitions | where DriveLetter -eq $volume.DriveLetter
            $disk = $AllDisks | where DiskNumber -eq $partition.DiskNumber
            $physicalDisk = $AllphysicalDisk | where DeviceId -eq $disk.DiskNumber
            $mappedDrive = $AllMappedDrives | where DriveLetter -eq $volume.DriveLetter

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
                Clear-Variable PhysicalDisk,Disk,Partition,MaxTempCount
            }
               elseif ($mappedDrive){
                $volumeSize = (($volume.Free + $volume.Used)) 
                $ChiaVolume = [PSChiaPlotter.ChiaVolume]::new($volume.Name,$Label,$volumeSize,$volume.Free)
                $ChiaVolume.BusType = "SMB"
                $ChiaVolume.MediaType = "Network Storage"
                $MaxTempCount = [math]::Floor([decimal]($volumeSize / (239 * 1gb)))
                $ChiaVolume.MaxConCurrentTempChiaRuns = $MaxTempCount
                $ChiaVolume
                Clear-Variable volumeSize,mappedDrive,Disk,Partition,MaxTempCount
            }
        }
        catch{
            Write-PSChiaPlotterLog -LogType "Error" -LineNumber $_.InvocationInfo.ScriptLineNumber -Message $_.Exception.Message -DebugLogPath $DataHash.LogPath
            $DriveLetter = $volume.DriveLetter
            if ([string]::IsNullOrEmpty($volume.DriveLetter)){
            $DriveLetter = $volume.Name
            }
            Write-Warning "Unable to create a ChiaVolume from driveletter $($DriveLetter)"
        }
    }
}
