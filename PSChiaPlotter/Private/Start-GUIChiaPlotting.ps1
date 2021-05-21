function Start-GUIChiaPlotting {
    [CmdletBinding()]
    param(
<#         [Parameter()]
        [ValidateScript({[System.IO.Directory]::Exists($_)})]
        [string]$SecondTempDirecoryPath, #>
        #$FarmerPublicKey,
        #$PoolPublicKey,

        $ChiaRun,
        $ChiaQueue,
        $ChiaJob
    )

    $PlottingParameters = $ChiaRun.PlottingParameters
    $KSize = $PlottingParameters.KSize
    $Buffer = $PlottingParameters.RAM
    $Threads = $PlottingParameters.Threads
    $DisableBitfield = $PlottingParameters.DisableBitField
    $ExcludeFinalDirectory = $PlottingParameters.ExcludeFinalDirectory
    $TempDirectoryPath = $PlottingParameters.TempVolume.DirectoryPath
    $FinalDirectoryPath = $PlottingParameters.FinalVolume.DirectoryPath
    $LogDirectoryPath = $PlottingParameters.LogDirectory
    $SecondTempDirecoryPath = $PlottingParameters.TempVolume.DirectoryPath

    $E = if ($DisableBitfield){"-e"}
    $X = if ($ExcludeFinalDirectory){"-x"}

    #remove any trailing '\' since chia.exe hates them
    $TempDirectoryPath = $TempDirectoryPath.TrimEnd('\')
    $FinalDirectoryPath = $FinalDirectoryPath.TrimEnd('\')

    #path to chia.exe
    $ChiaPath = (Get-Item -Path "$ENV:LOCALAPPDATA\chia-blockchain\app-*\resources\app.asar.unpacked\daemon\chia.exe").FullName
    $ChiaArguments = "plots create -k $KSize -b $Buffer -r $Threads -t `"$TempDirectoryPath`" -d `"$FinalDirectoryPath`" $E $X"


    if ($SecondTempDirecoryPath){
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
        try{
            $LogPath = Join-Path $LogDirectoryPath ((Get-Date -Format yyyy_MM_dd_hh-mm-ss-tt_) + "plotlog-" + $plotNumber + ".log")
            $PlottingParam = @{
                FilePath = $ChiaPath
                ArgumentList = $ChiaArguments
                RedirectStandardOutput = $LogPath
                NoNewWindow = $true
            }
            $chiaProcess = Start-Process @PlottingParam -PassThru 3> $Null

            $ChiaRun.ChiaProcess = $ChiaProcess
            $ChiaRun.ProcessId = $ChiaProcess.Id
            $ChiaJob.RunsInProgress.Add($ChiaRun)

            $ChiaRun.PlottingParameters.TempVolume.CurrentChiaRuns.Add($ChiaRun)
            #$FinalVolume.CurrentChiaRuns.Add($ChiaRun)
            $ChiaQueue.CurrentRun = $ChiaRun
            $DataHash.MainViewModel.CurrentRuns.Add($ChiaRun)

            #Have noticed that giving the process a second to start before checking the logs works better
            Start-Sleep 1
        
            while (!$chiaProcess.HasExited){
                try{
                    $progress = Get-ChiaPlotProgress -LogPath $LogPath -ErrorAction Stop
                    $plotid = $progress.PlotId
                    $ChiaRun.Progress = $progress.progress
                    $ChiaQueue.CurrentTime = [DateTime]::Now
                    $ChiaRun.CurrentTime = [DateTime]::Now
                    $ChiaRun.Phase = $progress.Phase
                    if ($progress.EST_TimeReamining.TotalSeconds -le 0){
                        $ChiaRun.EstTimeRemaining = New-TimeSpan -Seconds 0
                    }
                    else{
                        $ChiaRun.EstTimeRemaining = $progress.EST_TimeReamining
                    }
                    $ChiaRun.EstTimeRemaining = $progress.EST_TimeReamining
                    Start-Sleep (5 + $ChiaQueue.QueueNumber)
                }
                catch{
                    Start-Sleep 30
                }
            } #while

            $ChiaJob.RunsInProgress.Remove($ChiaRun)
            $ChiaJob.CompletedPlotCount++
            $ChiaRun.ExitCode = $ChiaRun.ChiaPRocess.ExitCode
            #$ChiaRun.ExitTime = $ChiaProcess.ExitTime

            if ($ChiaRun.ChiaPRocess.ExitCode -ne 0){
                $ChiaRun.Status = "Failed"
                Get-ChildItem -Path $TempDirectoryPath -Filter "*$plotid*.tmp" | Remove-Item -Force
            }
            else{
                $ChiaRun.Status = "Completed"
            }
            $ChiaQueue.CompletedPlotCount++
            $DataHash.MainViewModel.CurrentRuns.Remove($ChiaRun)
            $ChiaRun.PlottingParameters.TempVolume.CurrentChiaRuns.Remove($ChiaRun)
            $DataHash.MainViewModel.CompletedRuns.Add($ChiaRun)
        }
        catch{
            $PSCmdlet.WriteError($_)
        }
    } #if chia path exits
    else{
        $Message = "chia.exe was not found"
        $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.IO.FileNotFoundException]::new($Message,"$ENV:LOCALAPPDATA\chia-blockchain\app-*\resources\app.asar.unpacked\daemon\chia.exe"),
                'ChiaPathInvalid',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                "$ENV:LOCALAPPDATA\chia-blockchain\app-*\resources\app.asar.unpacked\daemon\chia.exe"
            )
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        $PSCmdlet.ThrowTerminatingError("Invalid Log Path Directory: $LogDirectoryPath")
    }
}