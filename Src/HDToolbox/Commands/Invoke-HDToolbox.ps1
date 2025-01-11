<#
.SYNOPSIS
HelpdeskHelper is a versatile tool for helpdesk teams to manage logs and automate tasks via configurable PowerShell scripts.

.DESCRIPTION
The HelpdeskHelper tool allows helpdesk teams to streamline their workflow by automating the handling of logs and PowerShell scripts. It supports multiple configurations, each tied to specific log files and scripts, enabling targeted and efficient troubleshooting.

.PARAMETER Config
Specifies the configuration to use. Each configuration is tied to a specific set of log files and PowerShell scripts.

.PARAMETER OutputPath
Optional. Specifies where to save processed log outputs. Defaults to the current directory if not specified.

.EXAMPLE
invoke-HDToolbox  -Config ".\Example" -OutputPath "C:\ProcessedLogs"
Processes the logs and runs the associated script for the "ErrorLogs" configuration. Outputs the result to the specified directory.

.NOTES
Version: 1.0  
Author: Jeff Scripter
Created: 1/4/2025

.LINK
TBD
#>

function  invoke-HDToolbox {
[CmdletBinding()]
param (
    [string]
    $ConfigSource = (get-location),

    [string]
    $InitialConfig,

    [io.DirectoryInfo]
    $OutputPath
)

    #region setup Config
    Write-Debug -Message "HDToolbox is using $ConfigSource"
    [io.directoryInfo]$ConfigSourceDirectory
    if ($ConfigSource.StartsWith('HTTP')){
        Write-Debug -Message "HDToolbox found a remote config. Downloading..."
        $scriptSource = Get-HdtGitSource -SourceURL $ConfigSource
        $ConfigSourceDirectory = get-Item -path $scriptSource 
    }else{
        $ConfigSourceDirectory = get-Item -path $ConfigSource 
    }

    Write-verbose -Message "HDToolbox Local Config location:  $($ConfigSourceDirectory.FullName)"
    $configsModulePath = "$($ConfigSourceDirectory.FullName)\Modules"
    if (-not ($env:PSModulePath.split(';') -contains $configsModulePath)){
        Write-Debug -Message "HDToolbox Local Config location:  $($ConfigSourceDirectory.FullName)"
        $env:PSModulePath += ";$configsModulePath"
    }
    #endregion

    #region Initial UI setup
    [object[]]$Configs = Get-hdtConfigs -Source $ConfigSourceDirectory
    try{
        Write-Debug -Message "HDToolbox found $($Configs.count) Configs"
        $selectedConfig = $Configs[0]
        Write-verbose -Message "HDToolbox starting with $($selectedConfig.Name) Config"
    }
    catch {
        Throw "No Config Found"
    }
    If (![String]::IsNullOrWhiteSpace($InitialConfig)){
        $selectedConfig = $Configs.Where({$psitem.name -eq $InitialConfig})
        if ($selectedConfig.count -eq 0) {
            Throw "Selected $Config not found in $($scriptRoot)"
        }
    }

    $UiForm = New-HdtUi -ScriptRoot $ScriptRoot 
    #endregion

    #region Config UI 
    Update-HdtUi -SelectedConfig $selectedConfig -Form ([Ref]$UiForm) -configs $configs
    #endregion
    $script:syncHash['ContinueMonitoring'] = $True
    $uiform.ShowDialog()
    $script:syncHash['ContinueMonitoring'] = $false

    if (-not [String]::IsNullOrEmpty( $scriptSource )){
        Remove-Item -Path  $scriptSource  -Recurse -force
    }
}