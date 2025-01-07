<#
.SYNOPSIS
Updates the graphical user interface (GUI) for managing the HDToolbox tool.

.DESCRIPTION
This script Updates a user-friendly GUI for interacting with the HDToolbox tool. The interface allows helpdesk teams to select configurations, browse log files, and execute associated PowerShell scripts without needing to use the command line.  

Users can also view outputs and save processed results directly from the GUI.  

.PARAMETER UiForm
The base Window object to update

.PARAMETER Configs
The All Config Object

.PARAMETER SelectedConfig
The Selected Config Object


.EXAMPLE
Update-HdtUi -SelectedConfig $SelectedConfig

.NOTES
Version: 1.0  
Author:JPS
Created: 12/22/2024 

This script uses Windows Presentation Foundation (WPF) or Windows Forms for building the GUI.

.LINK
TBD
#>
Function Update-HdtUi {
[CmdletBinding()]
param (
	[Ref]
	$Form,

	[PSCustomObject[]] 
	$configs,

	[PSCustomObject]
	$SelectedConfig,

	[Switch] $Update
)
	$uiForm = $form.Value
	push-location -Path $SelectedConfig.ConfigDirectory
	
	#Update Dimentions
	if ($Null -ne $SelectedConfig.Height){
		$uiform.Height = $SelectedConfig.Height
	}
	if ($Null -ne $SelectedConfig.Width){
		$uiform.Width = $SelectedConfig.Width
	}
	
	#Update branding
	Write-verbose -Message "HDToolbox Customizing UI for $($selectedConfig.CompanyName)"
	$UiForm.Title = "$($SelectedConfig.CompanyName) HelpDesk Toolbox"
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
	If(-not ($Update.IsPresent)){
		$UiConfigSelector.SelectedIndex = $Configs.Name.IndexOf($selectedConfig.name)
		$UiConfigSelector.Add_SelectionChanged({
			$selection = $_.Source.SelectedItem 
			$selectedConfig = $configs.Where({$PSItem.Name -eq $selection})
			Update-HdtUi -SelectedConfig $selectedConfig -Form ([Ref]$UiForm) -configs $configs -Update
		})
	}

	#update Variables 
	$variableScript = Get-Item -path $selectedConfig.VariableScript
	Write-verbose -Message "HDToolbox running variable script: $($variableScript.FullName)"
	$variablesGrid = $uiform.FindName("Variables") 
	[PSCustomObject[]]$AvailableVariables = Invoke-HdtVariableScript -ScriptPath $variableScript.FullName
	$variablesGrid.ItemsSource = $AvailableVariables

	# Update Script Nodes
	Write-verbose -Message "HDToolbox Removing old script Nodes"
	Remove-HdtUiScriptsNode -Form ([Ref]$UiForm) #Remove old script nodes

	$TemplateScriptExpander = $uiform.FindName("TemplateExpander")
	$GridRows = $uiform.FindName("GridRows")
	$xamlTemplate = [System.Windows.Markup.XamlWriter]::Save($TemplateScriptExpander)
	$parent = $TemplateScriptExpander.Parent
	$index = $GridRows.RowDefinitions.IndexOf($uiform.FindName("VariableGridRow")) 
	$index++ 
	Foreach ($node in $SelectedConfig.Nodes){
		Write-verbose -Message "HDToolbox Adding script Node: $($node.Name)"
		$scripts = Get-ChildItem -path $node.Scripts -Recurse -filter *.ps1
		If ($scripts.count -lt 1){
			Write-Warning -Message "Node ($($node.name)):No Scripts found in $($node.Scripts)"
			Continue
		}
		$NewRow = [System.Windows.Controls.RowDefinition]::new()
		$NewRow.Height = "Auto"
		$NewRow.Name = "$($node.Name)GridRow"
		$GridRows.RowDefinitions.Insert($index ,$NewRow)
		$nodeExpander = New-HdtUiScriptsNode -Node $node -XamlString $xamlTemplate
		[System.Windows.Controls.Grid]::SetRow($nodeExpander,$index)
		$Parent.Children.Insert($index, $NodeExpander)

		#Add Variables
		$variablesGrid = $uiform.FindName("Variables") 
		:script foreach($script in $nodeExpander.Content.Items){
			:parameter foreach ($param in $script.Parameters.Split(';')){
				if ($variablesGrid.items.VariableName -contains $param){
					Continue parameter
				}
				Write-verbose -Message "HDToolbox New Missing Parameter: $param"

				$variablesGrid.itemsSource += ([PSCustomObject]@{
					VariableName = $param
					Value = ''
					Source = $script.name
				})
			}
		}
		$index++ 
	}

	#logs
	Write-verbose -Message "HDToolbox adding Logs"
	$LogsExpanderGrid = $uiform.FindName("LogsExpander")
	$GridRows = $uiform.FindName("GridRows")
	$index = $GridRows.RowDefinitions.IndexOf($uiform.FindName("LogGridRow")) 
	[System.Windows.Controls.Grid]::SetRow($LogsExpanderGrid,$index)
	Update-HdtLogs -form ([ref]$uiform) -SelectedConfig $SelectedConfig

	#Update on timer
	if (-not ($Update.IsPresent)){
		Write-verbose -Message "HDToolbox Setting Refresh timer for logs"
		$Timer = New-Object System.Windows.Forms.Timer
		$Timer.Interval = 1000  # Timer interval in milliseconds (1000 ms = 1 second)
		$timer.tag = @{'form' = $form}
		$Null = $Timer.Add_Tick({
			param($sender, $e)
			# Update the label text with the current time
			Update-HdtLogs -form $sender.Tag['form'] -SelectedConfig $SelectedConfig -Update
		})
		$timer.Add_Tick({
			param($sender, $e)
			:RunspaceMonitoring foreach ($script in $Script:syncHash["ScriptResults"].Keys){
				wait-debugger
				$Details = $Script:syncHash["ScriptResults"][$script]
                if ((-not $Details.resultasync.IsCompleted) ){
                    continue RunspaceMonitoring
                }
				$runspace = $details.Runspace
				$Grid = $sender.Tag['form'].value.FindName($Details.Script.Grid)
				
                $Details.output = $details.runspace.EndInvoke($details.resultAsync) -join '\n '
                $warnings = $runspace.Streams.Warning -join '\n '
                $Errors = $runspace.Streams.Error -join '\n '
                if ($Errors -or $runspace.HadErrors){
                    $details.State = "Error"
                    $Details.output += "$errors"
                }elseif ($Warnings){
                    $details.State = "Warning"
                }else{
                    $details.state = 'Complete'
                }

				$scriptName = $details.Script.Name
				$grid.ItemsSource.Where({$PSItem -eq $scriptName}).Foreach({$PSItem.state = $details.State; $psitem.Output = $details.output})
				$Script:syncHash["ScriptResults"].Remove($script)
				
				$Grid.Items.Refresh() 
			}
		})
		$Timer.Start()
	}

	#Buttons
	$GatherLogsButton = $uiform.FindName("GatherLogs")
	$index = $GridRows.RowDefinitions.IndexOf($uiform.FindName("ButtonGridRow")) 
	[System.Windows.Controls.Grid]::SetRow($GatherLogsButton,$index)
	pop-location
}
