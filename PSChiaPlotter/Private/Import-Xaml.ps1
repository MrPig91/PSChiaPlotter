function Import-Xaml {
    param(
        $PathToXAML
    )
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName System.Windows.Forms
    [xml]$xaml = Get-Content -Path $PathToXAML
    $manager = [System.Xml.XmlNamespaceManager]::new($xaml.NameTable)
    $manager.AddNamespace("x","http://schemas.microsoft.com/winfx/2006/xaml")
    $xamlReader = [System.Xml.XmlNodeReader]::new($xaml)
    [Windows.Markup.XamlReader]::Load($xamlReader)
}