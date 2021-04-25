function Get-ChiaKPlotCombination{
    [CmdletBinding(DefaultParameterSetName = "DriveLetter")]
    param(
        [Parameter(ParameterSetName="FreeSpace")]
        [int64[]]$FreeSpace,
        [Parameter(ParameterSetName="DriveLetter")]
        [string[]]$DriveLetter = (Get-Volume).DriveLetter
    )

    if ($PSCmdlet.ParameterSetName -eq "FreeSpace"){
        foreach ($space in $FreeSpace){
            $Max = Get-MaxKSize -TotalBytes $space
            $AllCombos = Get-OptimizedKSizePlotNumbers $Max | sort RemainingBytes
            $AllCombos | Add-Member -MemberType NoteProperty -Name "StartingFreeSpace" -Value $space
            $AllCombos
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq "DriveLetter"){
        foreach ($letter in $DriveLetter){
            $Drive = Get-Volume -DriveLetter $letter
            $Max = Get-MaxKSize -TotalBytes $Drive.SizeRemaining
            $AllCombos = Get-OptimizedKSizePlotNumbers $Max | sort RemainingBytes
            $AllCombos | Add-Member -NotePropertyMembers @{
                DriveLetter = $letter
                FriendlyName = $Drive.FileSystemLabel
            }
            $AllCombos.psobject.TypeNames.Insert(0,"PSChiaPlotter.KSizeCombination")
            $AllCombos
        }
    }
}