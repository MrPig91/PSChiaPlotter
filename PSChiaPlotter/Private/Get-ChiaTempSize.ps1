function Get-ChiaTempSize{
    [CmdletBinding()]
    param(
        $DirectoryPath,
        $PlotId
    )
    if ($PlotId -ne $null){
        $tepmSize = (Get-ChildItem -Path $DirectoryPath -Filter "*$plotid*.tmp" | Measure-Object -Property Length -Sum).Sum
        [math]::Round($tepmSize)
    }
}