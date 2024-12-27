<#
.SYNOPSIS
Updates the graphical user interface (GUI) for managing the HelpdeskHelper tool.

.DESCRIPTION
This script Updates a user-friendly GUI for interacting with the HelpdeskHelper tool. The interface allows helpdesk teams to select configurations, browse log files, and execute associated PowerShell scripts without needing to use the command line.  

Users can also view outputs and save processed results directly from the GUI.  

.PARAMETER UiForm
The base Window object to update

.PARAMETER Configs
The All Config Object

.PARAMETER SelectedConfig
The Selected Config Object


.EXAMPLE
Update-HdhUi -SelectedConfig $SelectedConfig

.NOTES
Version: 1.0  
Author:JPS
Created: 12/22/2024 

This script uses Windows Presentation Foundation (WPF) or Windows Forms for building the GUI.

.LINK
TBD
#>
Function Update-HdhUi {
[CmdletBinding()]
param (
	[Ref]
	$Form,

	[PSCustomObject[]] 
	$configs,

	[PSCustomObject]
	$SelectedConfig
)
	$uiForm = $form.Value
	#Update Dimentions
	$uiform.Height = $SelectedConfig.Height
	$uiform.Width = $SelectedConfig.Height

	#Update branding
	$UiForm.Title = "HelpDeskHelper for $($SelectedConfig.CompanyName)"
	$CompanyIcon = Get-Item -Path $SelectedConfig.IconPath
	$UiIcon = $uiform.FindName("CompanyIcon") 
	$UiIcon.Source = $CompanyIcon.FullName
	$uiform.Icon = $CompanyIcon.FullName
	$UiCompanyName = $uiform.FindName("CompanyName") 
	$UiCompanyName.Text = $SelectedConfig.CompanyName
	$UiCompanyName = $uiform.FindName("Banner") 
	$UiCompanyName.Background = $SelectedConfig.BannerColor

	#Update Configuration 
	$UiConfigSelector = $UiForm.FindName('ConfigSelector')
	$UiConfigSelector.ItemsSource = [String[]]$configs.name
	$UiConfigSelector.SelectedIndex = $Configs.Name.IndexOf($selectedConfig.name)

	#update Variables 
	$variableScript = Get-Item -path $selectedConfig.VariableScript
	$variablesGrid = $uiform.FindName("Variables") 
	[PSCustomObject[]]$AvailableVariables = Invoke-HdhVariableScript -ScriptPath $variableScript.FullName
	$variablesGrid.ItemsSource = $AvailableVariables

	# Update Script Nodes
	$TemplateScriptExpander = $uiform.FindName("TemplateExpander")
	$xamlString = [System.Windows.Markup.XamlWriter]::Save($TemplateScriptExpander)
	$parent = $TemplateScriptExpander.Parent
	$Index = $Parent.Children.IndexOf($TemplateScriptExpander)
	Foreach ($node in $SelectedConfig.Nodes){
		$scripts = Get-ChildItem -path $node.Scripts -Recurse -filter *.ps1
		If ($scripts.count -lt 1){
			Write-Warning -Message "Node ($($node.name)):No Scripts found in $($node.Scripts)"
			Continue
		}
		$scriptObjects = New-Object -type collections.Arraylist
		foreach ($script In $scripts){
			$help = Get-Help $script.FullName -Detailed
			$obj = [PSCustomObject]@{
				Name = $script.BaseName
				FullPath = $script.FullName
				SYNOPSIS = $help.SYNOPSIS
				Parameters = $help.parameters.parameter.Name -join ';'
				Folder = $script.Directory.Name
				Output = ""
			}
			$Null = $scriptObjects.Add($obj)
		}

		# Deserialize to create a copy
		$reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader -ArgumentList $xamlString))
		$NodeExpander = [System.Windows.Markup.XamlReader]::Load($reader)
	
		# Find the parent container (e.g., a StackPanel, Grid, etc.)
		$NodeExpander.Name = $node.Name + "Expander"
		$NodeExpander.Uid = $node.Name + "Expander"
		$NodeExpander.Header = $node.Name
		$NodeExpander.Visibility = $node.Expanded
		$NodeGrid = $NodeExpander.FindName("Template")
		$NodeGrid.ItemsSource = $scriptObjects
		$Parent.Children.Insert($index, $NodeExpander)
	}

	return $UiForm
}
