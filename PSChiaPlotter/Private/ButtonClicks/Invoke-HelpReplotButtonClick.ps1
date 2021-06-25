function Invoke-HelpReplotButtonClick {
    [CmdletBinding()]
    param()

    try{
        $HowToReplotPath = Join-Path $DataHash.HelpFiles -ChildPath "HowToReplot.Txt"
        Invoke-Item -Path $HowToReplotPath
    }
    catch{
        Write-PSChiaPlotterLog -LogType "Error" -ErrorObject $_
        Show-MessageBox -Text "Unable to open help file :("
    }
}