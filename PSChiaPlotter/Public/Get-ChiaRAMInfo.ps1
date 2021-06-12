function Get-ChiaRAMInfo {
    <#
        .SYNOPSIS
            Display installed system memory information.
        .DESCRIPTION
            Displays general information about the installed RAM.

            Lists the computer name, # of available and unavailable motherboard RAM slots,
            the amount of installed memory, the RAM manufacturer/part number and RAM devices.
        .PARAMETER c
            Clear the screen prior to displaying the requested information.
        .EXAMPLE
            PS> Get-ChiaRAMInfo
            
            ComputerName   : COMPUTERNAME
            SlotsInUse     : 4
            SlotsFree      : 0
            CurrentSize_GB : 64
            MaxSize_GB     : 64
            PartNumber     : 16ATF2G64AZ-2G6E1
            Manufacturer   : 009C2B0C0000
            TotalSlots     : 4
            RAMDevices     : {Win32_PhysicalMemory: Physical Memory (Tag = "Physical Memory 0"), Win32_PhysicalMemory: Physical
                            Memory (Tag = "Physical Memory 1"), Win32_PhysicalMemory: Physical Memory (Tag = "Physical Memory
                            2"), Win32_PhysicalMemory: Physical Memory (Tag = "Physical Memory 3")}

            This example displays general information about the installed system memory.
        .EXAMPLE
            PS> Get-ChiaRAMInfo -c

            ComputerName   : COMPUTERNAME
            SlotsInUse     : 4
            SlotsFree      : 0
            CurrentSize_GB : 64
            MaxSize_GB     : 64
            PartNumber     : 16ATF2G64AZ-2G6E1
            Manufacturer   : 009C2B0C0000
            TotalSlots     : 4
            RAMDevices     : {Win32_PhysicalMemory: Physical Memory (Tag = "Physical Memory 0"), Win32_PhysicalMemory: Physical
                            Memory (Tag = "Physical Memory 1"), Win32_PhysicalMemory: Physical Memory (Tag = "Physical Memory
                            2"), Win32_PhysicalMemory: Physical Memory (Tag = "Physical Memory 3")}

            This example will clear the screen before displaying the installed system memory information.
        .INPUTS
            Inputs (if any)
        .OUTPUTS
            Output (if any)
        .LINK
            GitHub Project: https://github.com/MrPig91/PSChiaPlotter
        .LINK
            PowerShell Gallery: https://www.powershellgallery.com/packages/PSChiaPlotter
    #>
    [CmdletBinding()]
    param(
        [switch]$c
    )
    if ($c) { Clear-Host }
    Get-Process {
        $Array = Get-CimInstance -Class Win32_PhysicalMemoryArray
        $CurrentRAM = Get-CimInstance -Class Win32_PhysicalMemory

        [PSCustomObject]@{
            PSTypeName     = "PSChiaPlotter.RAMInfo"
            ComputerName   = $ENV:COMPUTERNAME
            SlotsInUse     = ($CurrentRAM | Measure-Object).Count
            SlotsFree      = $Array.MemoryDevices - ($CurrentRAM | Measure-Object).Count
            CurrentSize_GB = (($CurrentRAM).Capacity | Measure-Object -Sum).Sum / 1gb
            MaxSize_GB     = $Array.MaxCapacityEx / 1mb
            PartNumber     = ($CurrentRAM.PartNumber | Select-Object -Unique | ForEach-Object { $_.Trim() })
            Manufacturer   = ($CurrentRAM.Manufacturer | Select-Object -Unique | ForEach-Object { $_.Trim() })
            TotalSlots     = $Array.MemoryDevices
            RAMDevices     = $CurrentRAM
        }#psobject
    } #Get-Process
}