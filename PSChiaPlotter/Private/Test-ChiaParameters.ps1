function Test-ChiaParameters {
    param(
        $NewJob
    )
    $ChiaParameters = $NewJob.InitialChiaParameters

    if ($ChiaParameters.RAM -lt 3390){
        return "RAM needs to be greater than 3390"
    }
    if ($ChiaParameters.Threads -le 0){
        return "Threads needs to 1 or higher"
    }
    if ($NewJob.TempVolumes.Count -lt 1){
        return "No Temp drives have been added!"
    }
    foreach ($tempvol in $NewJob.TempVolumes){
        if (-not[System.IO.Directory]::Exists($tempvol.DirectoryPath)){
            return "Temp Directory `"$($tempvol.DirectoryPath)`" does not exists"
        }
    }
    if ($NewJob.FinalVolumes.Count -lt 1){
        return "No Final Drives have been added!"
    }
    foreach ($finalvol in $NewJob.FinalVolumes){
        if (-not[System.IO.Directory]::Exists($finalvol.DirectoryPath)){
            return "Final Directory `"($($finalvol.DirectoryPath)`" does not exists"
        }
    }
    if (-not[System.IO.Directory]::Exists($ChiaParameters.LogDirectory)){
        return "Log Directory does not exists"
    }
    if ($NewJob.DelayInMinutes -gt 35791){
        return "Delay Time is greater than 35791 minutes, which is the max"
    }
    if ($NewJob.FirstDelay -gt 35791){
        return "First delay time is greater than 35791 minutes, which is the max"
    }
    return $true
}