function ConvertTo-FriendlyTimeSpan {
    [CmdletBinding()]
    param(
        [int32]$Seconds
    )

    $TimeSpan = New-TimeSpan -Seconds $Seconds
    switch ($TimeSpan){
        {$_.Days -ge 1} {return "$([math]::Round($TimeSpan.TotalDays,2)) days";break}
        {$_.Hours -ge 1} {return "$([math]::Round($TimeSpan.TotalHours,2)) hrs";break}
        {$_.Minutes -ge 1} {return "$([math]::Round($TimeSpan.TotalMinutes,2)) mins";break}
        {$_.seconds -ge 1} {return "$([math]::Round($TimeSpan.TotalSeconds,2)) sec";break}
    }
}