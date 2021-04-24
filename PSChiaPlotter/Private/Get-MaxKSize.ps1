function Get-MaxKSize {
    [CmdletBinding()]
    param(
        [ValidateSet("K32","K33","K34","K35")]
        [string[]]$KSize = ("K32","K33","K34","K35"),

        [Parameter(Mandatory)]
        [int64]$TotalBytes
    )

    foreach ($size in $KSize){
        [MaximizedKSize]::new($size,$TotalBytes)
    } #foreach
}