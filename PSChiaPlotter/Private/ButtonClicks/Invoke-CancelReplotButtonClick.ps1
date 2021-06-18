function Invoke-CancelReplotButtonClick{
    [CmdletBinding()]
    param()

    try{
        $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters.ReplotEnabled = $false
        foreach ($finalVolume in $DataHash.NewJobViewModel.NewChiaJob.FinalVolumes){
            $finalVolume.ReplotEnabled = $false
        }
        $ReplotConfig_Window.Close()
    }
    catch{
        Write-PSChiaPlotterLog -LogType ERROR -ErrorObject $_
    }
}