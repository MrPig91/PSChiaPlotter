function Test-AlternativePlotterParameters {
    [CmdletBinding()]
    param()

    try{
        $ChiaParameters = $DataHash.NewJobViewModel.NewChiaJob.InitialChiaParameters
        if ($ChiaParameters.AlternativePlotterEnabled -eq $true){
            if (-not(Test-Path -Path $ChiaParameters.AlternativePlotterPath -PathType Leaf)){
                return "The path to the alternative plotter is invalid - [$($ChiaParameters.AlternativePlotterPath)]"
            }
            
            if ($ChiaParameters.PoolContractEnabled){
                if ([string]::IsNullOrEmpty($ChiaParameters.PoolContractAddress)){
                    return "You must supply a Pool Contract Address for the alternative plotter to use!"
                }
            }
            else{
                if ([string]::IsNullOrEmpty($ChiaParameters.PoolPublicKey)){
                    return "You must supply a pool public key for the alternative plotter to use!"
                }
            }

            if ([string]::IsNullOrEmpty($ChiaParameters.FarmerPublicKey)){
                return "You must supply a farmer public key for the alternative plotter to use!"
            }
            if ($ChiaParameters.KSize.KSizeValue -ne 32){
                return "Currently alternative plotter does not accept any KSize other than 32, please change KSize to 32"
            }
            [void](Show-MessageBox -Text "PSChiaPlotter will not check for temp free space when using alternative plotters, so please read space requirments based on the plotter's documentation and use accordingly!" -Icon Information)
        }
        return $true
    }
    catch{
        return $_.Exception.Message
        Write-PSChiaPlotterLog -LogLevel "Error" -ErrorObject $_
    }
}