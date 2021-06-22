function Test-ChiaPlot {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [Alias("FilePath","FullName","Filter")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,
        [ALias("n")]
        [int]$Challenges = 30
    )

    Begin{
        $ChiaPath = (Get-Item -Path "$ENV:LOCALAPPDATA\chia-blockchain\app-*\resources\app.asar.unpacked\daemon").FullName
        if ($ENV:Path.Split(";") -notcontains $ChiaPath){
            $ENV:Path += ";$ChiaPath"
        }
        $Proofs = "Proofs ([0-9]*) / ([0-9]*), ([0-9.]*)"
        $Testing = "Testing plot"
        $ErrorString = "ERROR"
    }

    Process{
        foreach ($plotpath in $Path){
            chia.exe plots check -n $Challenges -g $plotpath 2>&1 | Select-String -SimpleMatch "Proofs","Error","Testing" | foreach {
                switch -Regex ($_){
                    $Proofs {
                        $PlotObject.ProofsFound = $Matches[1] -as [int]
                        $PlotObject.Ratio = $Matches[3] -as [double]
                        $PlotObject
                        break
                    }
                    $Testing {
                        $PlotPath = ($_ -split "Testing plot ")[1].split(' ')[0]
                        $Leaf = Split-Path -Path $PlotPath -Leaf
                        $KSize = $Leaf -split "plot-k" -split "-" | Select-Object -First 1 -Skip 1
                        $PlotId = ($Leaf -split "-" | select -Last 1).Split(".")[0]
                        $PlotObject = [PSCustomObject]@{
                            PSTypeName = "PSChiaPlotter.PlotTest"
                            Path = $PlotPath
                            ProofsFound = 0
                            Challenges = $Challenges
                            Ratio = 0.0
                            KSize = $KSize
                            PlotId = $PlotId
                            Errors = New-Object System.Collections.Generic.List[string]
                        }
                        break
                    }
                    $ErrorString {
                        $PlotObject.Errors.Add($_.ToString())
                        break
                    }
                } #switch
            } #foreach line
        } #foreach
    } #process
}