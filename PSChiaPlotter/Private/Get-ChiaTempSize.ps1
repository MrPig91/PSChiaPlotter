function Get-ChiaTempSize{
    [CmdletBinding()]
    param(
        $DirectoryPath,
        $PlotId
    )
    try{
        if ($PlotId -ne $null){
            $tepmSize = (Get-ChildItem -Path $DirectoryPath -Filter "*$plotid*.tmp" | Measure-Object -Property Length -Sum).Sum
            return [math]::Round($tepmSize / 1gb)
        }
        else{
            return 0
        }
    }
    catch{
        return 0
    }
}