function Show-Messagebox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,
        [string]$Title = "Message Box",
        [System.Windows.MessageBoxButton]$Buttons =[System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]$Icon = [System.Windows.MessageBoxImage]::None
    )

    [System.Windows.MessageBox]::Show($Text,$Title,$Buttons,$Icon)
}