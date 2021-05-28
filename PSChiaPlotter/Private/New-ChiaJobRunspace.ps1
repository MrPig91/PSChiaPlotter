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
        Get-childItem -Path $DataHash.PrivateFunctions -File | ForEach-Object {Import-Module $_.FullName}
        Get-childItem -Path $DataHash.Classes -File | ForEach-Object {Import-Module $_.FullName}

        for ($queue = 1; $queue -le $Job.QueueCount; $queue++){
            try{
                $newQueue = [PSChiaPlotter.ChiaQueue]::new($Job.JobNumber,$queue,$job.InitialChiaParameters)
                $newQueue.Status = "Waiting"
                $DataHash.MainViewModel.AllQueues.Add($newQueue)
                $Job.Queues.Add($newQueue)
            }
            catch{
                Show-Messagebox -Text $_.Exception.Message -Title "Job $($Job.JobNumber) - Runspace"
            }
        }

        try{
            for ($queue = 0;$queue -lt $Job.QueueCount;$queue++){
                if ($queue -eq 0){
                    sleep -Seconds $Job.FirstDelay
                    $Job.Status = "Running"
                }
                #$Job.Queues[$queue].StartTime = [DateTime]::Now
                $Job.Queues[$queue].Status = "Running"
                $QueueRunspace = New-ChiaQueueRunspace -Queue $Job.Queues[$queue] -Job $Job
                $QueueRunspace.Runspacepool = $ScriptsHash.Runspacepool
                $QueueRunspace.BeginInvoke()
                if (($queue + 1) -ne $Job.QueueCount){
                    #plus 10 seconds for a min delay for data syncing insurance
                    Start-Sleep -Seconds ($Job.DelayInMinutes * 60 + 10)
                }
            }
        }
        catch{
            Show-Messagebox -Text $_.Exception.Message -Title "Job $($Job.JobNumber) - Runspace" | Out-Null
        }
    }.AddParameters($PSBoundParameters)
}