<#
.SYNOPSIS
Updates the graphical user interface (GUI) for managing the HDToolbox tool to allow for changing configs

.DESCRIPTION
This script Updates a user-friendly GUI for interacting with the HDToolbox tool. It only updates the Config Dropdown

Users can also view outputs and save processed results directly from the GUI.  

.PARAMETER HdtForm
The HDTForm Window object to update


.EXAMPLE
Update-HdtUiVariables -HdtForm $HdtForm

.NOTES
Version: 1.0  
Author:JPS
Created: 12/22/2024 

This script uses Windows Presentation Foundation (WPF) or Windows Forms for building the GUI.

.LINK
TBD
#>
Function Update-HdtUiVariables{
[CmdletBinding()]
param (
	[HdtForm]
	$HdtForm
)
	push-location -Path $HdtForm.SelectedConfig.ConfigDirectory
	Write-verbose -Message "HDToolbox Customizing UI with Variable"

	$variablesGrid = $HdtForm.form.FindName("Variables") 
	$SelectedConfig = $HdtForm.SelectedConfig
	if ($HdtForm.Configs[$selectedConfig.name].Variables.Count -lt 1){
		$variableScript = Get-ChildItem -path $selectedConfig.VariableScript
		Write-Debug -Message "HDToolbox running variable script: $($variableScript.FullName)"
		[PSCustomObject[]]$AvailableVariables = Invoke-HdtVariableScript -ScriptPath $variableScript
		Foreach($AvailableVariable in $AvailableVariables){
			$null = $HdtForm.Configs[$selectedConfig.name].Variables.Add($AvailableVariable)
		}
	}
	$variablesGrid.ItemsSource = $HdtForm.Configs[$selectedConfig.name].Variables

	#new variable menu
	$VariableNew = $variablesGrid.FindName('VariableNew')
	$VariableNew.Tag = @{'HdtForm' = $HdtForm}
	$VariableNew.Add_Click({
        param($sender, $e)
		Wait-Debugger

	})

	#Copy variable menu
	$VariableCopy = $variablesGrid.FindName('VariableCopy')
	$VariableNew.Tag = @{'HdtForm' = $HdtForm}
	$VariableCopy.Add_Click({
        param($sender, $e)
		Wait-Debugger

	})

	#Delete variable menu
	$VariableDelete = $variablesGrid.FindName('VariableDelete')
	$VariableNew.Tag = @{'HdtForm' = $HdtForm}
	$VariableDelete.Add_Click({
        param($sender, $e)
		Wait-Debugger
	})
	pop-location
}
