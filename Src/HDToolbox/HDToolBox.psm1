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
    [string]$SignatureStatus
    [String]$SignatureThumbPrint
    [string]$FullPath
}

class HdtForm {
    [object] $form
    [hashtable] $Configs = @{}
    [Object] $selectedConfig
    [hashtable] $scriptContent = @{}
}

class ConfigStatus {
    [Object] $ConfigDetails
    [Collections.ObjectModel.ObservableCollection[Object]]$Variables
    [Collections.ObjectModel.ObservableCollection[Object]]$Logs
    [System.Windows.Data.ListCollectionView]$LogsSource
    [hashtable]$Scripts
    [Collections.Generic.HashSet[String]]$logFiles

    # Constructor
    ConfigStatus($ConfigDetails) {
        # Initialize properties with default values
        $this.ConfigDetails = $ConfigDetails
        $this.Variables = [Collections.ObjectModel.ObservableCollection[Object]]::new()
        $this.Logs = [Collections.ObjectModel.ObservableCollection[Object]]::new()
        $this.LogsSource = [System.Windows.Data.CollectionViewSource]::GetDefaultView($this.Logs)
        $this.Scripts = @{}
        $this.logFiles = [Collections.Generic.HashSet[String]]::new()
    }
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