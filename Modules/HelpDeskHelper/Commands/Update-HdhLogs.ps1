<#
.SYNOPSIS
Updates the graphical user interface (GUI) for managing the HelpdeskHelper tool.

.DESCRIPTION
This script Updates a user-friendly GUI for interacting with the HelpdeskHelper tool. The interface allows helpdesk teams to select configurations, browse log files, and execute associated PowerShell scripts without needing to use the command line.  

Users can also view outputs and save processed results directly from the GUI.  

.PARAMETER UiForm
The base Window object to update

.PARAMETER SelectedConfig
The Selected Config Object

.EXAMPLE
Update-HdhLogs -form ([ref]$uiform) -SelectedConfig $SelectedConfig

.NOTES
Version: 1.0  
Author:JPS
Created: 12/22/2024 

This script uses Windows Presentation Foundation (WPF) or Windows Forms for building the GUI.

.LINK
TBD
#>
Function Update-HdhLogs {
[CmdletBinding()]
param (
	[Ref]
	$Form,

	[PSCustomObject]
	$SelectedConfig,

	[switch]
	$update
)
	$uiForm = $form.Value

	#logs
	$LogsGrid = $uiform.FindName("Logs")
	$logFiles = New-Object -type Collections.Arraylist
	if (-not $update.IsPresent){
		$Script:logsEntries = New-Object -type Collections.ObjectModel.ObservableCollection[Object]
		$LogsGrid.ItemsSource = $Script:logsEntries 
	}

	#get list of logs in variables
	$LogLookback = [TimeSpan]$SelectedConfig.LogLookback
	[PSCustomobject[]]$VariableLogs = $uiform.FindName("Variables").ItemsSource.Where({$psitem.VariableName -Like "Log*"}).Value
	:LogFiles foreach($log in ($VariableLogs + $SelectedConfig.LogFiles)){
		if (-not (Test-Path -Path $log))
		{
			Write-warning -Message "Config Log [$($log)] not found"
			Continue LogFiles
		}

		#skip If too old
		$logItem = Get-Item -Path $log
		if ($logItem.Attributes -contains "Directory"){
			[io.Fileinfo[]]$logChildItems = Get-ChildItem -Path $logItem.FullName -Filter *.log -Recurse -File
			$logChildItems = $logChildItems.Where({(get-date) -lt ($PSItem.LastWriteTime.add($LogLookback))})
			$logfiles.AddRange($logChildItems)
		}else{
			If ((get-date) -lt ($logItem.LastWriteTime.add($LogLookback))){
				Write-Debug -Message "Config Log [$($log)] too old"
				Continue LogFiles
			}
	
			$logFiles.Add($logItem.FullPath)
		}
	}

		
	#get Entries from logs
	$LogLookback = [TimeSpan]$SelectedConfig.LogLookback
	:LogFiles Foreach ($log in $SelectedConfig.EventLogs){
		#$EventLogEntries = Get-CimInstance 
	}

	$KeepScrolling = $LogsGrid.ItemsSource.Count -le ($LogsGrid.SelectedIndex + 2)
	foreach($log in $logFiles){
		$params = @{}
		if ($update.IsPresent){
			$params.add('NewContentOnly',$true)
		}
		[pscustomObject[]]$entries = Get-Log -File $Log @params
		if (-not ($update.IsPresent)){
			$entries = $entries.Where({(get-date) -lt ($PSItem.DateTime.add($LogLookback))})
		}
		if ($entries.count -gt 0){
			try{
				$entries.Foreach({$Script:logsEntries.Add($PSItem)})
			}catch{
				Write-Warning $PSitem
			}
		}
		#if last selected, keep scrolling
		If ($KeepScrolling){
			$LogsGrid.SelectedIndex = $Script:logsEntries.Count -1
			$LogsGrid.ScrollIntoView($Script:logsEntries[-1])
		}
	}

}
