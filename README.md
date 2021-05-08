# PSChiaPlotter
A repo for powershell module that helps Chia Plotting. 

Run this in Powershell one time to add the Chia.exe directory to your $ENV:Path in your profile script so that it is available every time you open powershell.

```Powershell
$addToProfile = '
$chiapath = (get-item "$env:LOCALAPPDATA\Chia-Blockchain\app-*\resources\app.asar.unpacked\daemon\").fullname

$env:Path =  $env:Path + "; $chiapath"
'

Add-Content -Path $profile.CurrentUserAllHosts -Value $addToProfile
```

If you want a very basic chia scripting file for parallel plotting with delays you can use the one below. Chia.exe directory must be added to $ENV:Path as shown below.
```Powershell
param(
[int]$parallel = 3,
[int]$delay = 3600,
[int]$PlotsPerQueue = 1,
[int]$Buffer = 3390,
[int]$Threads = 2,
[Parameter(Mandatory)]
[string]$tempDir,
[Parameter(Mandatory)]
[string]$FinalDir,
[Parameter(Mandatory)]
[string]$LogDir
)

for ($i = 1; $i -le $parallel;$i++){
$date = Get-date -format yyyy-MM-dd-hh-mm-ss
$logpath = Join-Path $LogDir $date
Start-Process -FilePath powershell.exe -ArgumentList "chia.exe plots create -n $plotsperQueue -b $Buffer -r $Threads -t $tempDir -d $FinalDir | Tee-Object -FilePath $($LogPath)_$($i).log"
Start-Sleep -Seconds 3600
}
```
