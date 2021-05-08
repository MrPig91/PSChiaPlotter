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
