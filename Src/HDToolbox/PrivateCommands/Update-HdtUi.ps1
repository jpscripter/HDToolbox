<#
.SYNOPSIS
Updates the graphical user interface (GUI) for managing the HDToolbox tool.

.DESCRIPTION
This script Updates a user-friendly GUI for interacting with the HDToolbox tool. The interface allows helpdesk teams to select configurations, browse log files, and execute associated PowerShell scripts without needing to use the command line.  

Users can also view outputs and save processed results directly from the GUI.  

.PARAMETER Form
The HDTForm Window object to update


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
	[HdtForm]
	$HdtForm,

	[Switch] $Update
)

	#Update Dimentions
	Update-HdtUiBranding -HdtForm $HdtForm

	#Update config
	if (-not ($update.IsPresent)){
		Write-Debug -Message "HDToolbox UI is updating configs"
		Update-HdtUiConfigDrop -HdtForm $HdtForm
	}

	#update Variables 
	Update-HdtUiVariables -HdtForm $HdtForm

	# Update Script Nodes
	Write-verbose -Message "HDToolbox Removing old script Nodes"
	Remove-HdtUiScriptsNode -HdtForm $HdtForm

	Write-verbose -Message "HDToolbox Adding Script Nodes"
	Update-HdtUiScriptsNode -HdtForm $HdtForm

	#logs
	Write-verbose -Message "HDToolbox adding Logs"
	$LogsExpanderGrid = $HdtForm.form.FindName("LogsExpander")
	$GridRows = $HdtForm.form.FindName("GridRows")
	$index = $GridRows.RowDefinitions.IndexOf($HdtForm.form.FindName("LogGridRow")) 
	[System.Windows.Controls.Grid]::SetRow($LogsExpanderGrid,$index)
	Update-HdtLogs -HdtForm $HdtForm

	#Update on timer
	if (-not ($Update.IsPresent)){
		Write-verbose -Message "HDToolbox Setting Refresh timer for logs"
		$Timer = New-Object System.Windows.Forms.Timer
		$Timer.Interval = 1000  # Timer interval in milliseconds (1000 ms = 1 second)
		$timer.tag = @{'HdtForm' = $HdtForm}
		$Null = $Timer.Add_Tick({
			param($sender, $e)
			# Update the label text with the current time
			Update-HdtLogs -HdtForm $sender.Tag['HdtForm'] -Update
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
				$Parent = $sender.Tag['HdtForm'].Form.FindName('TemplateExpander').Parent
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
	$GatherLogsButton = $HdtForm.form.FindName("GatherLogs")
	$index = $GridRows.RowDefinitions.IndexOf($HdtForm.form.FindName("ButtonGridRow")) 
	[System.Windows.Controls.Grid]::SetRow($GatherLogsButton,$index)
	$GatherLogsButton.tag = @{'HdtForm' = $HdtForm}
	$GatherLogsButton.Add_Click({
		param($sender, $e)

		$SelectedConfig = $sender.Tag['HdtForm'].selectedConfig
		$CurrentConfig = $sender.Tag['HdtForm'].Configs[ $sender.Tag['HdtForm'].SelectedConfig.Name]
		push-location -Path $SelectedConfig.ConfigDirectory

		#save location
		$saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
		$saveFileDialog.Filter = "ZIP Files (*.zip)|*.zip"
		$saveFileDialog.Title = "Select a location to save the ZIP file"
		$filename = "GatheredFiles_$env:Computername-$($selectedConfig.Name)-$(Get-Date -Format 'yyyyMMddHHmmss').zip"
		$saveFileDialog.FileName = $filename  # Default filename
		if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
			$zipFilePath = $saveFileDialog.FileName

			#using hashset to dedup quickly
			$FilesToGather = (new-object Collections.Generic.HashSet[String])
			
			#run scripts
			$GatherScripts = Get-ChildItem -path $selectedConfig.LogGatherScript
			Write-verbose -Message "HDToolbox running Gather scripts: $($GatherScripts.FullName)"
			$FilesToGatherFromGather = Invoke-HdtGatherScript -ScriptPath $GatherScripts
			$FilesToGatherFromGather.foreach({$null = $FilesToGather.add($Psitem)})
			
			#gather logs
			$FilesToGatherFromLogs =  $CurrentConfig.Logfiles
			$FilesToGatherFromLogs.foreach({$null = $FilesToGather.add($Psitem)})

			#gather State
			$ForStateTempFileName = "HDToolboxState_$env:Computername-$($selectedConfig.Name)-$(Get-Date -Format 'yyyyMMddHHmmss').json"
			$ForStateTempFile = "$env:temp\$ForStateTempFileName"
			$logGrid = $sender.Tag['HdtForm'].Form.FindName("Logs")
			$SelectedIndex = $logGrid.SelectedIndex
			$ImportantLogEntries = $logGrid.ItemsSource[($SelectedIndex-5)..($SelectedIndex+5)]
			$ForStateTempObject = [PSCustomObject]@{
				SelectedConfig = $sender.Tag['HdtForm'].selectedConfig
				Variables = $CurrentConfig.Variables
				Scripts = $CurrentConfig.scripts
				ImportantLogEntries = $ImportantLogEntries
			} 
			$ForStateTempJson = ConvertTo-Json -Depth 3 -InputObject $ForStateTempObject 
			out-file -FilePath $forStateTempFile -InputObject $ForStateTempJson
			$FilesToGather.add($ForStateTempFile)

			#ZipFile
			Start-HdtGather -FilesToGather $FilesToGather -ZipFilePath $zipFilePath
			Remove-Item -Path $ForStateTempFile
		} else {
			Write-Warning "No location selected."
		}
		#run scripts
		Pop-Location
	})
	pop-location
}
