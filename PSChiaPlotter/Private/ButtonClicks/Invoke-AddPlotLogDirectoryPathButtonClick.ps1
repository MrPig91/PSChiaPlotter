function Invoke-AddPlotLogDirectoryPathButtonClick {
    [CmdletBinding()]
    param(
        $PlotLogDirPath
    )
    $AddPlotPathScript = [powershell]::Create().AddScript{
        param(
            $PlotLogDirPath
        )
        try{
            $ErrorActionPreference = "Stop"
            Add-Type -AssemblyName PresentationFramework
    
            #Import required assemblies and private functions
            Get-childItem -Path $DataHash.PrivateFunctions -File -Recurse | ForEach-Object {Import-Module $_.FullName}
            Get-childItem -Path $DataHash.Classes -File | ForEach-Object {Import-Module $_.FullName}

            $UIHash.AddPlotLogPath_Button.Dispatcher.Invoke([action]{$UIHash.AddPlotLogPath_Button.IsEnabled = $false})
            #$PlotLogDirPath = $UIHash.AddPlotLog_TextBox.Text
            if ($DataHash.MainViewModel.PlotLogDirectoryPaths.Contains($PlotLogDirPath)){
                [void](Show-MessageBox -Text "This log directory has already been added!" -Icon Warning)
                return
            }
    
            if (Test-Path -Path $PlotLogDirPath -PathType Container){
                $AllPlotLogs = (Get-ChildItem -Path $PlotLogDirPath -File).FullName
                if ($null -ne $AllPlotLogs){
                    $AllLogStats = $null
                    $AllLogStats = Get-ChiaPlottingStatistic -Path $AllPlotLogs
                    $newlogstats = foreach ($stat in $AllLogStats){
                        try{
                            $phase1 = New-TimeSpan -Seconds $stat.Phase_1_sec
                            $phase2 = New-TimeSpan -Seconds $stat.Phase_2_sec
                            $phase3 = New-TimeSpan -Seconds $stat.Phase_3_sec
                            $phase4 = New-TimeSpan -Seconds $stat.Phase_4_sec
                            $totaltime = New-TimeSpan -Seconds $stat.TotalTime_sec
                            $copyTime = New-TimeSpan -Seconds $stat.CopyTime_sec
                            $copyandplot = New-TimeSpan -Seconds $stat.PlotAndCopyTime_sec
                
                            if ($stat.PlotId){
                                $stat | Add-Member -NotePropertyMembers @{
                                    Phase_1 = $phase1
                                    Phase_2 = $phase2
                                    Phase_3 = $phase3
                                    Phase_4 = $phase4
                                    PlotTime = $totaltime
                                    CopyPhase = $copyTime
                                    PlotAndCopy = $copyandplot
                                    ParentFolder = $PlotLogDirPath
                                }
                                $stat
                            }
                            Clear-Variable "phase1","phase2","phase3","phase4","totaltime","copyTime","copyandplot" -ErrorAction SilentlyContinue
                        }
                        catch{
                            Write-Information "Unable to add time span properties"
                        }
                    }
                    foreach ($logstat in $newLogStats){
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
        Finally{
            $UIHash.AddPlotLogPath_Button.Dispatcher.Invoke([action]{$UIHash.AddPlotLogPath_Button.IsEnabled = $true})
        }
    }.AddParameters($PSBoundParameters) #script
    $AddPlotPathScript.RunspacePool = $ScriptsHash.RunspacePool
    [void]$AddPlotPathScript.BeginInvoke()
}