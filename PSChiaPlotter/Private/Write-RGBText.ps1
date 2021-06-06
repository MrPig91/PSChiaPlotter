function Write-RGBText {
    [CmdletBinding()]
    param(
        [string]$Text,

        [Parameter(Position = 1)]
        [int]$fRed = 0,
        [int]$fGreen = 0,
        [int]$fBlue = 0,

        [int]$bRed = 0,
        [int]$bGreen = 0,
        [int]$bBlue = 0,
        
        # No newline after the text.
        [Parameter()]
        [switch] $NoNewLine,

        [switch]$UnderLine
    )

    $escape = [char]27 + '['
    $resetAttributes = "$($escape)0m"

    if ($UnderLine){
        $UL = "$($escape)4m"
    }
    
    $foreground = "$($escape)38;2;$($fRed);$($fGreen);$($fBlue)m"
    $background = "$($escape)48;2;$($bRed);$($bGreen);$($bBlue)m"
    
    Write-Host ($foreground + $background + $UL + $Text + $resetAttributes) -NoNewline:$NoNewLine
}