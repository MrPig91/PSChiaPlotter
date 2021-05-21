function Show-PSChiaPlotter {
    Add-Type -AssemblyName PresentationFramework

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
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1,5,$InitialSessionState,$Host)
    $RunspacePool.ApartmentState = "STA"
    $RunspacePool.ThreadOptions = "ReuseThread"
    $RunspacePool.open()

    #DataHash Adding Properties
    $DataHash.ModuleRoot = $MyInvocation.MyCommand.Module.ModuleBase
    $DataHash.PrivateFunctions = Join-Path -Path $DataHash.ModuleRoot -ChildPath "Private"
    #$DataHash.Assemblies = Join-Path -Path $DataHash.ModuleRoot -ChildPath "Assemblies"
    $DataHash.WPF = Join-Path -Path $DataHash.ModuleRoot -ChildPath "WPFWindows"
    $DataHash.Classes = Join-Path -Path $DataHash.ModuleRoot -ChildPath "Classes"

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
    [void]$UIRunspace.BeginInvoke()
}