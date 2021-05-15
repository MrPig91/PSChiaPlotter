param(
    [int]$plotTotal = 1,
    [int]$Threads = 2,
    [int]$Buffer = 3390,
    [string]$tempDir,
    [string]$FinalDir,
    [string]$LogDir,
    [string]$QueueName
)

if ((Test-Path -Path $tempDir,$FinalDir,$LogDir) -contains $false){
    Write-Error "Invalid Path Parameter"
    return
}

Import-Module .\Get-ChiaPlotProgress.ps1

for ($plotNumber = 1;$plotNumber -le $plotTotal;$plotNumber++){
    $date = Get-Date -Format yyyy-MM-dd_hh-mm-ss_tt
    $logPath = "$LogDir\$($date)-PlotLog-$plotNumber.log"

    $chiaProcess = Start-Process -FilePath Chia.exe -ArgumentList "plots create -b $Buffer -r $Threads -t $tempDir -d $FinalDir" -PassThru -RedirectStandardOutput $logPath -NoNewWindow
    $host.ui.RawUI.WindowTitle = "$QueueName - Plot $plotNumber out of $plotTotal | Chia Process Id - $($chiaProcess.id)"
    sleep 1

    while (!$chiaProcess.HasExited){
        $progress = Get-ChiaPlotProgress -LogPath $logPath
        Write-Progress -Activity "Queue $($QueueName): Plot $plotNumber out of $plotTotal" -Status "$($progress.phase) - $($progress.Progress)%" -PercentComplete $progress.progress -SecondsRemaining $progress.EST_TimeReamining.TotalSeconds
        sleep 10
    }
}