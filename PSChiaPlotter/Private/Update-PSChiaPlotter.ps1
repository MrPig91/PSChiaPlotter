function Update-PSChiaPlotter {
    [CmdletBinding()]
    param()

    $UpdateScript = [powershell]::Create().AddScript{
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName System.Windows.Forms
        Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Classes -File | ForEach-Object {Import-Module $_.FullName}
        Import-Module -Name PSChiaPlotter

        $CurrentModule = Get-Module -Name PSChiaPlotter
        $NewestModule = Find-Module -Name PSChiaPLotter -Repository PSGallery
        if ($NewestModule.Version -gt $CurrentModule.Version){
            $Response = Show-Messagebox -Text "New version found! Version - $($NewestModule.Version.ToString())`nWould you like to update now?" -Buttons YesNo
            if ($Response -eq [System.Windows.MessageBoxResult]::Yes){
                try{
                    Update-Module -Name PSChiaPlotter -Force -ErrorAction Stop
                    $message = "PSChiaPlotter module successfully updated from $($CurrentModule.Version.ToString()) to $($NewestModule.Version.ToString())"
                    $message += "`nYou must restart the GUI before changes can take effect.`nOnly do this when your plots have finished!"
                    Write-PSChiaPlotterLog -LogType INFO -Message $message
                    Show-Messagebox -Text $message | Out-Null
                }
                catch{
                    Write-PSChiaPlotterLog -LogType ERROR -Message $_.Exception.Message -LineNumber $_.InvocationInfo.ScriptLineNumber
                    Show-Messagebox -Text "Unable to update to the latest version. Check logs more info" | Out-Null
                }
            }
        }
        else{
            Try{
                Show-Messagebox -Text "Your PSChiaPlotter is up to date!" | Out-Null
            }
            catch{
                Write-PSChiaPlotterLog -LogType ERROR -Message $_.Exception.Message -LineNumber $_.InvocationInfo.ScriptLineNumber
            }
        }
    }
    $UpdateScript.RunspacePool = $ScriptsHash.Runspacepool
    $UpdateScript.BeginInvoke()
}