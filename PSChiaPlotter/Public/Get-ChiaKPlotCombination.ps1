function Get-ChiaKPlotCombination {
    <#
        .SYNOPSIS
            Display compatible combinations of kplots to fill and maximize drive space.
        .DESCRIPTION
            List all possible kplot combinations to use in order to maximize remaining drive space.
        .PARAMETER FreeSpace
            Specify the number of bytes to determine available combinations. Doesn't check drives.
        .PARAMETER DriveLetter
            Specify a drive letter to check combinations on a specific drive.
        .PARAMETER UpTo
            Specify to only return combinations with this being the max kplot.
            Option Values (no 'k'): 32, 33, 34 or default of 35 (default is all combinations)
        .PARAMETER c
            Clear the screen prior to displaying the requested information.
        .INPUTS
            Inputs (if any)
        .OUTPUTS
            Displays a list of possible kplot combinations to maximize drive space.
        .EXAMPLE
            PS> Get-ChiaKPlotCombination

            DriveLetter FriendlyName    K35 K34 K33 K32 RemainingGB
            ----------- ------------    --- --- --- --- -----------
            J:          Seagate Drive   1   2   0   1   17.73
            J:          Seagate Drive   1   1   2   1   29.93
            J:          Seagate Drive   1   0   2   5   54.13
            J:          Seagate Drive   1   0   1   7   60.13
            J:          Seagate Drive   1   0   0   9   66.13
            J:          Seagate Drive   2   0   0   0   94.63
            E:          General         1   2   1   11  2.53
            E:          General         1   1   5   7   2.73
            E:          General         1   2   0   13  8.53
            E:          General         1   1   6   4   98.13
            E:          General         1   0   10  0   98.33
            D:          Webserv         1   0   1   0   72.09
            D:          Webserv         1   0   0   2   78.09

            This example displays a list of possible kplot combinations based off the available freespace on
            each connected drive.
        .EXAMPLE
            PS> Get-ChiaKPlotCombination -FreeSpace 1112969701922

            StartingFreeSpace K35 K34 K33 K32 RemainingGB
            ----------------- --- --- --- --- -----------
            1112969701922     1   0   0   1   51.03

            This example displays a list of possible kplot combinations if the available drive space
            was 1112969701922 bytes (1112.97 GB).
        .EXAMPLE
            PS> Get-ChiaKPlotCombination -DriveLetter E

            DriveLetter FriendlyName K35 K34 K33 K32 RemainingGB
            ----------- ------------ --- --- --- --- -----------
            E:          General      3   0   2   0   0.53
            E:          General      1   2   1   11  2.53
            E:          General      1   1   5   7   2.73
            E:          General      1   0   9   3   2.93
            E:          General      3   0   1   2   6.53
            E:          General      1   2   0   13  8.53
            E:          General      1   2   2   8   97.93
            E:          General      1   1   6   4   98.13
            E:          General      1   0   10  0   98.33

            This example displays a list of possible kplot combinations on the E drive.
        .EXAMPLE
            PS> Get-ChiaKPlotCombination -DriveLetter j -c

            DriveLetter FriendlyName    K35 K34 K33 K32 RemainingGB
            ----------- ------------    --- --- --- --- -----------
            J:          Seagate Drive   1   2   0   1   17.73
            J:          Seagate Drive   1   1   2   1   29.93
            J:          Seagate Drive   1   0   2   5   54.13
            J:          Seagate Drive   1   0   1   7   60.13
            J:          Seagate Drive   1   0   0   9   66.13
            J:          Seagate Drive   2   0   0   0   94.63

        .EXAMPLE
            PS> Get-ChiaKPlotCombination -upto 33

            DriveLetter FriendlyName    K35 K34 K33 K32 RemainingGB
            ----------- ------------    --- --- --- --- -----------
            J:          Seagate Backup Plus Drive 0   0   6   6   1.63
            J:          Seagate Backup Plus Drive 0   0   5   8   7.63
            J:          Seagate Backup Plus Drive 0   0   4   10  13.63
            J:          Seagate Backup Plus Drive 0   0   3   12  19.63
            J:          Seagate Backup Plus Drive 0   0   2   14  25.63
            E:          General                   0   0   4   22  4.21
            E:          General                   0   0   3   24  10.21
            E:          General                   0   0   2   26  16.21
            E:          General                   0   0   1   28  22.21
            E:          General                   0   0   14  1   45.61
            G:          Seagate Backup Plus Drive 0   0   1   1   96.08
            D:          Webserv                   0   0   5   1   20.3
            D:          Webserv                   0   0   4   3   26.3
            D:          Webserv                   0   0   3   5   32.3
            D:          Webserv                   0   0   2   7   38.3
            D:          Webserv                   0   0   1   9   44.3

            This example displays a list of all possible kplot combinations, with K33 being the largest, based
            off the available freespace on each connected drive. Can be used with all other parameters.
        .LINK
            PowerShell Gallery: https://www.powershellgallery.com/packages/PSChiaPlotter
        .LINK
            GitHub Project: https://github.com/MrPig91/PSChiaPlotter
    #>
    [CmdletBinding(DefaultParameterSetName = "DriveLetter")]
    param(
        [Parameter(ParameterSetName = "FreeSpace")]
        [int64[]]$FreeSpace,
        [Parameter(ParameterSetName = "DriveLetter")]
        [string[]]$DriveLetter = (Get-Volume).DriveLetter,
        [int]$UpTo = 35,
        [switch]$c
    )
    if ($c) { Clear-Host }
    if ($PSCmdlet.ParameterSetName -eq "FreeSpace") {
        foreach ($space in $FreeSpace) {
            $Max = Get-MaxKSize -TotalBytes $space
            $AllCombos = Get-OptimizedKSizePlotNumbers -MaximizedKSize $Max -KSFilter $UpTo | Sort-Object RemainingBytes
            $AllCombos | Add-Member -MemberType NoteProperty -Name "StartingFreeSpace" -Value $space
            $AllCombos
        }#foreach
    }
    elseif ($PSCmdlet.ParameterSetName -eq "DriveLetter") {
        foreach ($letter in $DriveLetter) {
            if ($letter -eq "" ) { continue } #Skip empty values
            $letter = $letter.Trim(":") #Prevent error when colon is included
            $Drive = Get-Volume -DriveLetter $letter
            if ($Drive.FileSystemLabel -eq "" ) { continue } #Skip empty values
            $Max = Get-MaxKSize -TotalBytes $Drive.SizeRemaining
            $AllCombos = Get-OptimizedKSizePlotNumbers -MaximizedKSize $Max -KSFilter $UpTo | Sort-Object RemainingBytes
            $AllCombos | Add-Member -NotePropertyMembers @{
                DriveLetter  = $letter + ":" #Add colon
                FriendlyName = $Drive.FileSystemLabel
            }#foreach
            $AllCombos | ForEach-Object { $_.psobject.TypeNames.Insert(0, "PSChiaPlotter.KSizeCombination") }
            $AllCombos
        }#foreach
    }#if
}