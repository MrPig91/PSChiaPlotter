function Start-ChiaParallelPlotting {
    param(
        [ValidateRange(1,128)]
        [int]$ParallelCount = 1,

        [ValidateRange(0,[int]::MaxValue)]
        [Alias("Delay")]
        [int]$DelayInSeconds = 3600,

        [int]$PlotsPerQueue = 1,
        [ValidateRange(3390,[int]::MaxValue)]
        [int]$Buffer = 3390,
        [ValidateRange(1,128)]
        [int]$Threads = 2,

        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$TempDirectoryPath,
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$FinalDirectoryPath,
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$LogDirectoryPath = "$ENV:USERPROFILE\.chia\mainnet\plotter",

        [switch]$NoExit
    )

    for ($Queue = 1; $Queue -le $ParallelCount;$Queue++){
        if ($NoExit){
            $NoExitFlag = "-NoExit"
        }
        $processParam = @{
            FilePath = "powershell.exe"
            ArgumentList = "$NoExitFlag -Command Start-ChiaPlotting -TotalPlots $plotsperQueue -Buffer $Buffer -Threads $Threads -TempDirectoryPath $TempDirectoryPath -FinalDirectoryPath $FinalDirectoryPath -LogDirectoryPath $LogDirectoryPath -QueueName Run_$Queue"
        }
        Start-Process @processParam
        if ($Queue -lt $ParallelCount){
            Start-Sleep -Seconds $DelayInSeconds
        }
    } #for
}