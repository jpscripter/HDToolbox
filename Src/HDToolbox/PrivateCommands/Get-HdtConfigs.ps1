<#
.SYNOPSIS
Retrieves the specified configuration file for the HDToolbox tool.

.DESCRIPTION
This script locates and returns the content of a targeted configuration file. The configuration file defines the settings for specific operations, including associated log files and PowerShell scripts for troubleshooting.  

The script supports searching in default and custom directories and can validate the existence of the configuration file before proceeding.

.EXAMPLE
Get-HdtConfigs.ps1 
Retrieves the configuration 

.NOTES
Version: 1.0  
Author: JPS
Created: 1/4/2024

This script assumes that configuration files are stored in JSON or XML format.

.LINK
TBD
#>
Function Get-HdtConfigs {
	[CmdletBinding()]
	param (
		[Parameter()]
		[io.DirectoryInfo]
		$Source 
	)
	$Configs = New-Object Collections.Arraylist

	#If no config is passed in
	$configFiles = Get-ChildItem -Path "$($Source.FullName)\*" -Filter *.json -Recurse
	Foreach ($configFile in $configFiles){
		$configContent = Get-Content -Raw $configFile
		Write-Debug -Message "Reading $($ConfigFile.FullName)"
		Try{
			$configObject = ConvertFrom-Json -InputObject $configContent
			$null = Add-Member -inputObject $configObject -name ConfigDirectory -value $configFile.Directory -Type NoteProperty
			if ( -not [string]::IsNullOrWhiteSpace($configObject.VariableScript)){
				$null = $configs.Add($configObject)
				Write-Debug -Message "`t Adding $($configObject.Name)"
			}
		}
		catch {
			Write-Warning -Message "Failed to convert $($configFile.FullName)"
		}
	}

	$script:ConfigSettings = @{}

	Foreach($config in $Configs){
		$configSettingsTempObj = [PSCustomObject]@{
			Variables = New-Object -type Collections.ObjectModel.ObservableCollection[Object]
			Logs = New-Object -type Collections.ObjectModel.ObservableCollection[Object]
			Scripts = @{}
		}
		$script:ConfigSettings.Add($Config.Name, $configSettingsTempObj)
	}

	return $Configs
}