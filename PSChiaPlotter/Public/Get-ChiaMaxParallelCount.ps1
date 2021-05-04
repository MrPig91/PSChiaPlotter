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

    if (!$PSBoundParameters.ContainsKey("ThreadCount") -and !$PSBoundParameters.ContainsKey("BufferMiB")){
        Write-Warning "All calculations based on plotting k32 plot size only. SSD TB suggestion rounded up to the nearest TB."
    }
    else{
        Write-Warning "SSD TB suggestion rounded up to the nearest TB."
    }
    $Processor = Get-CimInstance -ClassName Win32_Processor
    $Threads = ($Processor | measure -Property ThreadCount -Sum).Sum
    $MaxParallelCountCPU = [math]::Floor($Threads / $ThreadCount)
    #1mb = 1048576 bytes
    $RAM = (Get-CimInstance -ClassName Win32_PhysicalMemory | measure -Property Capacity -Sum).Sum / 1mb
    $MaxParallelCountRAM = [Math]::Floor([decimal]($RAM / $BufferMiB))

    $SystemDisk = Get-CimInstance -Namespace ROOT/Microsoft/Windows/Storage -ClassName MSFT_Disk -Filter "IsSystem=True"
    $SSDs = Get-CimInstance -Namespace root/microsoft/windows/storage -ClassName MSFT_PhysicalDisk -Filter "MediaType=4" #4 -eq SSD
    $SSDs = $SSDs | where UniqueId -ne $SystemDisk.UniqueId | select 
    $One_TB = 1000000000000
    $One_GB = 1000000000
    $TotalSSDspace = ($SSDs | measure -Property Size -Sum).Sum
    $SSD_Count = ($SSDs | Measure-Object).Count
    if ($SSD_Count -eq 0){
        Write-Warning "No non-system SSD found, therefore Current_MaxParallelPlots will be 0. (Ignore if using mutiple HDDs)"
    }

    if ($Threads -gt ($Processor.NumberOfCores * 2)){
        Write-Warning "Threads may actually only be half what is reported and therefore all calculations are off."
    }

    $SSD_MAX = [math]::Floor([decimal]($TotalSSDspace / (256.6 * $One_GB)))

    if ($MaxParallelCountCPU -le $MaxParallelCountRAM){
        $MAXCount = $MaxParallelCountCPU
        $BottleNeck = "CPU"        
    }
    else{
        $MAXCount = $MaxParallelCountRAM
        $BottleNeck = "RAM"        
    }
    $Suggested_SSD_TB = [math]::Ceiling([decimal](256.6 * $MAXCount) / 1000)

    if ($SSD_MAX -le $MAXCount){
        $CurrentMax = $SSD_MAX
        $BottleNeck = "SSD"
    }
    else{
        $CurrentMax = $MAXCount
    }

    $Suggested_SSD_TB = [math]::Ceiling([decimal](256.6 * $MAXCount) / 1000)

    [PSCustomObject]@{
        ThreadCount = $ThreadCount
        Buffer = $BufferMiB
        CPUTotalThreads = $Threads
        CPUCores = ($Processor | Measure -Property NumberOfCores -Sum).Sum
        NumberOfProcessors = ($Processor | measure).Count
        TotalRAM_MiB = $RAM
        BottleNeck = $BottleNeck
        Current_SSD_SPACE_TB = [math]::Round(($TotalSSDspace / $One_TB),2)
        Current_SSD_Count = $SSD_Count
        Suggested_SSD_SPACE_TB = $Suggested_SSD_TB
        Current_MaxParallelPlots = $CurrentMax
        Potential_MAXParallelPlots = $MAXCount
    }
}