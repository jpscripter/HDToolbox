add-type -AssemblyName PresentationFramework
add-type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Windows.Forms
enum ScriptState {
    Complete = 0
    Running = 1
    Warning = 2
    Error = 3
}
class ScriptModel {
    [string]$Folder
    [string]$Name
    [string]$Output = ""
    [string]$Synopsis
    [string]$Parameters
    [string]$Grid
    [Nullable[ScriptState]]$State 
    [String]$Signature
    [String]$SignatureThumbPrint
    [string]$FullPath
}

class HdtForm {
    [object] $form
    [hashtable] $Configs = @{}
    [Object] $selectedConfig
}

class ConfigStatus {
    [Object] $ConfigDetails
    [Collections.ObjectModel.ObservableCollection[Object]]$Variables = (New-Object -type Collections.ObjectModel.ObservableCollection[Object])
    [Collections.ObjectModel.ObservableCollection[Object]]$Logs = (New-Object -type Collections.ObjectModel.ObservableCollection[Object])
    [hashtable]$Scripts = @{}
    [String[]]$ExpandedScriptsNodes
}

if (Test-Path -Path $PSScriptRoot\PrivateCommands\){
    $Commands = Get-ChildItem -Path $PSScriptRoot\PrivateCommands\*.ps1 -file -Recurse
    Foreach($PCMD in $Commands){
	    Write-Verbose -Message "Private Cmdlet File: $PCMD"  
	    . $PCMD
    }
}

if (Test-Path -Path $PSScriptRoot\Commands\){
    $Commands = Get-ChildItem -Path $PSScriptRoot\Commands\*.ps1 -file -Recurse
    Foreach($CMD in $Commands){
	    Write-Verbose -Message "Cmdlet File: $CMD"  
	    . $CMD
        
    }
    Export-ModuleMember -Function $Commands.BaseName 
}


# Create a runspace pool and a runspace
$Min = 1
$max = 10
$Script:runspacePool = [runspacefactory]::CreateRunspacePool($min, $Max)
$Script:runspacePool.Open()

$Script:syncHash = [hashtable]::Synchronized(@{
    ScriptResults = @{}
    ContinueMonitoring = $true
})

#endregion