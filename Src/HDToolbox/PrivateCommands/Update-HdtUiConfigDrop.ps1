<#
.SYNOPSIS
Updates the graphical user interface (GUI) for managing the HDToolbox tool to allow for changing configs

.DESCRIPTION
This script Updates a user-friendly GUI for interacting with the HDToolbox tool. It only updates the Config Dropdown

Users can also view outputs and save processed results directly from the GUI.  

.PARAMETER HdtForm
The HDTForm Window object to update


.EXAMPLE
Update-HdtUiConfigDrop -HdtForm $HdtForm

.NOTES
Version: 1.0  
Author:JPS
Created: 12/22/2024 

This script uses Windows Presentation Foundation (WPF) or Windows Forms for building the GUI.

.LINK
TBD
#>
Function Update-HdtUiConfigDrop{
[CmdletBinding()]
param (
	[HdtForm]
	$HdtForm
)
	Write-verbose -Message "HDToolbox Customizing UI with configs ($($HdtForm.Configs.Keys -join ','))"
	
	#Update Configuration 
	$UiConfigSelector = $HdtForm.form.FindName('ConfigSelector')
	$UiConfigSelector.ItemsSource = $HdtForm.Configs.Values.ConfigDetails.name
	[string[]]$configNames = $HdtForm.Configs.Keys
	$UiConfigSelector.SelectedIndex = $configNames.IndexOf($hdtForm.selectedConfig.name)
	$UiConfigSelector.tag = @{'HdtForm'= $HdtForm}
	$UiConfigSelector.Add_SelectionChanged({
        param($sender, $e)
		wait-debugger
		$selection = $e.Source.SelectedItem 
		$sender.tag['HdtForm'].selectedConfig = $sender.tag['HdtForm'].configs[$selection.name]
		Update-HdtUi -HdtForm $HdtForm -Update
	})
}
