function Invoke-AddPlotLogDirectoryPath {
    [CmdletBinding()]
    param()

    try{
        $PlotLogDirPath = $UIHash.AddPlotLog_TextBox.Text
        if ($DataHash.MainViewModel.PlotLogDirectoryPaths.Contains($PlotLogDirPath)){
            [void](Show-MessageBox -Text "This log directory has already been added!" -Icon Warning)
            return
        }
        
        if (Test-Path -Path $PlotLogDirPath -PathType Container){
            $AllPlotLogs = (Get-ChildItem -Path $PlotLogDirPath -File).FullName
            if ($null -ne $AllPlotLogs){
                $AllLogStats = Get-ChiaPlottingStatistic -Path $AllPlotLogs
                foreach ($logstat in $AllLogStats){
                    if (-not$DataHash.MainViewModel.AllPlottingLogStats.Contains($logstat)){
                        $DataHash.MainViewModel.AllPlottingLogStats.Add($logstat)
                    }
                } #foreach logstat
                $DataHash.MainViewModel.PlotLogDirectoryPaths.Add($PlotLogDirPath)
            }
            else{
                [void](Show-MessageBox -Text "No Log files found in the folder '$PlotLogDirPath'!" -Icon Warning)
            }
        }
        else{
            [void](Show-MessageBox -Text "Path '$PlotLogDirPath' does not exist!" -Icon Warning)
        }
    }
    catch{
        Write-PSChiaPlotterLog -LogType Error -ErrorObject $_
        [void](Show-MessageBox -Text $_.Exception.Message -Title "Add Directory Error" -Icon Error)
    }
}