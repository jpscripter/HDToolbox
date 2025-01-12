<#
.SYNOPSIS
Updates the graphical user interface (GUI) for managing the HDToolbox tool to include the branding in the selected config.

.DESCRIPTION
This script Updates a user-friendly GUI for interacting with the HDToolbox tool. It only updates the branding

Users can also view outputs and save processed results directly from the GUI.  

.PARAMETER HdtForm
The HDTForm Window object to update


.EXAMPLE
Update-HdtUiBranding -HdtForm $HdtForm

.NOTES
Version: 1.0  
Author:JPS
Created: 12/22/2024 

This script uses Windows Presentation Foundation (WPF) or Windows Forms for building the GUI.

.LINK
TBD
#>
Function Update-HdtUiBranding{
[CmdletBinding()]
param (
	[HdtForm]
	$HdtForm,

	[Switch] $Update
)
	push-location -Path $HdtForm.SelectedConfig.ConfigDirectory
	$selectedConfig = $HdtForm.SelectedConfig
	Write-verbose -Message "HDToolbox Customizing UI for $($selectedConfig.CompanyName)"
	
	#Update Dimentions
	if ($Null -ne $SelectedConfig.Height){
		$HdtForm.form.Height = $SelectedConfig.Height
	}
	if ($Null -ne $SelectedConfig.Width){
		$HdtForm.form.Width = $SelectedConfig.Width
	}
	
	#Update branding
	$HdtForm.form.Title = "$($SelectedConfig.CompanyName) HelpDesk Toolbox"
	$CompanyIcon = Get-Item -Path $SelectedConfig.IconPath
	$UiIcon = $HdtForm.form.FindName("CompanyIcon") 
	$UiIcon.Source = $CompanyIcon.FullName
	$HdtForm.form.Icon = $CompanyIcon.FullName
	$UiCompanyName = $HdtForm.form.FindName("CompanyName") 
	$UiCompanyName.Text = $SelectedConfig.CompanyName
	$UiCompanyName = $HdtForm.form.FindName("Banner") 
	$UiCompanyName.Background = $SelectedConfig.BannerColor

	pop-location
}
