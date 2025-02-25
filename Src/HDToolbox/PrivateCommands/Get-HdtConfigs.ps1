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
		$Source,

		[object] $HdtForm
	)
	$Configs = New-Object Collections.Arraylist

	#If no config is passed in
	$configFiles = Get-ChildItem -Path "$($Source.FullName)\*" -Filter *.json -Recurse
	Foreach ($configFile in $configFiles){
		$configContent = Get-Content -Raw $configFile
		Write-Debug -Message "Reading $($ConfigFile.FullName)"
		Try{
			$configObject = ConvertFrom-Json -InputObject $configContent
			$null = Add-Member -inputObject $configObject -name ConfigDirectory -value $configFile.Directory.Fullname -Type NoteProperty
			if ( -not [string]::IsNullOrWhiteSpace($configObject.VariableScript)){
				$null = $configs.Add($configObject)
				Write-Debug -Message "`t Found $($configObject.Name)"
			}
		}
		catch {
			Write-Warning -Message "Failed to convert $($configFile.FullName)"
		}
	}

	#add configs to Form Object for tracking and internal usage
	Foreach($config in $Configs){
		Write-Debug -Message "`t Adding config $($config.Name)"

		if ($null -eq $HdtForm.SelectedConfig){
			$HdtForm.SelectedConfig = $Config
		}
		$configSettingsTempObj = [ConfigStatus]::new($config)
		$HdtForm.Configs.Add($Config.Name, $configSettingsTempObj)
	}
}