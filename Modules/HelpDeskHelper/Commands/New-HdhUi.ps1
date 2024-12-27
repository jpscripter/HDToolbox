<#
.SYNOPSIS
Provides a graphical user interface (GUI) for managing the HelpdeskHelper tool.

.DESCRIPTION
This script creates a user-friendly GUI for interacting with the HelpdeskHelper tool. The interface allows helpdesk teams to select configurations, browse log files, and execute associated PowerShell scripts without needing to use the command line.  

Users can also view outputs and save processed results directly from the GUI.  

.PARAMETER XamlFile
The file location for the xaml template to use. This is read once and kept for the rest of the variable no longer exists. 

.EXAMPLE
Get-HdhConfigs.ps1 -XamlFile $Xaml

.NOTES
Version: 1.0  
Author:JPS
Created: 12/22/2024 

This script uses Windows Presentation Foundation (WPF) or Windows Forms for building the GUI.

.LINK
TBD
#>
Function New-HdhUi {
[CmdletBinding()]
param (
	[Parameter()]
	[io.DirectoryInfo]
	$ScriptRoot
)

	[io.FileInfo[]]$xamlFile = Get-ChildItem -Path $ScriptRoot.FullName -Filter *.xaml
	try{
		$selectedXaml = $xamlFile[0]
	}catch{
		Throw "No Xaml Files found in $($scriptRoot)"
	}
	#region Get UI Template
	$WindowXamlText = Get-Content -raw $XamlFile 
	$inputXML = $WindowXamlText -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
	[xml]$xamlTemplate = $inputXML
	$reader = (New-Object System.Xml.XmlNodeReader $xamlTemplate)
	$UiForm = [Windows.Markup.XamlReader]::Load( $reader )
	return $UiForm
}