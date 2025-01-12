    <#
    .SYNOPSIS
    Gathers specified files and creates a ZIP archive at the chosen location.

    .DESCRIPTION
    The `Start-HdtGather` cmdlet collects specified files, including scripts, logs, and configuration state, 
    and creates a ZIP archive at a user-selected location. It ensures no duplicate files are added to the archive 
    and removes any temporary files used during the process.

    .PARAMETER FilesToGather
    A collection of file paths to gather into the ZIP archive. Duplicate entries are automatically removed.

    .PARAMETER ZipFilePath
    The full file path where the ZIP archive will be created.

    .EXAMPLE
    Start-HdtGather -FilesToGather $files -ZipFilePath "C:\Logs\GatheredFiles.zip"

    This example gathers the files specified in `$files` and creates a ZIP archive at `C:\Logs\GatheredFiles.zip`.

    .NOTES
    - This cmdlet requires the `System.IO.Compression.FileSystem` assembly for ZIP file creation.
    - Temporary files created during the process are automatically removed after gathering.

    .INPUTS
    - [Collections.Generic.HashSet[String]]: A collection of unique file paths.
    - [String]: A string representing the path for the ZIP archive.

    .OUTPUTS
    None. This cmdlet creates a ZIP archive as a side effect.

    #>
function Start-HdtGather {
	[CmdletBinding()]
	param (
		[HdtForm]
		$HdtForm
	)

	$SelectedConfig = $HdtForm.selectedConfig
	$CurrentConfig = $HdtForm.Configs[ $HdtForm.SelectedConfig.Name]
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
		$logGrid = $HdtForm.Form.FindName("Logs")
		$SelectedIndex = $logGrid.ItemsSource.CurrentPosition
		$FilteredLogEntries = $logGrid.ItemsSource.Foreach({$PSItem})
		$ImportantLogEntries = $FilteredLogEntries[($SelectedIndex-5)..($SelectedIndex+5)]

		$ForStateTempObject = [PSCustomObject]@{
			SelectedConfig = $HdtForm.selectedConfig
			Variables = $CurrentConfig.Variables
			Scripts = $CurrentConfig.scripts
			ImportantLogEntries = $ImportantLogEntries
		} 
		$ForStateTempJson = ConvertTo-Json -Depth 3 -InputObject $ForStateTempObject 
		out-file -FilePath $forStateTempFile -InputObject $ForStateTempJson
		$FilesToGather.add($ForStateTempFile)

		#ZipFile
		Out-HdtGather -FilesToGather $FilesToGather -ZipFilePath $zipFilePath
		Remove-Item -Path $ForStateTempFile
	} else {
		Write-Warning "No location selected."
	}

	Pop-Location
}
