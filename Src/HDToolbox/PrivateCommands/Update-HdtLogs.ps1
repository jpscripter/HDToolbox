<#
.SYNOPSIS
Updates the graphical user interface (GUI) for managing the HDToolbox tool.

.DESCRIPTION
This script Updates a user-friendly GUI for interacting with the HDToolbox tool. The interface allows helpdesk teams to select configurations, browse log files, and execute associated PowerShell scripts without needing to use the command line.  

Users can also view outputs and save processed results directly from the GUI.  

.PARAMETER UiForm
The base Window object to update

.PARAMETER SelectedConfig
The Selected Config Object

.EXAMPLE
Update-HdtLogs -form ([ref]$uiform) -SelectedConfig $SelectedConfig

.NOTES
Version: 1.0  
Author:JPS
Created: 12/22/2024 

This script uses Windows Presentation Foundation (WPF) or Windows Forms for building the GUI.

.LINK
TBD
#>
Function Update-HdtLogs {
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
	try{
		$LogLookback = [int]$SelectedConfig.LogLookback
	}catch{
		Write-warning -message "Can not convert LogLookback $($SelectedConfig.LogLookback) to int"
		$LogLookback = 24
	}
	[PSCustomobject[]]$VariableLogs = $uiform.FindName("Variables").ItemsSource.Where({$psitem.VariableName -Like "Log*"}).Value
	:LogFiles foreach($log in ($VariableLogs + $SelectedConfig.LogFiles)){
		if (-not (Test-Path -Path $log))
		{
			Write-Debug -Message "Config Log [$($log)] not found"
			Continue LogFiles
		}

		#skip If too old
		$logItem = Get-Item -Path $log
		if ($logItem.Attributes -contains "Directory"){
			[io.Fileinfo[]]$logChildItems = Get-ChildItem -Path $logItem.FullName -Filter *.log -Recurse -File
			$logChildItems = $logChildItems.Where({(get-date) -lt ($PSItem.LastWriteTime.AddHours($LogLookback))})
			$logfiles.AddRange($logChildItems)
		}else{
			If ((get-date) -lt ($logItem.LastWriteTime.AddHours($LogLookback))){
				Write-Debug -Message "Config Log [$($log)] too old"
				Continue LogFiles
			}
	
			$logFiles.Add($logItem.FullPath)
		}
	}

		
	#get Entries from logs
	try{
		$LogLookback = [int]$SelectedConfig.LogLookback
	}catch{
		Write-warning -message "Can not convert LogLookback $($SelectedConfig.LogLookback) to int"
		$LogLookback = -24
	}
	try{
		$LogTailLength = [int]$SelectedConfig.LogTailLength
	}catch{
		Write-warning -message "Can not convert LogTailLength $($SelectedConfig.LogTailLength) to int"
		$LogTailLength = 0
	}
	:LogFiles Foreach ($log in $SelectedConfig.EventLogs){
		#$EventLogEntries = Get-CimInstance 
	}

	$KeepScrolling = $LogsGrid.ItemsSource.Count -le ($LogsGrid.SelectedIndex + 2)
	foreach($log in $logFiles){
		$params = @{}
		if ($LogTailLength -ne 0){
			$params.add('Tail',$LogTailLength)
		}
		if ($update.IsPresent){
			$params.add('NewContentOnly',$true)
		}
		[pscustomObject[]]$entries = Get-Log -File $Log @params
		if (-not ($update.IsPresent)){
			$entries = $entries.Where({(get-date) -lt ($PSItem.DateTime.AddHours($LogLookback))})
		}
		if ($entries.count -gt 0){
			try{
				$entries.Foreach({$Script:logsEntries.Add($PSItem)})
			}catch{
				Write-Warning $PSitem
			}
		}
		#if last selected, keep scrolling
		If ($KeepScrolling -and ($Script:logsEntries.Count -gt 1)){
			$LogsGrid.SelectedIndex = $Script:logsEntries.Count - 1
			$LogsGrid.ScrollIntoView($Script:logsEntries[-1])
		}
	}

}
