function Test-ChiaParameters {
    param(
        $NewJob
    )
    $ChiaParameters = $NewJob.InitialChiaParameters

    if ([string]::IsNullOrEmpty($NewJob.JobName)){
        return "Job Name cannot be null or empty"
    }
    if ($ChiaParameters.RAM -lt 100){
        return "RAM needs to be greater than 100"
    }
    if ($ChiaParameters.Threads -le 0){
        return "Threads needs to 1 or higher"
    }
    if ($ChiaParameters.Buckets -le 0){
        return "Buckets cannot be less than 1"
    }
    if ($NewJob.EnablePhaseOneLimitor){
        if ($NewJob.PhaseOneLimit -lt 1){
            return "Phase one limit cannot be less than 1... that doesn't make sense."
        }
    }
    if ($NewJob.BasicPlotting){
        if (-not[System.IO.Directory]::Exists($ChiaParameters.BasicTempDirectory)){
            return "Temp Directory `"$($ChiaParameters.BasicTempDirectory)`" does not exists"
        }
        if (-not[System.IO.Directory]::Exists($ChiaParameters.BasicFinalDirectory)){
            return "Final Directory `"$($ChiaParameters.BasicFinalDirectory)`" does not exists"
        }
        if ($ChiaParameters.EnableBasicSecondTempDirectory){
            if (-not[System.IO.Directory]::Exists($ChiaParameters.BasicSecondTempDirectory)){
                return "2nd Temp Directory `"$($ChiaParameters.BasicSecondTempDirectory)`" does not exists"
            }
        }
    }
    else{
        if ($NewJob.TempVolumes.Count -lt 1){
            return "No Temp drives have been added!"
        }
        foreach ($tempvol in $NewJob.TempVolumes){
            if (-not[System.IO.Directory]::Exists($tempvol.DirectoryPath)){
                return "Temp Directory `"$($tempvol.DirectoryPath)`" does not exists"
            }
            $ValidPath = $false
            foreach ($path in $tempvol.AccessPaths){
                if ($tempvol.DirectoryPath.StartsWith($path)){
                    $ValidPath = $true
                }
            } #foreach
            if (-not$ValidPath){
                return "Directory path '$($tempvol.DirectoryPath)' for Drive $($tempvol.DriveLetter) does not start with a valid access path, valid paths shown below.`n`n$($tempvol.AccessPaths | foreach {"$_`n"})"
            }
        }
        if ($NewJob.FinalVolumes.Count -lt 1){
            return "No Final Drives have been added!"
        }
        foreach ($finalvol in $NewJob.FinalVolumes){
            if (-not[System.IO.Directory]::Exists($finalvol.DirectoryPath)){
                return "Final Directory `"$($finalvol.DirectoryPath)`" does not exists"
            }
            $ValidPath = $false
            foreach ($path in $finalvol.AccessPaths){
                if ($finalvol.DirectoryPath.StartsWith($path)){
                    $ValidPath = $true
                }
            } #foreach
            if (-not$ValidPath){
                return "Directory path '$($finalvol.DirectoryPath)' for Drive $($finalvol.DriveLetter) does not start with a valid access path, valid paths shown below.`n`n$($finalvol.AccessPaths | foreach {"$_`n"})"
            }
        }
    } #else
    
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