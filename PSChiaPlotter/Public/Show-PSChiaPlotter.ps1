function Show-PSChiaPlotter {
    [CmdletBinding()]
    param(
        [switch]$DebugWithNotepad,
        [Parameter(DontShow)]
        [switch]$NoNewWindow,
        [Parameter(DontShow)]
        [int]$Threads = [int]$ENV:NUMBER_OF_PROCESSORS
    )
    Add-Type -AssemblyName PresentationFramework

    $PSChiaPlotterFolderPath = "$ENV:LOCALAPPDATA\PSChiaPlotter"
    if (-not(Test-Path -Path $PSChiaPlotterFolderPath)){
        New-Item -Path $PSChiaPlotterFolderPath -ItemType Directory | Out-Null
    }

    if (-not$PSBoundParameters.ContainsKey("Threads")){
        $Threads = [int]$ENV:NUMBER_OF_PROCESSORS
        if ($Threads -eq 0){
            Write-Warning "Unable to grab the CPU thread count... please enter the thread count below"
            $Respnose = Read-Host -Prompt "How many CPU Threads does this system have?"
            foreach ($char in $Respnose.ToCharArray()){
                if (-not[char]::IsNumber($char)){
                    Write-Warning "You didn't enter in a number..."
                    return
                }
            } #foreach
            $Threads = [int]$Respnose
            if (([int]$Threads -le 0)){
                Write-Warning "You didn't enter in a number above 0... exiting"
                return
            }
        }
    }

    $PSChiaPlotterFolderPath = Join-Path -Path $ENV:LOCALAPPDATA -ChildPath 'PSChiaPlotter\Logs'
    $LogName = (Get-Date -Format yyyyMMdd) + '_debug.log'
    $LogPath = Join-Path -Path $PSChiaPlotterFolderPath -ChildPath $LogName
    if (-not$NoNewWindow.IsPresent){
        $parameters = @{
            FilePath = "powershell.exe"
            ArgumentList = "-NoExit -NoProfile -STA -Command Show-PSChiaPlotter -NoNewWindow -Threads $Threads"
            WindowStyle = "Hidden"
            RedirectStandardOutput = $LogPath
        }
        Start-Process @parameters
        return
    }
    #Start-Transcript -Path $LogPath | Out-Null

    $Global:UIHash = [hashtable]::Synchronized(@{})
    $Global:DataHash = [hashtable]::Synchronized(@{})
    $Global:ScriptsHash = [hashtable]::Synchronized(@{})
    $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $UISync = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new("UIHash", $UIHash, $Null)
    $DataSync = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new("DataHash", $DataHash, $Null)
    $ScriptsSync = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new("ScriptsHash", $ScriptsHash, $Null)
    $InitialSessionState.Variables.Add($UISync)
    $InitialSessionState.Variables.Add($DataSync)
    $InitialSessionState.Variables.Add($ScriptsSync)

    $MaxThreads = ([int]$Threads + 5)
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1,$MaxThreads,$InitialSessionState,$Host)
    $RunspacePool.ApartmentState = "STA"
    $RunspacePool.ThreadOptions = "ReuseThread"
    $RunspacePool.open()

    #DataHash Adding Properties
    $DataHash.ModuleRoot = $MyInvocation.MyCommand.Module.ModuleBase
    $DataHash.PrivateFunctions = Join-Path -Path $DataHash.ModuleRoot -ChildPath "Private"
    $DataHash.WPF = Join-Path -Path $DataHash.ModuleRoot -ChildPath "WPFWindows"
    $DataHash.Classes = Join-Path -Path $DataHash.ModuleRoot -ChildPath "Classes"
    $DataHash.Runspaces = New-Object System.Collections.Generic.List[System.Object]
    #DEBUG SWITCH
    $DataHash.Debug = $DebugWithNotepad.IsPresent
    $DataHash.LogPath = $LogPath

    $ScriptsHash.RunspacePool = $RunspacePool

    #Import required assemblies and private functions
    Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
    #Get-childItem -Path $DataHash.Assemblies -File | ForEach-Object {Add-Type -Path $_.FullName}

    
    #$QueueRunspace = New-ChiaQueueRunspace
    #$QueueRunspace.Runspacepool = $RunspacePool
    #$ScriptsHash.QueueRunspace = $QueueRunspace

    #Create UI Thread
    $UIRunspace = New-UIRunspace
    $UIRunspace.RunspacePool = $RunspacePool
    $DataHash.UIRunspace = $UIRunspace
    $DataHash.UIHandle = $UIRunspace.BeginInvoke()
    $Date = Get-Date -Format "[yyyy-MM-dd.HH:mm:ss]"
    Write-Host "[INFO]-$Date-Staring PSChiaPlotter GUI - PID = $($PID)"

    $UIHash.NewWindow = $true
    $UIHash.PowershellPID = $PID

    $RunspacePoolEvent = Register-ObjectEvent -InputObject $DataHash.UIRunspace -EventName InvocationStateChanged -Action {
        $NewState = $Event.Sender.InvocationStateInfo.State
        #Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
        #for some reason importing the private functions is not working...
        $Date = Get-Date -Format "[yyyy-MM-dd.HH:mm:ss]"
        if ($NewState -eq "Completed"){
            try{
                $ScriptsHash.RunspacePool.Close()
                $ScriptsHash.RunspacePool.Dispose()
                if ($UIHash.NewWindow){
                    
                    $Message = "PSChiaPlotter has been closed... Stopping Powershell process with PID of $($UIHash.PowershellPID)"
                    Write-Host "[INFO]-$Date-$Message"
                    Stop-Process -Id $UIHash.PowershellPID -Force
                }
            }
            catch{
                $Date = Get-Date -Format "[yyyy-MM-dd.HH:mm:ss]"
                $Message = "PSChiaPlotter has been closed... unable to stop powershell process with PID of $($UIHash.PowershellPID)"
                Write-Host "[WARNING]-$Date-$WARNING-$Message"
                Write-Host "[ERROR]-$Date-$($_.InvocationInfo.ScriptLineNumber)-$($_.Exception.Message)"
            }
        }
        else{
            #do nothing
        }
    }
}