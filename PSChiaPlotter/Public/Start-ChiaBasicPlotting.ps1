function Start-ChiaBasicPlotting {
    [CmdletBinding()]
    param(
        [ValidateRange(32,35)]
        [int]$KSize = 32,
    
        [ValidateRange(1,5000)]
        [int]$TotalPlots = 1,
    
        [int]$Buffer,

        [ValidateRange(1,256)]
        [int]$ThreadCount = 2,

        [switch]$DisableBitfield,
        [switch]$ExcludeFinalDirectory,
    
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]$TempDirectoryPath,

        [Parameter()]
        [ValidateScript({Test-Path $_})]
        [string]$SecondTempDirecoryPath,

        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]$FinalDirectoryPath,

        #$FarmerPublicKey,
        #$PoolPublicKey,

        [string]$LogPathDirectory = "$ENV:USERPROFILE\.chia\mainnet\plotter",
        [string]$PlotLogNamingSuffix,

        [switch]$NoNewWindow
    )

    if (-not$PSBoundParameters.ContainsKey("Buffer")){
        switch ($KSize){
            32 {$Buffer = 3390}
            33 {$Buffer = 7400}
            34 {$Buffer = 14800}
            35 {$Buffer = 29600}
        }
        Write-Information "Buffer set to: $Buffer"
    }

    $E = if ($DisableBitfield){"-e"}
    $X = if ($ExcludeFinalDirectory){"-x"}

    #remove any trailing '\' since chia.exe hates them
    $TempDirectoryPath = $TempDirectoryPath.TrimEnd('\')
    $FinalDirectoryPath = $FinalDirectoryPath.TrimEnd('\')

    #path to chia.exe
    $ChiaPath = (Get-Item -Path "$ENV:LOCALAPPDATA\chia-blockchain\app-*\resources\app.asar.unpacked\daemon\chia.exe").FullName
    $ChiaArguments = "plots create -k $KSize -n $TotalPlots -b $Buffer -r $ThreadCount -t `"$TempDirectoryPath`" -d `"$FinalDirectoryPath`" $E $X"


    if ($PSBoundParameters.ContainsKey("SecondTempDirecoryPath")){
        $SecondTempDirecoryPath = $SecondTempDirecoryPath.TrimEnd('\')
        $ChiaArguments += " -2 $SecondTempDirecoryPath"
        Write-Information "Added 2nd Temp Dir to Chia ArguementList"
    }

    if (Test-Path $LogPathDirectory){
        $LogPath = Join-Path $LogPathDirectory ((Get-Date -Format yyyy_MM_dd_hh-mm-ss-tt_) + "plotlog" + $PlotLogNamingSuffix + ".log")
    }
    else{
        $Message = "The log path provided was not found: $LogPathDirectory"
        $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.IO.FileNotFoundException]::new($Message,$SErvicePath),
                'LogPathInvalid',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                "$LogPathDirectory"
            )
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        $PSCmdlet.ThrowTerminatingError("Invalid Log Path Directory: $LogPathDirectory")
    }

    if ($ChiaPath){
        Write-Information "Chia path exists, starting the plotting process"
        $PlottingParam = @{
            FilePath = $ChiaPath
            ArgumentList = $ChiaArguments
            RedirectStandardOutput = $LogPath
            NoNewWindow = $NoNewWindow.IsPresent
        }
        try{
            $PlottingProcess = Start-Process @PlottingParam -PassThru
            [PSCustomObject]@{
                KSize = $KSize
                Buffer = $Buffer
                Threads = $ThreadCount
                PID = $PlottingProcess.Id
                StartTime = $PlottingProcess.StartTime
                TempDir = $TempDirectoryPath
                FinalDir = $FinalDirectoryPath
                TempDir2 = $SecondTempDirecoryPath
                LogPath = $LogPath
                TotalPlotCount = $TotalPlots
                BitfieldEnabled = !$DisableBitfield.IsPresent
                ExcludeFinalDir = $ExcludeFinalDirectory.IsPresent
            }
            Write-Information "Plotting started, PID = $PID"
        }
        catch{
            $PSCmdlet.WriteError($_)
        }
    } #if
}