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
    if ($ConfigSource.ToLower().StartsWith('http')){
        Write-Debug -Message "HDToolbox found a remote config. Downloading..."
        $scriptSource = Get-HdtGitSource -SourceURL $ConfigSource
        $ConfigSourceDirectory = get-Item -path $scriptSource 
    }else{
        $ConfigSourceDirectory = get-Item -path $ConfigSource 
    }

    #making sure config's module folder is in the ps module path
    Write-verbose -Message "HDToolbox Local Config location:  $($ConfigSourceDirectory.FullName)"
    $configsModulePath = "$($ConfigSourceDirectory.FullName)\Modules"
    if (-not ($env:PSModulePath.split(';') -contains $configsModulePath)){
        Write-Debug -Message "Adding to module path:  $($ConfigSourceDirectory.FullName)"
        $env:PSModulePath += ";$configsModulePath"
    }
    #endregion

    #region Initial UI setup
    $HdtForm = New-HdtUi

    #Load configs
    Get-hdtConfigs -Source $ConfigSourceDirectory -HdtForm $HdtForm
    Write-Verbose -Message "HDToolbox found $($HdtForm.Configs.keys.count) Configs"

    If (![String]::IsNullOrWhiteSpace($InitialConfig)){
        try{
            $HdtForm.selectedConfig = $HdtForm.Configs[$InitialConfig]
        }
        catch{
            Throw "Selected $Config not found in $($scriptRoot)"
        }
    }
    #endregion

    #region Config UI 
    Update-HdtUi -HdtForm $HdtForm 
    #endregion

    #Launch Dialog
    $script:syncHash['ContinueMonitoring'] = $True
    $HdtForm.form.ShowDialog()
    $HdtForm.form.Close()
    $HdtForm = $null
    [GC]::collect()
    $script:syncHash['ContinueMonitoring'] = $false

    if (-not [String]::IsNullOrEmpty( $scriptSource )){
        Remove-Item -Path  $scriptSource  -Recurse -force -ErrorAction SilentlyContinue
    }
}