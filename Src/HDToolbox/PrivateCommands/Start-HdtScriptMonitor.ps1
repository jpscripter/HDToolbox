<#
.SYNOPSIS
Executes a PowerShell script in a separate runspace and returns the results as a hashtable.

.DESCRIPTION
The Invoke-HdtScript cmdlet runs a PowerShell script located at a specified path in an isolated runspace.
This approach allows for script execution without affecting the main session.
Results are captured and returned as a hashtable.


.EXAMPLE
Start-HdtScriptMonitor 

Runs the script located at the specified path and returns the results in a hashtable.

.NOTES
Ensure the script file exists and has the necessary permissions before invoking this cmdlet.
#>
function Start-HdtScriptMonitor 
{
    <#
    import-module .\logParsing\LogParsing.psd1 -force
    Import-module .\hdtoolbox\Src\HDToolbox\HDToolBox.psd1 -force
    invoke-HDToolbox -Config .\hdtoolbox\ExampleConfig\

    $m = get-module HDToolbox
    $script:syncHash = $m.Invoke({$script:syncHash })
    $syncHash  = $script:syncHash 

    $RunningScriptResults = $syncHash["ScriptResults"]
    $runningScript = $RunningScriptResults.Keys
    #>
    $script:syncHash['ContinueMonitoring'] = $True

    #region Runspace Setup
    $monitorScript = {
        param($syncHash)
        # this script will look at the runspace to determine results and pass those back to the main thread to update the ui

        while ($syncHash['ContinueMonitoring']) {
            $RunningScriptResults = $syncHash["ScriptResults"]
            :RunspaceRunning foreach($RunningScript in $RunningScriptResults.Keys)
            {
                $Details = $RunningScriptResults[$RunningScript]

                if ($Details.resultasync.IsCompleted){
                    continue runspaceRunning
                }
                $Details.output = $details.runspace.EndInvoke($details.resultAsync) -join '\n '
                $warnings = $runspace.Streams.Warning -join '\n '
                $Errors = $runspace.Streams.Error -join '\n '
                if ($Errors -or $runspace.HadErrors){
                    $details.State = "Error"
                    $Details.output += "$errors"
                }elseif ($Warnings){
                    $details.State = "Warning"
                }else{
                    $details.state = 'Complete'
                }
            }
            Start-Sleep -Seconds 1
        }
    }

    # Create a runspace and script block
    $Powershell = [powershell]::Create()
    $AddedCommand = $Powershell.AddScript($monitorScript).AddParameter($script:syncHash) 
    $Powershell.RunspacePool = $Script:runspacePool

    #run
    $AddedCommand.BeginInvoke()
    Write-Debug "Background script monitor started Executed"

}