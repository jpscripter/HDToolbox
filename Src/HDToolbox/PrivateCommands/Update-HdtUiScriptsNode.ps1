<#
.SYNOPSIS
Updates the graphical user interface (GUI) for managing the HDToolbox tool to Include all scripts nodes in the config

.DESCRIPTION
This script Updates a user-friendly GUI for interacting with the HDToolbox tool. It adds new ones

Users can also view outputs and save processed results directly from the GUI.  

.PARAMETER HdtForm
The HDTForm Window object to update


.EXAMPLE
Update-HdtUiScriptsNode -HdtForm $HdtForm

.NOTES
Version: 1.0  
Author:JPS
Created: 12/22/2024 

This script uses Windows Presentation Foundation (WPF) or Windows Forms for building the GUI.

.LINK
TBD
#>
Function Update-HdtUiScriptsNode{
[CmdletBinding()]
param (
	[HdtForm]
	$HdtForm
)
	push-location -Path $HdtForm.SelectedConfig.ConfigDirectory
	$selectedConfig = $HdtForm.selectedConfig
	$Config = $HdtForm.Configs[$selectedConfig.name]

	#get template
	$TemplateScriptExpander = $HdtForm.form.FindName("TemplateExpander")
	$GridRows = $HdtForm.form.FindName("GridRows")
	$xamlTemplate = [System.Windows.Markup.XamlWriter]::Save($TemplateScriptExpander)
	$parent = $TemplateScriptExpander.Parent
	$index = $GridRows.RowDefinitions.IndexOf($HdtForm.form.FindName("VariableGridRow")) 

	$index++ # This is used to add to the correct location in the xaml. It's weird but works.
	#add each new node
	Foreach ($node in $SelectedConfig.Nodes){
		#Set scriptdetails in UIObject
		if ($Config.scripts.Keys -contains $node.Name){
			Write-verbose -Message "HDToolbox Reloading script Node: $($node.Name)"
		}else{
			Write-verbose -Message "HDToolbox Adding script Node: $($node.Name)"
			$scripts = Get-ChildItem -path $node.Scripts -Recurse -filter *.ps1
			If ($scripts.count -lt 1){
				Write-Warning -Message "Node ($($node.name)):No Scripts found in $($node.Scripts)"
				Continue
			}
			# Collect script metadata
			[Collections.ObjectModel.ObservableCollection[Object]]$scriptDetails = Get-HdtScriptsDetails -Scripts $scripts
			$null = $Config.scripts.Add($Node.name, $scriptDetails)
			[HashTable]$scriptContent += Get-HdtScriptsContent -Scripts $scripts
			foreach($ScriptPath in $scriptContent.Keys)
			{
				if($ScriptPath -NotIn $HdtForm.ScriptContent.keys){
					$null =$HdtForm.ScriptContent.Add($ScriptPath, $scriptContent[$ScriptPath])
				}
			}
		}

		#make Node
		$NewRow = [System.Windows.Controls.RowDefinition]::new()
		$NewRow.Height = "Auto"
		$NewRow.Name = "$($node.Name)GridRow"
		$GridRows.RowDefinitions.Insert($index, $NewRow)
		$nodeExpander = New-HdtUiScriptsNode -Node $node -XamlString $xamlTemplate -HdtForm $HdtForm
		[System.Windows.Controls.Grid]::SetRow($nodeExpander,$index)
		$Parent.Children.Insert($index, $NodeExpander)

		#Add Variables
		$variablesGrid = $HdtForm.form.FindName("Variables") 
		:script foreach($script in $nodeExpander.Content.Items){
			:parameter foreach ($param in $script.Parameters.Split(';')){
				if ($variablesGrid.items.VariableName -contains $param -or [string]::IsNullOrWhiteSpace($param)){
					Continue parameter
				}
				Write-verbose -Message "HDToolbox New Missing Parameter: $param"
				$AvailableVariableScript = ([PSCustomObject]@{
					VariableName = $param
					Value = ''
					Source = $script.name
				})
				$null = $HdtForm.Configs[$selectedConfig.name].Variables.Add($AvailableVariableScript)
			}
		}
		$index++ 
	}
	pop-location
}
