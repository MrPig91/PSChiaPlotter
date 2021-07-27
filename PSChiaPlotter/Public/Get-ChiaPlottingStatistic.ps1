function Get-ChiaPlottingStatistic {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string[]]$Path = (Get-ChildItem -Path $env:USERPROFILE\.chia\mainnet\plotter\ | sort CreationTime -Descending).FullName
    )

    Process{
        foreach ($log in $path){
            if (Test-Path $log){
                $Content = Get-Content -Path $log
                $FirstLine = $Content | Select-Object -First 1
                if ($FirstLine -like "Multi-threaded pipelined*"){
                    #Madmax log file
                    foreach ($madmaxline in $Content){
                        switch -Wildcard ($madmaxline){
                            "Plot Name:*" {
                                $PlotID = $madmaxline.Split("-") | Select-Object -Last 1
                                $PlotSize = ($madmaxline.Split("-") | Select-Object -Skip 1 -First 1).TrimStart('k')
                            }
                            "*Threads:*" {$ThreadCount = $madmaxline -split ": " | Select-Object -Last 1}
                            "Phase 1*" {$Phase_1 = $madmaxline.Split(' ')[3]}
                            "Phase 2*" {$Phase_2 = $madmaxline.Split(' ')[3]}
                            "Phase 3*" {$Phase_3 = $madmaxline.Split(' ')[3]}
                            "Phase 4*" {$Phase_4 = $madmaxline.Split(' ')[3]}
                            "Total*" {$TotalTime = $madmaxline.Split(' ')[5]}
                            "Copy*" {$CopyTime = $madmaxline.Split(',')[1].Split(' ')[2]}
                            "Working Directory:*" {$TempDrive = ($madmaxline -split ":  " | Select-Object -Last 1).Trim().Split('\') | select -First 1}
                            "Working Directory 2:*" {$SecondTempDir = ($madmaxline -split ": " | Select-Object -Last 1).Split('\') | select -First 1}
                            "Final Directory:*" {$FinalDrive = ($madmaxline -split ": " | Select-Object -Last 1).Split('\') | select -First 1}
                            default {Write-Information "Could not match line: $line"}
                        }
                    } #foreach
                    $BufferSize = 0
                }
                else{
                    #OG log file
                    $ImportantLines = @("ID: ","Time for phase","Total time","Plot size","Buffer size","threads of stripe","Copy time","Copied final file from","Starting plotting progress into temporary dirs")
                    $ContentLines = $Content | Select-String -SimpleMatch $ImportantLines | ForEach-Object {$_.ToString()}
                    foreach ($line in $ContentLines){
                        switch -Wildcard ($line){
                            "ID: *" {$PlotID = $line.Split(' ') | select -Skip 1 -First 1}
                            "Plot size*" {$PlotSize = $line.split(' ') | select -Skip 3} #using select for these since indexing will error if empty
                            "Buffer Size*" {$BufferSize = ($line.Split(' ') | select -Skip 3).split("M") | select -First 1}
                            "*threads*" {$ThreadCount = $line.split(' ') | select -First 1 -Skip 1}
                            "*phase 1*" {$Phase_1 = $line.Split(' ') | select -First 1 -Skip 5}
                            "*phase 2*" {$Phase_2 = $line.Split(' ') | select -First 1 -Skip 5}
                            "*phase 3*" {$Phase_3 = $line.Split(' ') | select -First 1 -Skip 5}
                            "*phase 4*" {$phase_4 = $line.Split(' ') | select -First 1 -Skip 5}
                            "Total time*" {$TotalTime = $line.Split(' ') | select -First 1 -Skip 3}
                            "Copy time*" {$CopyTime = $line.Split(' ') | select -First 1 -Skip 3}
                            "Starting plotting progress into temporary dirs*" {$TempDrive = ($line.Split(' ') | select -First 1 -Skip 6).Split('\') | select -First 1 }
                            "Copied final file from*" {$FinalDrive = ($line.Split(' ') | select -First 1 -Skip 6).Split('\').Replace('"', '') | select -First 1}
                            default {Write-Information "Could not match line: $line"}
                        }
                    } #foreach
                    $SecondTempDir = $null
                } #if/else

                [PSCustomObject]@{
                    PSTypeName = "PSChiaPlotter.ChiaPlottingStatistic"
                    PlotId = $PlotID
                    KSize = $PlotSize
                    "RAM(MiB)" = $BufferSize
                    Threads = $ThreadCount
                    "Phase_1_sec" = [int]$Phase_1
                    "Phase_2_sec" = [int]$Phase_2
                    "Phase_3_sec" = [int]$Phase_3
                    "Phase_4_sec" = [int]$phase_4
                    "TotalTime_sec" = [int]$TotalTime
                    "CopyTime_sec" = [int]$CopyTime
                    "PlotAndCopyTime_sec" = ([int]$CopyTime + [int]$TotalTime)
                    "Time_Started" = (Get-Item -Path $log).CreationTime 
                    "Temp_drive" = $TempDrive
                    "Final_drive" = $FinalDrive
                    "SecondTemp_Directory" = $SecondTempDir
                }
                Clear-Variable -Name "PlotID","PlotSize","BufferSize","ThreadCount","Phase_1","Phase_2","Phase_3","Phase_4","TotalTime","CopyTime","FinalDrive","TempDrive","FirstLine","SecondTempDir" -ErrorAction SilentlyContinue
            }
        }
    }
}