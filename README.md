# PSChiaPlotter
A repo for powershell module that helps Chia Plotting. 

I highly recommend running this in powershell to add chia.exe to your ENV:Path variable so you don't have switch to its directory.

```Powershell
$addToProfile = '
$chiapath = (get-item "$env:LOCALAPPDATA\Chia-Blockchain\app-*\resources\app.asar.unpacked\daemon\").fullname

$env:Path =  $env:Path + "; $chiapath"
'

Add-Content -Path $profile.CurrentUserAllHosts -Value $addToProfile
```
