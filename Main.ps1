#region Setup
add-type -AssemblyName PresentationFramework
$ErrorActionPreference = 'Stop'
$ScriptRoot = $PSScriptRoot

#endregion

#region Make Xaml Object
$WindowXamlText = Get-Content -raw -Path "$ScriptRoot\App.xaml"
$inputXML = $WindowXamlText -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
[xml]$XAML = $inputXML
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$Form=[Windows.Markup.XamlReader]::Load( $reader )
#endregion

#get Fields
$xaml.SelectNodes("//*[@Name]").ForEach(
    {
        "trying item $($_.Name)"
        Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)

    })