function Get-ChiaRAMInfo {
    [CmdletBinding()]
    param(
    )

    Begin{

    } #Begin

    Process{
    
        $Array = Get-CimInstance -Class Win32_PhysicalMemoryArray
        $CurrentRAM = Get-CimInstance -Class Win32_PhysicalMemory

        [PSCustomObject]@{
            PSTypeName = "PSChiaPlotter.RAMInfo"
            ComputerName = $ENV:COMPUTERNAME
            SlotsInUse = ($CurrentRAM | Measure).Count
            SlotsFree = $Array.MemoryDevices - ($CurrentRAM | Measure).Count
            CurrentSize_GB = (($CurrentRAM).Capacity | Measure -Sum).Sum / 1gb
            MaxSize_GB = $Array.MaxCapacityEx / 1mb
            PartNumber = ($CurrentRAM.PartNumber | Select -Unique | foreach {$_.Trim()})
            Manufacturer = ($CurrentRAM.Manufacturer | Select -Unique | foreach {$_.Trim()})
            TotalSlots = $Array.MemoryDevices
            RAMDevices = $CurrentRAM
        }
    } #Process
}