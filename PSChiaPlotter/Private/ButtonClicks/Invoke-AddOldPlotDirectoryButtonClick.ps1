function Invoke-AddOldPlotDirectoryButtonClick {
    [CmdletBinding()]
    param(
        [string]$Path
    )

    try{
        if ([System.IO.Directory]::Exists($Path)){
            
            $currentKSize = $NewJobViewModel.NewChiaJob.InitialChiaParameters.KSize.KSizeValue
            $plots = Get-ChildItem -Path $Path -Filter "*.plot"
            $matchedPlots = $plots | where Name -like "plot-k$($currentKSize)*.plot"
            $plotcount = ($matchedPlots | Measure-Object).Count

            if ($plotcount -ge 1){
                return [PSCustomObject]@{
                    Path = $Path
                    PlotCount = $plotcount
                }
                
            }
            elseif (($plots | Measure-Object).Count -ge 1){
                Show-MessageBox -Text "Plots were found, but they are not K$currentKSize and cannot be plotted with the current settings!" -Icon Warning | Out-Null
            }
            else{
                Show-MessageBox -Text "No plots were found of any KSize for this directory!" -Icon Warning | Out-Null
            }
        }
        else{
            Show-MessageBox -Text "Directory path provided does not exists!" -Icon Warning | Out-Null
        }
    }
    catch{
        Write-PSChiaPlotterLog -LogType Error -ErrorObject $_
        Show-MessageBox -Text $_.Exception.Message -Title "Add Directory Error" -Icon Error | Out-Null
    }
}