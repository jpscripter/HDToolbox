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
		$ScriptRoot = '.'
	)
	$Configs = New-Object Collections.Arraylist

	#If no config is passed in
	$configFiles = Get-ChildItem -Path "$($ScriptRoot.FullName)\*" -Filter *.json
	Foreach ($configFile in $configFiles){
		$configContent = Get-Content -Raw $configFile
		Write-Debug -Message "Reading $($ConfigFile.FullName)"
		Try{
			$configObject = ConvertFrom-Json -InputObject $configContent
			$null = $configs.Add($configObject)
			Write-Debug -Message "`t Adding $($configObject.Name)"
		}
		catch {
			Write-Warning -Message "Failed to convert $($configFile.FullName)"
		}
	}
	return $Configs
}