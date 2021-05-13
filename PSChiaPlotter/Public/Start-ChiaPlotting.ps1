function Start-ChiaPlotting {
    [CmdletBinding()]
    param(
        [ValidateRange(32,35)]
        [int]$KSize = 32,
    
        [ValidateRange(1,5000)]
        [int]$TotalPlots = 1,
    
        [int]$Buffer,

        [ValidateRange(1,256)]
        [int]$Threads = 2,

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

        [string]$LogDirectoryPath = "$ENV:USERPROFILE\.chia\mainnet\plotter",

        [switch]$NoNewWindow,

        [string]$QueueName
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
    $ChiaArguments = "plots create -k $KSize -b $Buffer -r $Threads -t `"$TempDirectoryPath`" -d `"$FinalDirectoryPath`" $E $X"


    if ($PSBoundParameters.ContainsKey("SecondTempDirecoryPath")){
        $SecondTempDirecoryPath = $SecondTempDirecoryPath.TrimEnd('\')
        $ChiaArguments += " -2 $SecondTempDirecoryPath"
        Write-Information "Added 2nd Temp Dir to Chia ArguementList"
    }

    if (Test-Path $LogDirectoryPath){
        $LogPath = Join-Path $LogDirectoryPath ((Get-Date -Format yyyy_MM_dd_hh-mm-ss-tt_) + "plotlog" + ".log")
    }
    else{
        $Message = "The log path provided was not found: $LogDirectoryPath"
        $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.IO.FileNotFoundException]::new($Message,$SErvicePath),
                'LogPathInvalid',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                "$LogDirectoryPath"
            )
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        $PSCmdlet.ThrowTerminatingError("Invalid Log Path Directory: $LogDirectoryPath")
    }

    if ($ChiaPath){
        Write-Information "Chia path exists, starting the plotting process"
        if ($NoNewWindow){
            for ($plotNumber = 1;$plotNumber -le $TotalPlots;$plotNumber++){
                try{
                    $LogPath = Join-Path $LogDirectoryPath ((Get-Date -Format yyyy_MM_dd_hh-mm-ss-tt_) + "plotlog-" + $plotNumber + ".log")
                    $PlottingParam = @{
                        FilePath = $ChiaPath
                        ArgumentList = $ChiaArguments
                        RedirectStandardOutput = $LogPath
                        NoNewWindow = $NoNewWindow.IsPresent
                    }
                    $chiaProcess = Start-Process @PlottingParam -PassThru
                    $host.ui.RawUI.WindowTitle = "$QueueName - Plot $plotNumber out of $TotalPlots | Chia Process Id - $($chiaProcess.id)"

                    #Have noticed that giving the process a second to start before checking the logs works better
                    Start-Sleep 1
                
                    while (!$chiaProcess.HasExited){
                        try{
                            $progress = Get-ChiaPlotProgress -LogPath $LogPath -ErrorAction Stop
                            Write-Progress -Activity "Queue $($QueueName): Plot $plotNumber out of $TotalPlots" -Status "$($progress.phase) - $($progress.Progress)%" -PercentComplete $progress.progress -SecondsRemaining $progress.EST_TimeReamining.TotalSeconds
                            Start-Sleep 5
                        }
                        catch{
                            Write-Progress -Activity "Queue $($QueueName): Plot $plotNumber out of $TotalPlots" -Status "WARNING! PROGRESS UPDATES HAS FAILED! $($progress.phase) - $($progress.Progress)%" -PercentComplete $progress.progress -SecondsRemaining $progress.EST_TimeReamining.TotalSeconds
                            Start-Sleep 30
                        }
                    }
                }
                catch{
                    $PSCmdlet.WriteError($_)
                }
            } #for
        } #if noNewWindow
        else{
            $ChiaArguments += " -n $TotalPlots"
            $PlottingParam = @{
                FilePath = $ChiaPath
                ArgumentList = $ChiaArguments
                RedirectStandardOutput = $LogPath
                NoNewWindow = $NoNewWindow.IsPresent
            }
            $PlottingProcess = Start-Process @PlottingParam -PassThru
            [PSCustomObject]@{
                KSize = $KSize
                Buffer = $Buffer
                Threads = $Threads
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
        } # else
    } #if chia path exits
}