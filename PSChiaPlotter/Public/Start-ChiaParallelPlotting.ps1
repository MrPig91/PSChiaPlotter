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
        [ValidateScript({[System.IO.Directory]::Exists($_)})]
        [string]$TempDirectoryPath,
        [Parameter(Mandatory)]
        [ValidateScript({[System.IO.Directory]::Exists($_)})]
        [string]$FinalDirectoryPath,

        [ValidateScript({[System.IO.Directory]::Exists($_)})]
        [string]$LogDirectoryPath = "$ENV:USERPROFILE\.chia\mainnet\plotter",

        [Parameter()]
        [string]$FarmerPublicKey,

        [Parameter()]
        [string]$PoolPublicKey,

        [Parameter()]
        [ValidateRange(1,[int]::MaxValue)]
        [int]$Buckets,

        [Parameter()]
        [ValidateScript({[System.IO.Directory]::Exists($_)})]
        [string]$SecondTempDirectoryPath,

        [switch]$DisableBitfield,
        [switch]$ExcludeFinalDirectory,

        [switch]$NoExit,

        [ValidateNotNullOrEmpty()]
        [string]$WindowTitle
    )

    $AdditionalParameters = ""
    if ($PSBoundParameters.ContainsKey("WindowTitle")){
        $AdditionalParameters += " -WindowTitle $WindowTitle"
    }
    if ($PSBoundParameters.ContainsKey("FarmerPublicKey")){
        $AdditionalParameters += " -FarmerPublicKey $FarmerPublicKey"
    }
    if ($PSBoundParameters.ContainsKey("PoolPublicKey")){
        $AdditionalParameters += " -PoolPublicKey $PoolPublicKey"
    }
    if ($PSBoundParameters.ContainsKey("Buckets")){
        $AdditionalParameters += " -Buckets $Buckets"
    }
    if ($PSBoundParameters.ContainsKey("SecondTempDirectoryPath")){
        $AdditionalParameters += " -SecondTempDirectoryPath '$SecondTempDirectoryPath'"
    }
    if ($DisableBitfield){
        $AdditionalParameters += " -DisableBitfield"
    }
    if ($ExcludeFinalDirectory){
        $AdditionalParameters += " -ExcludeFinalDirectory"
    }

    for ($Queue = 1; $Queue -le $ParallelCount;$Queue++){
        if ($NoExit){
            $NoExitFlag = "-NoExit"
        }
        $ChiaArguments = "-TotalPlots $plotsperQueue -Buffer $Buffer -Threads $Threads -TempDirectoryPath '$TempDirectoryPath' -FinalDirectoryPath '$FinalDirectoryPath' -LogDirectoryPath '$LogDirectoryPath' -QueueName Queue_$Queue $AdditionalParameters"
        $processParam = @{
            FilePath = "powershell.exe"
            ArgumentList = "$NoExitFlag -Command Start-ChiaPlotting $ChiaArguments"
        }
        Start-Process @processParam
        if ($Queue -lt $ParallelCount){
            Start-Sleep -Seconds $DelayInSeconds
        }
    } #for
}