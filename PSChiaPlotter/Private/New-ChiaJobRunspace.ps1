function New-ChiaJobRunspace{
    param(
        [Parameter(Mandatory)]
        $Job
    )
    [powershell]::Create().AddScript{
        Param (
            $Job
        )
        $ErrorActionPreference = "Stop"
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName System.Windows.Forms

        #Import required assemblies and private functions
        Get-childItem -Path $DataHash.PrivateFunctions -File -Recurse | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Classes -File | ForEach-Object {Import-Module $_.FullName}

        for ($queue = 1; $queue -le $Job.QueueCount; $queue++){
            try{
                $newQueue = [PSChiaPlotter.ChiaQueue]::new($queue,$job.InitialChiaParameters,$job)
                $newQueue.Status = "Waiting"
                $DataHash.MainViewModel.AllQueues.Add($newQueue)
                $Job.Queues.Add($newQueue)
            }
            catch{
                Write-PSChiaPlotterLog -LogType "ERROR" -ErrorObject $_
                Show-Messagebox -Text $_.Exception.Message -Title "Job $($Job.JobNumber) - Runspace"
            }
        }

        try{
            for ($queue = 0;$queue -lt $Job.QueueCount;$queue++){
                if ($queue -eq 0){
                    sleep -Seconds ($Job.FirstDelay * 60)
                    $Job.Queues[$queue].IsBlocked = $false
                    $Job.Status = "Running"
                }

                $QueueRunspace = New-ChiaQueueRunspace -Queue $Job.Queues[$queue] -Job $Job
                $QueueRunspace.Runspacepool = $ScriptsHash.Runspacepool
                [void]$QueueRunspace.BeginInvoke()
                $DataHash.Runspaces.Add($QueueRunspace)
                if (($queue + 1) -ne $Job.QueueCount){
                    #plus 10 seconds for a min delay for data syncing insurance
                    Start-Sleep -Seconds ($Job.DelayInMinutes * 60 + 5)
                }
            }
        }
        catch{
            Write-PSChiaPlotterLog -LogType "ERROR" -ErrorObject $_
            Show-Messagebox -Text $_.Exception.Message -Title "Job $($Job.JobNumber) - Runspace" | Out-Null
        }
    }.AddParameters($PSBoundParameters)
}