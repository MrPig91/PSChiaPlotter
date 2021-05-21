function Get-ChiaVolume {
    [CmdletBinding()]
    param()


    $Volumes = Get-CimInstance -Namespace "ROOT/Microsoft/Windows/Storage" -ClassName MSFT_Volume |
        Where {$_.DriveLetter -ne $Null}

    foreach ($volume in $Volumes){
        $Label = $volume.FileSystemLabel
        if ([string]::IsNullOrEmpty($volume.FileSystemLabell)){
            $Label = "N/A"
        }
        [PSChiaPlotter.ChiaVolume]::new($volume.DriveLetter,$Label,$volume.Size,$volume.SizeRemaining)
    }
}