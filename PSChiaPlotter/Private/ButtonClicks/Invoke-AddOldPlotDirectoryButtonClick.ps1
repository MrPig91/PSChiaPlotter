function Invoke-AddOldPlotDirectoryButtonClick {
    [CmdletBinding()]
    param(
        [string]$Path
    )

    try{
        if (-not$DataHash.NewJobViewModel.NewChiaJob.BasicPlotting){
            $ValidPath = $false
            foreach ($path in $OldDirectories_ListBox.DataContext.AccessPaths){
                if ($OldDirectories_ListBox.DataContext.DirectoryPath.StartsWith($path)){
                    $ValidPath = $true
                }
            } #foreach
            if (-not$ValidPath){
                [void](Show-MessageBox "The replot directory path does not exists in the volume you are trying to replot!")
            }
        }
        if ($OldDirectories_ListBox.DataContext.DirectoryPath -eq $path){
            Show-MessageBox -Text "Your 'New Plot Directory' cannot be the same as a replot diretory!`n`nPlease change your 'New Plot Directory'!" -Icon Warning | Out-Null
            return
        }
        if ([System.IO.Directory]::Exists($Path)){
    
            if ($Path -in $OldDirectories_ListBox.DataContext.OldPlotDirectories.Path){
                Show-MessageBox -Icon Warning -Text "This old plot directory has already been added!" | Out-Null
                return
            }
            $currentKSize = $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.KSize.KSizeValue
            $plots = Get-ChildItem -Path $Path -Filter "*.plot"
            $matchedPlots = $plots | where Name -like "plot-k$($currentKSize)*.plot"
            $plotcount = ($matchedPlots | Measure-Object).Count

            if ($plotcount -ge 1){
                [PSChiaPlotter.OldPlotDirectory]::new($path,$plotcount,$currentKSize)
            }
            elseif (($plots | Measure-Object).Count -ge 1){
                Show-MessageBox -Text "Plots were found, but they are not K$currentKSize and cannot be replotted with the current settings!" -Icon Warning | Out-Null
            }
            else{
                Show-MessageBox -Text "No plots were found of any KSize in this directory!" -Icon Warning | Out-Null
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