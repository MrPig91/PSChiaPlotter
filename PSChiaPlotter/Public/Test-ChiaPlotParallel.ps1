function Test-ChiaPlotParallel {
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias("FilePath","FullName")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,
        [ValidateRange(1,256)]
        [int]$Threads =  1,
        [ALias("n")]
        [int]$Challenges = 30
    )

    Begin{
        $ChiaPath = (Get-Item -Path "$ENV:LOCALAPPDATA\Programs\Chia\resources\app.asar.unpacked\daemon").FullName
        if ($ENV:Path.Split(";") -notcontains $ChiaPath){
            $ENV:Path += ";$ChiaPath"
        }
        $SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $RunspacePool = [runspacefactory]::CreateRunspacePool(1,$Threads,$SessionState,$Host)
        $RunspacePool.ApartmentState = "STA"
        $RunspacePool.ThreadOptions = "ReuseThread"
        $RunspacePool.Open()
        $Jobs = New-Object System.Collections.Generic.List[Object]
        $TotalPlots = $Path.Count
    } #Begin

    Process{
        foreach ($plotpath in $Path){
            Write-Information "Adding runspace for $plot"
            $Parameters = @{
                PlotPath = $plotpath
                Challenges = $Challenges
                ChiaPath = $ChiaPath
            }
            $CheckPlotScript = [powershell]::Create().AddScript({
                Param (
                    $PlotPath,
                    $Challenges,
                    $ChiaPath
                )
                $Leaf = Split-Path -Path $PlotPath -Leaf
                $KSize = $Leaf -split "plot-k" -split "-" | Select-Object -First 1 -Skip 1
                $PlotId = ($Leaf -split "-" | select -Last 1).Split(".")[0]
                $PlotObject = [PSCustomObject]@{
                    PSTypeName = "PSChiaPlotter.PlotTest"
                    Path = $PlotPath
                    PlotsFound = 0
                    ProofsFound = 0
                    Challenges = $Challenges
                    Ratio = 0.0
                    PlotSize = 0.0
                    LoadTime = 0.0
                    KSize = $KSize
                    PlotId = $PlotId
                    Errors = New-Object System.Collections.Generic.List[string]
                }
                
                $Proofs = "Proofs ([0-9]*) / ([0-9]*), ([0-9.]*)"
                $ValidPlot = "Found 1 valid plots"
                $InvalidPlot = "1 invalid plots found"
                $LoadedPlot = "Loaded a total of ([0-9]) plots of size ([0-9.]*) TiB, in ([0-9.]*) seconds"
                $ErrorString = "ERROR"

                if (Test-Path -Path $PlotPath -PathType Leaf){
                    $Results = chia.exe plots check -n $Challenges -g $PlotPath 2>&1 | Select-String -SimpleMatch "Proofs","Error","Found","Loaded"
                    foreach ($line in $Results){
                        switch -Regex ($line){
                            $Proofs {
                                $PlotObject.ProofsFound = $Matches[1] -as [int]
                                $PlotObject.Ratio = $Matches[3] -as [double]
                                break;
                            }
                            $ValidPlot {
                                $PlotObject.Valid = $true
                            }
                            $InvalidPlot {
                                $PlotObject.Valid = $false
                            }
                            $LoadedPlot {
                                $PlotObject.PlotsFound = $Matches[1] -as [int]
                                $PlotObject.PlotSize = $Matches[2] -as [double]
                                $PlotObject.LoadTime = $Matches[3] -as [double]
                            }
                            $ErrorString {
                                $PlotObject.Errors.Add($line.ToString())
                            }
                        }
                    }
                    $PlotObject
                }
            }).AddParameters($Parameters)
            $CheckPlotScript.RunspacePool = $RunspacePool
            $Handle = $CheckPlotScript.BeginInvoke()
            $temp = [PSCustomObject]@{
                PowerShell = $CheckPlotScript
                Handle = $Handle
            }
            [void]$jobs.Add($temp)
        } #foreach 
    
        while ($jobs.handle.IsCompleted -contains $false){
            Write-Information "Returning objects and closing runspaces"
            $RemoveJobs = New-Object System.Collections.Generic.List[Object]
            $jobs | where {$_.handle.IsCompleted -eq $true} | foreach {
                $_.powershell.EndInvoke($_.handle)
                $_.PowerShell.Dispose()
                [void]$RemoveJobs.Add($_)
            }
            if ($RemoveJobs){
                foreach ($job in $RemoveJobs){
                    [void]$Jobs.Remove($job)
                }
            }
            $PercentComplete = [math]::Round(($TotalPlots - ($jobs | Measure-Object).Count) / $TotalPlots * 100,2)
            $ProgessParameters = @{
                Activity = "Running chia check on $TotalPlots plots"
                Status = "$($TotalPlots - ($jobs | Measure-Object).Count) / $TotalPlots Completed | $PercentComplete%" 
                PercentComplete = $PercentComplete
            }
            Write-Progress @ProgessParameters
        } #while
    } #process
    end{
        Write-Information "Closing Runspace Pool"
        $RunspacePool.close()
        $RunspacePool.Dispose()
    } #end
}