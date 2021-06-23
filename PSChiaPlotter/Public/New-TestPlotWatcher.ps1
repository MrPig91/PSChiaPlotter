function New-TestPlotWatcher {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]$Path
    )

    Process{
        $Watcher = [System.IO.FileSystemWatcher]::new($Path,"*.plot")
        $Watcher.EnableRaisingEvents = $true
        $Watcher.IncludeSubdirectories = $false

        $Action = {
            $PlotPath = $Event.SourceEventArgs.FullPath
            if ($PlotPath.EndsWith(".plot")){
                $ParentDirectory = Split-Path -Path $PlotPath -Parent
                $CSVPath = Join-Path $ParentDirectory -ChildPath "PlotsCheck.csv"
                Test-ChiaPlot -Path $PlotPath | Export-Csv -Path $CSVPath -NoTypeInformation -Append
            }
        }
        Register-ObjectEvent -InputObject $Watcher -Action $Action -EventName Renamed -SourceIdentifier "$Path-Watcher"
    }
}