function Start-PlotCopyPhase {
    [CmdletBinding()]
    param(
        $RunToCopy,
        $FinalVol,
        $TempVol
    )

    $StartCopyPhaseScript = [powershell]::Create().AddScript{
        Param (
            $RunToCopy,
            $FinalVol,
            $TempVol
        )
        $ErrorActionPreference = "Stop"
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName System.Windows.Forms

        #Import required assemblies and private functions
        Get-childItem -Path $DataHash.PrivateFunctions -File -Recurse | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Classes -File | ForEach-Object {Import-Module $_.FullName}
        try{
            $RunToCopy.Phase = "Copy"
            $RunToCopy.CurrentPhaseProgress = 0
            $RunToCopy.Progress = 98
            if ($RunToCopy.PlottingParameters.AlternativePlotterEnabled -eq $true){
                $tempFinalPath = $RunToCopy.PlottingParameters.TempVolume.DirectoryPath
            }
            else{
                if (-not[string]::IsNullOrEmpty($RunToCopy.PlottingParameters.SecondTempVolume.DirectoryPath)){
                    $tempFinalPath = $RunToCopy.PlottingParameters.SecondTempVolume.DirectoryPath
                }
                else{
                    $tempFinalPath = $RunToCopy.PlottingParameters.TempVolume.DirectoryPath
                }
            }
            $plotPath = Join-Path $tempFinalPath -ChildPath "*$($RunToCopy.PlotId)*"
            $PlotItem = Get-Item -Path $plotPath
            $newplotItem = Rename-Item -Path $PlotItem -NewName "$($PlotItem.Name).tmp" -Force -PassThru
            $MovedItem = Move-Item -Path $NewPlotItem.FullName -Destination $RunToCopy.PlottingParameters.FinalVolume.DirectoryPath -PassThru
            Rename-Item -Path $MovedItem.FullName -NewName $MovedItem.Name.Replace('.tmp','')
            
            $RunToCopy.Progress = 100
            $RunToCopy.CurrentPhaseProgress = 100

            $CopyRunJob = $RunToCopy.ParentQueue.ParentJob
            $CopyRunJob.RunsInProgress.Remove($RunToCopy)
            $CopyRunJob.CompletedRunCount++

            if (-not$CopyRunJob.BasicPlotting){
                $FinalVol.PendingFinalRuns.Remove($RunToCopy)
                $TempVol.CurrentChiaRuns.Remove($RunToCopy)
            }
            $RunToCopy.ExitCode = $RunToCopy.ChiaPRocess.ExitCode
            $RunToCopy.ExitTime = [datetime]::Now

            $RunToCopy.Status = "Completed"
            $CopyRunJob.CompletedPlotCount++
            $RunToCopy.ParentQueue.CompletedPlotCount++
            $DataHash.MainViewModel.CompletedRuns.Add($RunToCopy)
            $RunToCopy.CheckPlotPowershellCommand = "&'$ChiaPath' plots check -g $plotid"
            Update-ChiaGUISummary -Success
            if ($RunToCopy.PlottingParameters.AutoPlotCheckEnabled){
                $PlotCheckResults = Test-ChiaPlot -Path $plotid -ErrorAction Continue
                if ($Null -ne $PlotCheckResults){
                    $RunToCopy.PlotCheckRatio = [math]::Round($PlotCheckResults.Ratio,2)
                }
            } #if autoplotcheck

            $RunToCopy.ParentQueue.CurrentRun = $null
            $DataHash.MainViewModel.CurrentRuns.Remove($RunToCopy)
        }
        catch{
            Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
            if (-not$DataHash.MainViewModel.FailedRuns.Contains($RunToCopy)){
                $DataHash.MainViewModel.FailedRuns.Add($RunToCopy)
            }
            if ($DataHash.MainViewModel.CurrentRuns.Contains($RunToCopy)){
                $DataHash.MainViewModel.CurrentRuns.Remove($RunToCopy)
            }
            if ($CopyRunJob.RunsInProgress.Contains($RunToCopy)){
                $CopyRunJob.RunsInProgress.Remove($RunToCopy)
            }
            if (-not$CopyRunJob.BasicPlotting){
                if ($FinalVol){
                    if ($FinalVol.PendingFinalRuns.Contains($RunToCopy)){
                        $FinalVol.PendingFinalRuns.Remove($RunToCopy)
                    }
                }
            }
        }
    }.AddParameters($PSBoundParameters)
    $StartCopyPhaseScript.RunspacePool = $ScriptsHash.RunspacePool
    [void]$StartCopyPhaseScript.BeginInvoke()
}