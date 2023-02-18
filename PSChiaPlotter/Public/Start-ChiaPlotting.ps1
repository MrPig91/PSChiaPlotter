function Start-ChiaPlotting {
    [CmdletBinding()]
    param(
        [ValidateSet(25,32,33,34,35)]
        [int]$KSize = 32,
    
        [ValidateRange(1,5000)]
        [int]$TotalPlots = 1,
    
        [int]$Buffer,

        [ValidateRange(1,256)]
        [int]$Threads = 2,

        [switch]$DisableBitfield,
        [switch]$ExcludeFinalDirectory,
    
        [Parameter(Mandatory)]
        [ValidateScript({[System.IO.Directory]::Exists($_)})]
        [string]$TempDirectoryPath,

        [Parameter()]
        [ValidateScript({[System.IO.Directory]::Exists($_)})]
        [string]$SecondTempDirectoryPath,

        [Parameter(Mandatory)]
        [ValidateScript({[System.IO.Directory]::Exists($_)})]
        [string]$FinalDirectoryPath,

        [Parameter()]
        [string]$FarmerPublicKey,

        [Parameter()]
        [string]$PoolPublicKey,

        [Parameter()]
        [ValidateRange(1,[int]::MaxValue)]
        [int]$Buckets,

        [ValidateScript({[System.IO.Directory]::Exists($_)})]
        [string]$LogDirectoryPath = "$ENV:USERPROFILE\.chia\mainnet\plotter",

        [switch]$NewWindow,

        [string]$QueueName = "Default_Queue",

        [string]$WindowTitle,

        [switch]$ValidatePlot
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

    if ($PSBoundParameters.ContainsKey("WindowTitle")){
        $WindowTitle = $WindowTitle + " |"
    }

    $E = if ($DisableBitfield){"-e"}
    $X = if ($ExcludeFinalDirectory){"-x"}

    #remove any trailing '\' since chia.exe hates them
    $TempDirectoryPath = $TempDirectoryPath.TrimEnd('\')
    $FinalDirectoryPath = $FinalDirectoryPath.TrimEnd('\')

    #path to chia.exe
    $ChiaPath = (Get-Item -Path "$ENV:LOCALAPPDATA\Programs\Chia\resources\app.asar.unpacked\daemon\chia.exe").FullName
    $ChiaArguments = "plots create -k $KSize -b $Buffer -r $Threads -t `"$TempDirectoryPath`" -d `"$FinalDirectoryPath`" $E $X"

    if ($KSize -eq 25){
        $ChiaArguments += " --override-k"
    }


    if ($PSBoundParameters.ContainsKey("SecondTempDirectoryPath")){
        $SecondTempDirectoryPath = $SecondTempDirectoryPath.TrimEnd('\')
        $ChiaArguments += " -2 $SecondTempDirectoryPath"
        Write-Information "Added 2nd Temp Dir to Chia ArguementList"
    }
    if ($PSBoundParameters.ContainsKey("FarmerPublicKey")){
        $ChiaArguments += " -f $FarmerPublicKey"
    }
    if ($PSBoundParameters.ContainsKey("PoolPublicKey")){
        $ChiaArguments += " -p $PoolPublicKey"
    }

    if ($PSBoundParameters.ContainsKey("Buckets")){
        $ChiaArguments += " -u $Buckets"
    }

    if ($ChiaPath){
        Write-Information "Chia path exists, starting the plotting process"
        if (!$NewWindow){
            for ($plotNumber = 1;$plotNumber -le $TotalPlots;$plotNumber++){
                try{
                    $LogPath = Join-Path $LogDirectoryPath ((Get-Date -Format yyyy_MM_dd_hh-mm-ss-tt_) + "plotlog-" + $plotNumber + ".log")
                    $PlottingParam = @{
                        FilePath = $ChiaPath
                        ArgumentList = $ChiaArguments
                        RedirectStandardOutput = $LogPath
                        NoNewWindow = $true
                    }
                    $chiaProcess = Start-Process @PlottingParam -PassThru
                    $host.ui.RawUI.WindowTitle = "$WindowTitle $QueueName - Plot $plotNumber out of $TotalPlots | Chia Process Id - $($chiaProcess.id)"

                    #Have noticed that giving the process a second to start before checking the logs works better
                    Start-Sleep 1
                
                    while (!$chiaProcess.HasExited){
                        try{
                            $progress = Get-ChiaPlotProgress -LogPath $LogPath -ErrorAction Stop
                            $plotid = $progress.PlotId
                            #write-progress will fail if secondsremaining is less than 0...
                            $secondsRemaining = $progress.EST_TimeRemaining.TotalSeconds
                            if ($progress.EST_TimeRemaining.TotalSeconds -le 0){
                                $secondsRemaining = 0
                            }
                            Write-Progress -Activity "Queue $($QueueName): Plot $plotNumber out of $TotalPlots" -Status "$($progress.phase) - $($progress.Progress)%" -PercentComplete $progress.progress -SecondsRemaining $secondsRemaining
                            Start-Sleep 5
                        }
                        catch{
                            Write-Progress -Activity "Queue $($QueueName): Plot $plotNumber out of $TotalPlots" -Status "WARNING! PROGRESS UPDATES HAS FAILED! $($progress.phase) - $($progress.Progress)%" -PercentComplete $progress.progress -SecondsRemaining $secondsRemaining
                            Start-Sleep 30
                        }
                    } #while
                    if ($chiaProcess.ExitCode -ne 0){
                        Get-ChildItem -Path $TempDirectoryPath -Filter "*$plotid*.tmp" | Remove-Item -Force
                    }
                    if ($ValidatePlot){
                        Test-ChiaPlot -Filter $plotid
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
                TempDir2 = $SecondTempDirectoryPath
                LogPath = $LogPath
                TotalPlotCount = $TotalPlots
                BitfieldEnabled = !$DisableBitfield.IsPresent
                ExcludeFinalDir = $ExcludeFinalDirectory.IsPresent
            }
            Write-Information "Plotting started, PID = $PID"
        } # else
    } #if chia path exits
}