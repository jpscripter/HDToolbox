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
	$GridRows = $uiform.FindName("GridRows")
	$xamlTemplate = [System.Windows.Markup.XamlWriter]::Save($TemplateScriptExpander)
	$parent = $TemplateScriptExpander.Parent
	$index = $GridRows.RowDefinitions.IndexOf($uiform.FindName("VariableGridRow")) 
	$index++ 
	Foreach ($node in $SelectedConfig.Nodes){
		$scripts = Get-ChildItem -path $node.Scripts -Recurse -filter *.ps1
		If ($scripts.count -lt 1){
			Write-Warning -Message "Node ($($node.name)):No Scripts found in $($node.Scripts)"
			Continue
		}
		$NewRow = [System.Windows.Controls.RowDefinition]::new()
		$NewRow.Height = "Auto"
		$NewRow.Name = "$($node.Name)GridRow"
		$GridRows.RowDefinitions.Insert($index ,$NewRow)
		$nodeExpander = New-HdhUiScriptsNode -Node $node -XamlString $xamlTemplate
		[System.Windows.Controls.Grid]::SetRow($nodeExpander,$index)
		$Parent.Children.Insert($index, $NodeExpander)
		$index++ 
	}

	#logs
	$LogsExpanderGrid = $uiform.FindName("LogsExpander")
	$index = $GridRows.RowDefinitions.IndexOf($uiform.FindName("LogGridRow")) 
	[System.Windows.Controls.Grid]::SetRow($LogsExpanderGrid,$index)

	$LogsGrid = $uiform.FindName("Logs")
	$logFiles = $SelectedConfig.LogFiles
	$logsEntries = Get-Log -File "C:\Windows\Logs\DISM\dism.log"
	$logs = $logsEntries[-100..-1]
	$LogsGrid.ItemsSource = $logs

	#Buttons
	$GatherLogsButton = $uiform.FindName("GatherLogs")
	$index = $GridRows.RowDefinitions.IndexOf($uiform.FindName("ButtonGridRow")) 
	[System.Windows.Controls.Grid]::SetRow($GatherLogsButton,$index)


	return $UiForm
}
