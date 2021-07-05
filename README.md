# PSChiaPlotter

A repo for powershell module that helps Chia Plotting. 

## Installation
Open a powershell as administrator and run the following command:
```Powershell
Install-Module -Repository PSGallery -Name PSChiaPlotter
```

If you want to update to the latest version, run this command:
```Powershell
Update-Module PSChiaPlotter
```

If you get and error like the following "The 'Command' command was found in the module 'PSChiaPlotter', but the module could not be loaded." then you will need to set your Execution Policy to remote signed by running the command below. Please note that execution policy is not a security feature, so changing it will not make your system more or less secure. Execution Policy is used to prevent you from accidentally running scripts that goes aganist the policy, but it does not prevent those scripts being ran in bypass mode. You can read more about Execution Policy on its about page [here](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.1)
```Powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
```

## Setup
Run this in Powershell one time to add the Chia.exe directory to your $ENV:Path in your profile script so that it is available every time you open powershell. This is not necessary to use the module but very useful for quickly using the chia.exe cli tool.

```Powershell
$addToProfile = '
$chiapath = (get-item "$env:LOCALAPPDATA\Chia-Blockchain\app-*\resources\app.asar.unpacked\daemon\").fullname

$env:Path =  $env:Path + "; $chiapath"
'

Add-Content -Path $profile.CurrentUserAllHosts -Value $addToProfile
```

If you get an error stating "Add-Content : Could not find a part of the path "C:\Users\yourUSERNAME\Documents\WindowsPowerShell\profile.ps1"." Then you made need to create any missing folders in that path.

## Video Guides
Using the PSChiaPlotter Plot Manager GUI

[![Plot Manager GUI Video](https://img.youtube.com/vi/ka4hb82r3Y8/0.jpg)](https://www.youtube.com/watch?v=ka4hb82r3Y8)

Basic Chia Plotting Using Powershell Guide

[![Plot Manager GUI Video](https://img.youtube.com/vi/FJ6zAeDji5A/0.jpg)](https://www.youtube.com/watch?v=FJ6zAeDji5A)

Advanced Chia Plotting Using Powershell - Adding Progress Bar

[![Plot Manager GUI Video](https://img.youtube.com/vi/nJcgnJHgQF4/0.jpg)](https://www.youtube.com/watch?v=nJcgnJHgQF4)

How to user Start-ChiaHarvesterWatcher and Get-ChiaHarvesterActivity To Check Harvester Health

[![Plot Manager GUI Video](https://img.youtube.com/vi/wOLakMJDLTw/0.jpg)](https://www.youtube.com/watch?v=wOLakMJDLTw)

## Road Map
The following is a list of things I want to add or improve on in the module. Not listed in any particular order.

:white_check_mark: 1. Start-ChiaHarvesterWatcher
  - :white_check_mark: Add blue color block when a proof is found. Also change RGB to last look up time - Version 1.0.29+
  - :white_check_mark: Add DarkMode and NoWalls - Version 1.0.29+
- [ ] 2. Show-PSChiaPlotter 
  - :white_check_mark: Add phase 1 concurrent plot limiter - Version 1.0.32+
  - :white_check_mark: Add seeing RAID drives - Version 1.0.28+
  - :white_check_mark: Add buckets parameter
  - :white_check_mark: Add option to remove safety feature that prevents over allocating space when plotting - Version 1.0.28+
  - :white_check_mark: Add KSize option instead of having K32 only - Version 1.0.32+
  - :white_check_mark: Add Job Name - Version 1.0.28+
  - :white_check_mark: Add Drive Rotation in final and temp drives - Version 1.0.28+
  - :white_check_mark: Add PSChiaPlotter Version on summary groupbox or somewhere - Version 1.0.30+
  - :white_check_mark: Add Auto Check For Updates (or maybe a buttont to check for updates) - Version 1.0.30+
  - :white_check_mark: Add Logging Capabaility with different logging levels - Version 1.0.30+
  - :white_check_mark: Have GUI window not dependent on the Powershell window that started it - Version 1.0.30+
  - :white_check_mark: Add 2nd Temp Parameter - Version 1.0.32+
  - :white_check_mark: Add Saving Jobs For Reuse - Version 1.0.32+
  - :white_check_mark: Add Basic Plotting Directories As Alternative Option - Version 1.0.32+
  - :white_check_mark: Add Phase % text and progress bar in background of the cell - Version 1.0.32+
  - :white_check_mark: Update module when pool plotting comes out - Version 1.0.46+
  - :white_check_mark: Added Button column on Completed Runs tab for checking finished plot - Version 1.0.43+
  - :white_check_mark: Add Madmax Alternative Plot Option (User can use a textbox to provide a path to the .exe) - Version 1.0.47+
  - :white_check_mark: Add Replot Feature - Version 1.0.46+
  - :white_check_mark: Add Tab page to show a datagrid with all plotting stats - Version 1.0.50+
  - [ ] Add Current and Completed Tabs for Queue groupbox 
  - [ ] Add the ability to add and remove columns on datagrids  
  - [ ] Notifications Integration (Discord, Toast, etc.)
  - [ ] Add The Ability To Add More Plots To Running Jobs
  - [ ] Global Phase 1 Limitor
  - [ ] Add Dark Mode
  
- [ ] 3. Get-ChiaKPlotCombination
  - [ ] Add which KSize parameter to filter out which KSizes you want
- [ ] 4. All Functions
  - [ ] Add Comment Based Help with at least 2 examples for each
  - [ ] Add ValueFromPipeline for functions that could use it

## Example Script
If you want a very basic chia scripting file for parallel plotting with delays you can use the one below. Chia.exe directory must be added to $ENV:Path as shown above. Please note this script has nothing to do with the functions in this module and is only here to show people who want to write their own scripts using powershell.
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
  Start-Sleep -Seconds $delay
}
```

## Donate
If you find these tools useful and want to donate you can use any of the below addresses.

XCH: xch1xlsrczvnfzjfeg7ejpaxy7evcn0nvsr73s4gcmzdqd7zkzlvy8ds49qvv2

ETH: 0xeeb3d0FEECaAfEd8BBC705370579689BFA024Be4

XMR: 4Adn4LNiaqjUfkAq1RNmLLcRd2oBDdGx8HWL4L76eZmMWQGbowrYhvuajRCdFYLq6pGAPgXYE9P3g2wvVp36FFRn3EAzRjW

BAN: ban_37o6aossupgce34dma9r6na4hi79j6mhqrtp1gkr8ygz6nxjz8t9q3emkp4h
