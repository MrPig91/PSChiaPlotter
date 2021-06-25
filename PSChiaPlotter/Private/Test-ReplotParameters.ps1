function Test-ReplotParameters{
    [CmdletBinding()]
    param()

    try{
        $ChiaParameters = $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters
        if ($ChiaParameters.ReplotEnabled){
            if ($DataHash.NewJobViewModel.NewChiaJob.BasicPlotting){
                $FinalVolumes = $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.BasicFinalDirectory
            }
            else{
                $FinalVolumes = $DataHash.NewJobViewModel.NewChiaJob.FinalVolumes
            }
            foreach ($replotVolume in $FinalVolumes){
                if (-not$replotVolume.ReplotEnabled){
                    return "ReplotEnabled Property is not true for volume '$($replotVolume.DriveLetter)'.`n`nWhen replotting all final volumes must have plots to replot!"
                }
                if ($replotVolume.OldPlotDirectories.Count -eq 0){
                    return "Volume '$($replotVolume.DriveLetter)' has zero old plot directories added to it. Please a directory to replot!"
                }
                if ($replotVolume.TotalReplotCount -lt 1){
                    return "Volume '$($replotVolume.DriveLetter)' has zero plots to replot, please remove it or add old plot directories to replot!"
                }
                if (($replotVolume.OldPlotDirectories.KSizeValue | Group-Object | Measure-Object).Count -gt 1){
                    return "You are trying to replot different KSizes at the same time... This is not possible with this plot manager."
                }
                if ($replotVolume.OldPlotDirectories[0].KSizeValue -ne $ChiaParameters.KSize.KSizeValue){
                    return "You are trying to replot with a different KSize. This plot manager is not smart enough to do that!`n Please make all KSizes match!"
                }
                if ($replotVolume.DirectoryPath -in $replotVolume.OldPlotDirectories.Path){
                    return "Your new plot directory path cannot be any of the old plot directory paths, please create a new folder for the new plots or move the old plots to a different folder!"
                }
            }
            $TotalReplotCount = ($FinalVolumes.OldPlotDirectories | Measure-Object -Property PlotCount -Sum).Sum
            if ($TotalReplotCount -lt $DataHash.NewJobViewModel.NewChiaJob.TotalPlotCount){
                $Response = Show-MessageBox -Icon Warning -Buttons YesNo -Text "You cannot plot more than the total number of plots you want to replot!`n`nWould you like to change the total plot count to $([string]$TotalReplotCount)?"
                if ($Response -eq [System.Windows.MessageBoxResult]::Yes){
                    $DataHash.NewJobViewModel.NewChiaJob.TotalPlotCount = $TotalReplotCount
                    return $true
                }
                else{
                    return "Either add more plots to replot or lower your total plot count!"
                }
            }
        }
        return $true
    }
    catch{
        Write-PSChiaPlotterLog -LogType Error -ErrorObject $_
        Show-MessageBox -Text $_.Exception.Message -Title "Replot Parameter Check" -Icon Error | Out-Null
        return "Unable to test replot parameters :("
    }
}