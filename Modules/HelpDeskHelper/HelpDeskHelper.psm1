add-type -AssemblyName PresentationFramework
add-type -AssemblyName PresentationCore

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

#region Runspace Setup
$monitorScript = {
    param($syncHash)

    while (-not $syncHash.StopMonitor) {
        # Simulate monitoring activity
        $syncHash.MonitorLog += "Monitor tick at $(Get-Date -Format 'HH:mm:ss')"
        Start-Sleep -Seconds 1
    }
    $syncHash.MonitorLog += "Monitoring stopped at $(Get-Date -Format 'HH:mm:ss')"
}

# Create a runspace pool and a runspace
    $Min = 1
    $max = 10
    $Script:runspacePool = [runspacefactory]::CreateRunspacePool($min, $Max)
    $Script:runspacePool.Open()

    $Script:syncHash = [hashtable]::Synchronized(@{
        RunningScripts = @{}
    })

    $monitorScript = {
        param($syncHash)
        Write-Verbose -Message "HelpDeskHelper Script Monitor"

        while (-not $syncHash.StopMonitor) {
            # Simulate monitoring activity
            $syncHash.MonitorLog += "Monitor tick at $(Get-Date -Format 'HH:mm:ss')"
            Start-Sleep -Seconds 1
        }
        $syncHash.MonitorLog += "Monitoring stopped at $(Get-Date -Format 'HH:mm:ss')"
    }

    # Set up the monitoring runspace
    $monitorRunspace = [powershell]::Create().AddScript($monitorScript).AddArgument($Script:syncHash)
    $monitorRunspace.RunspacePool = $Script:runspacePool


    # Start the monitoring runspace
    $monitorRunspace.BeginInvoke()
#endregion