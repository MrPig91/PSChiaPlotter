function Get-ChiaRAMInfo {
    [CmdletBinding()]
    param(
        [string[]]$ComputerName = $ENV:Computername,
        [Microsoft.Management.Infrastructure.CimCmdlets.ProtocolType]$Protocol = "Wsman"
    )

    Begin{

    } #Begin

    Process{
        foreach ($computer in $ComputerName){
            if (Test-Connection -ComputerName $computer -Quiet -Count 1){
                try{
                    $CimSessionOption = New-CimSessionOption -Protocol $Protocol
                    $Session = New-CimSession -ComputerName $computer -SessionOption $CimSessionOption -OperationTimeoutSec 2 -ErrorAction Stop
                    $Array = Get-CimInstance -CimSession $Session -Class Win32_PhysicalMemoryArray
                    $CurrentRAM = Get-CimInstance -CimSession $Session -Class Win32_PhysicalMemory

                    [PSCustomObject]@{
                        PSTypeName = "PSChiaPlotter.RAMInfo"
                        ComputerName = $computer
                        SlotsInUse = ($CurrentRAM | Measure).Count
                        SlotsFree = $Array.MemoryDevices - ($CurrentRAM | Measure).Count
                        CurrentSize_GB = (($CurrentRAM).Capacity | Measure -Sum).Sum / 1gb
                        MaxSize_GB = $Array.MaxCapacityEx / 1mb
                        PartNumber = ($CurrentRAM.PartNumber | Select -Unique | foreach {$_.Trim()})
                        Manufacturer = ($CurrentRAM.Manufacturer | Select -Unique | foreach {$_.Trim()})
                        TotalSlots = $Array.MemoryDevices
                        RAMDevices = $CurrentRAM
                    }
                    Remove-CimSession -CimSession $Session
                }
                catch{
                    if ($Protocol = "WSMan"){
                        Get-RAMInfo -ComputerName $Computer -Protocol "Dcom" -ErrorAction SilentlyContinue
                    }
                }
            } #if
        } #foreach
    } #Process
}