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
	push-location -Path $SelectedConfig.ConfigDirectory
	
	#Update Dimentions
	if ($Null -ne $SelectedConfig.Height){
		$form.Value.Height = $SelectedConfig.Height
	}
	if ($Null -ne $SelectedConfig.Width){
		$form.Value.Width = $SelectedConfig.Width
	}
	
	#Update branding
	Write-verbose -Message "HDToolbox Customizing UI for $($selectedConfig.CompanyName)"
	$form.Value.Title = "$($SelectedConfig.CompanyName) HelpDesk Toolbox"
	$CompanyIcon = Get-Item -Path $SelectedConfig.IconPath
	$UiIcon = $form.Value.FindName("CompanyIcon") 
	$UiIcon.Source = $CompanyIcon.FullName
	$form.Value.Icon = $CompanyIcon.FullName
	$UiCompanyName = $form.Value.FindName("CompanyName") 
	$UiCompanyName.Text = $SelectedConfig.CompanyName
	$UiCompanyName = $form.Value.FindName("Banner") 
	$UiCompanyName.Background = $SelectedConfig.BannerColor

	#Update Configuration 
	$UiConfigSelector = $form.Value.FindName('ConfigSelector')
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
	$variableScript = Get-ChildItem -path $selectedConfig.VariableScript
	Write-verbose -Message "HDToolbox running variable script: $($variableScript.FullName)"
	$variablesGrid = $form.Value.FindName("Variables") 
	[PSCustomObject[]]$AvailableVariables = Invoke-HdtVariableScript -ScriptPath $variableScript
	$variablesGrid.ItemsSource = $AvailableVariables

	# Update Script Nodes
	Write-verbose -Message "HDToolbox Removing old script Nodes"
	Remove-HdtUiScriptsNode -Form ([Ref]$form.Value) #Remove old script nodes

	$TemplateScriptExpander = $form.Value.FindName("TemplateExpander")
	$GridRows = $form.Value.FindName("GridRows")
	$xamlTemplate = [System.Windows.Markup.XamlWriter]::Save($TemplateScriptExpander)
	$parent = $TemplateScriptExpander.Parent
	$index = $GridRows.RowDefinitions.IndexOf($form.Value.FindName("VariableGridRow")) 
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
		$variablesGrid = $form.Value.FindName("Variables") 
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
	$LogsExpanderGrid = $form.Value.FindName("LogsExpander")
	$GridRows = $form.Value.FindName("GridRows")
	$index = $GridRows.RowDefinitions.IndexOf($form.Value.FindName("LogGridRow")) 
	[System.Windows.Controls.Grid]::SetRow($LogsExpanderGrid,$index)
	Update-HdtLogs -form $form -SelectedConfig $SelectedConfig

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
			$completedscripts = @{}
			:RunspaceMonitoring foreach ($script in $Script:syncHash["ScriptResults"].Keys){
				$Details = $Script:syncHash["ScriptResults"][$script]
                if ((-not $Details.resultasync.IsCompleted) ){
                    continue RunspaceMonitoring
                }
				$runspace = $details.Runspace
				$Parent = $sender.Tag['form'].value.FindName('TemplateExpander').Parent
				$gridExpander = $parent.Children.where({$psitem.name -eq ($details.Script.Grid + 'ScriptExpander')})
				$grid = $gridExpander.Content
                $warnings = $runspace.Streams.Warning -join '\n '
                $Errors = $runspace.Streams.Error -join '\n '
                if ($Errors -or $runspace.HadErrors){
                    $details.State = [ScriptState]::Error
                    $Details.output += "$errors"
                }elseif ($Warnings){
					$Details.output = $details.runspace.EndInvoke($details.resultAsync) -join '\n '
                    $details.State = [ScriptState]::Warning
                }else{
					$Details.output = $details.runspace.EndInvoke($details.resultAsync) -join '\n '
                    $details.state = [ScriptState]::Complete
                }

				$scriptName = $details.Script.Name
				$grid.ItemsSource.Where({$PSItem.name -eq $scriptName}).Foreach({$PSItem.state = $details.State; $psitem.Output = $details.output})
				$completedscripts.add($script,$details)
				$Grid.Items.Refresh() 
			}
			foreach($RemoveScript in $completedscripts.keys){
				$Script:syncHash["ScriptResults"].Remove($RemoveScript)
			}

		})
		$Timer.Start()
	}

	#Buttons
	$GatherLogsButton = $form.Value.FindName("GatherLogs")
	$index = $GridRows.RowDefinitions.IndexOf($form.Value.FindName("ButtonGridRow")) 
	[System.Windows.Controls.Grid]::SetRow($GatherLogsButton,$index)
	$GatherLogsButton.Add_Click({
		push-location -Path $SelectedConfig.ConfigDirectory
		#save location
		$saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
		$saveFileDialog.Filter = "ZIP Files (*.zip)|*.zip"
		$saveFileDialog.Title = "Select a location to save the ZIP file"
		$filename = "GatheredFiles_$env:Computername-$($selectedConfig.Name)-$(Get-Date -Format 'yyyyMMddHHmmss').txt"
		$saveFileDialog.FileName = $filename  # Default filename
		if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
			$zipFilePath = $saveFileDialog.FileName
			
			#run scripts
			$GatherScripts = Get-ChildItem -path $selectedConfig.LogGatherScript
			Write-verbose -Message "HDToolbox running Gather scripts: $($GatherScripts.FullName)"
			$FilesToGather = Invoke-HdtGatherScript -ScriptPath $GatherScripts

			#ZipFiles
			Start-HdtGather -FilesToGather $FilesToGather -ZipFilePath $zipFilePath

		} else {
			Write-Warning "No location selected."
		}
		#run scripts
		Pop-Location
	})
	pop-location
}
