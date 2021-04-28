function Get-ChiaMaxParallelCount {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateRange(1,128)]
        [int]$ThreadCount = 2,
        [Parameter()]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$BufferMiB = 3390
    )
    $Processor = Get-CimInstance -ClassName Win32_Processor
    $MaxParallelCountCPU = $Processor.ThreadCount / $ThreadCount
    #1mb = 1048576 bytes
    $RAM = (Get-CimInstance -ClassName Win32_PhysicalMemory | measure -Property Capacity -Sum).Sum / 1mb
    $MaxParallelCountRAM = [Math]::Floor([decimal]($RAM / $BufferMiB))
    if ($MaxParallelCountCPU -le $MaxParallelCountRAM){
        $MAXCount = $MaxParallelCountCPU
        $BottleNeck = "CPU"        
    }
    else{
        $MAXCount = $MaxParallelCountRAM
        $BottleNeck = "RAM"        
    }
    $SSD_TB = [math]::Ceiling([decimal](256.6 * $MAXCount) / 1000)
    [PSCustomObject]@{
        ThreadCount = $ThreadCount
        Buffer = $BufferMiB
        MaxParallelPlots = $MaxCount
        CPUTotalThreads = $Processor.ThreadCount
        CPUCores = $Processor.NumberOfCores
        TotalRAM_MiB = $RAM
        BottleNeck = $BottleNeck
        SSD_TB = $SSD_TB
    }
}