param(
    [int]$Parallel = 3,
    [int]$Delay = 3600,
    [int]$PlotsPerQueue = 1,
    [int]$Buffer = 3390,
    [int]$Threads = 2,
    [Parameter(Mandatory)]
    [ValidateScript({[System.IO.Directory]::Exists($_)})]
    [string]$TempDir,
    [Parameter(Mandatory)]
    [ValidateScript({[System.IO.Directory]::Exists($_)})]
    [string]$FinalDir,
    [Parameter(Mandatory)]
    [ValidateScript({[System.IO.Directory]::Exists($_)})]
    [string]$LogDir
)

for ($queue = 1; $queue -le $parallel; $queue++){
    Start-Process -FilePath powershell.exe -ArgumentList "-file Start-ChiaPlotting.ps1 -plotTotal $plotsperQueue -Buffer $Buffer -Threads $Threads -tempDir $tempDir -FinalDir $FinalDir -LogDir $LogDir -QueueName Run_$queue" -WorkingDirectory $PSScriptRoot
    Start-Sleep -Seconds $Delay
}