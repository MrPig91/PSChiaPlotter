function Get-ChiaKPlotCombination{
    <#
        .SYNOPSIS
            Display compatible combinations of plots to fill a plot.
        
        .DESCRIPTION
            Display compatible combinations of plots to fill a plot.
        
        .PARAMETER FreeSpace
            Specifies the parameter name.
        
        .PARAMETER DriveLetter
            Specifies the extension. "Txt" is the default.
        
        .PARAMETER upto
            Only return combinations with this being the max size.
            Options: 32, 33, 34 or 35 (default is all combinations)
    
        .PARAMETER c
            Clears the screen first.
            
        .INPUTS
            Inputs (if any)
                    
        .OUTPUTS
            Displays a list of possible plot size combinations to maximize drive space.
            
        .EXAMPLE
            PS> Get-ChiaKPlotCombination -FreeSpace 108.877420954
            File.txt
            
        .EXAMPLE
            PS> Get-ChiaKPlotCombination
            File.doc
            
        .EXAMPLE
            PS> Get-ChiaKPlotCombination
            File.doc
            
        .LINK
            PowerShell Gallery: https://www.powershellgallery.com/packages/PSChiaPlotter

        .LINK
            GitHub Project: https://github.com/MrPig91/PSChiaPlotter

        .LINK
            Set-Item
    #>
    [CmdletBinding(DefaultParameterSetName = "DriveLetter")]
    param(
        [Parameter(ParameterSetName="FreeSpace")]
        [int64[]]$FreeSpace,
        [Parameter(ParameterSetName="DriveLetter")]
        [string[]]$DriveLetter = (Get-Volume).DriveLetter,
        [string]$UpTo = "K35",
        [switch]$c
    )
    if($c) { Clear-Host }
    $KSFilter = $UpTo
    if( $KSFilter.Substring(0,1) -ne "K" ) { $KSFilter = "K$UpTo" }
    if ($PSCmdlet.ParameterSetName -eq "FreeSpace"){
        foreach ($space in $FreeSpace){
            $Max = Get-MaxKSize -TotalBytes $space
            $AllCombos = Get-OptimizedKSizePlotNumbers -MaximizedKSize $Max -KSFilter $KSFilter | Sort-Object RemainingBytes
            $AllCombos | Add-Member -MemberType NoteProperty -Name "StartingFreeSpace" -Value $space
            $AllCombos
        }#foreach
    }
    elseif ($PSCmdlet.ParameterSetName -eq "DriveLetter"){
        foreach ($letter in $DriveLetter){
            if($letter -eq "" ) { continue } #Skip empty values
            $letter = $letter.Trim(":") #Prevent error when colon is included
            $Drive = Get-Volume -DriveLetter $letter
            if($Drive.FileSystemLabel -eq "" ) { continue } #Skip empty values
            $Max = Get-MaxKSize -TotalBytes $Drive.SizeRemaining
            $AllCombos = Get-OptimizedKSizePlotNumbers -MaximizedKSize $Max -KSFilter $KSFilter | Sort-Object RemainingBytes
            $AllCombos | Add-Member -NotePropertyMembers @{
                DriveLetter = $letter + ":" #Add colon
                FriendlyName = $Drive.FileSystemLabel
            }#foreach
            $AllCombos | ForEach-Object {$_.psobject.TypeNames.Insert(0,"PSChiaPlotter.KSizeCombination")}
            $AllCombos
        }#foreach
    }#elseif
}