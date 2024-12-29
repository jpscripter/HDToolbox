<#
.SYNOPSIS
HelpdeskHelper is a versatile tool for helpdesk teams to manage logs and automate tasks via configurable PowerShell scripts.

.DESCRIPTION
The HelpdeskHelper tool allows helpdesk teams to streamline their workflow by automating the handling of logs and PowerShell scripts. It supports multiple configurations, each tied to specific log files and scripts, enabling targeted and efficient troubleshooting.

.PARAMETER Config
Specifies the configuration to use. Each configuration is tied to a specific set of log files and PowerShell scripts.

.PARAMETER OutputPath
Optional. Specifies where to save processed log outputs. Defaults to the current directory if not specified.

.EXAMPLE
HelpdeskHelper -Config "ErrorLogs" -OutputPath "C:\ProcessedLogs"
Processes the logs and runs the associated script for the "ErrorLogs" configuration. Outputs the result to the specified directory.

.NOTES
Version: 1.0  
Author: Jeff Scripter
Created: 12/22/2024

.LINK
TBD
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Config,

    [Parameter()]
    [io.DirectoryInfo]
    $OutputPath
)

#region Setup
$ErrorActionPreference = 'Stop'
add-type -AssemblyName PresentationFramework
add-type -AssemblyName PresentationCore
[io.DirectoryInfo]$ScriptRoot = (get-location).path #$PSScriptRoot
$env:PSModulePath += ";$($ScriptRoot.FullName)\Modules"
Import-module HelpDeskHelper -force
#endregion

#region Initial UI setup
[object[]]$Configs = Get-hdhConfigs -ScriptRoot $ScriptRoot
try{
    $selectedConfig = $Configs[0]
}
catch {
    Throw "No Config Found"
}
If (![String]::IsNullOrWhiteSpace($config)){
    $selectedConfig = $Configs.Where({$psitem.name -eq $config})
    if ($selectedConfig.count -eq 0) {
        Throw "Selected $Config not found in $($scriptRoot)"
    }
}

$UiForm = New-HdhUi -ScriptRoot $ScriptRoot 
#endregion

#region Config UI 
Update-HdhUi -SelectedConfig $selectedConfig -Form ([Ref]$UiForm) -configs $configs
#endregion

$uiform.ShowDialog()

#region Make Xaml Object
$WindowXamlText = Get-Content -raw -Path "$ScriptRoot\App.xaml"