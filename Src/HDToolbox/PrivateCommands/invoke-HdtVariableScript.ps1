<#
.SYNOPSIS
Executes a PowerShell script in a separate runspace and returns the results as a hashtable.

.DESCRIPTION
The Invoke-HdtVariableScript cmdlet runs a PowerShell script located at a specified path in an isolated runspace.
This approach allows for script execution without affecting the main session.
Results are captured and returned as a hashtable.

.PARAMETER ScriptPath
Specifies the full path to the PowerShell script file to execute. The file must exist and be accessible.

.OUTPUTS
Hashtable
A hashtable containing the script returned variables

.EXAMPLE
Invoke-HdtVariableScript -ScriptPath "C:\Scripts\MyScript.ps1"

Runs the script located at the specified path and returns the results in a hashtable.

.NOTES
Ensure the script file exists and has the necessary permissions before invoking this cmdlet.
#>
function Invoke-HdtVariableScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [io.FileInfo]$ScriptPath
    )

    if (-not $ScriptPath.Exists) {
        Throw "The script path '$ScriptPath' does not exist or is not a file."
    }

    # Create a runspace and script block
    $runspace = [powershell]::Create()
    $null = $runspace.AddScript([System.IO.File]::ReadAllText($ScriptPath))
   
    $result = New-Object collections.arraylist
    try {
        # Open the runspace and invoke the script
        $Output = $runspace.Invoke()

        # Capture output as a hashtable
        $Output.Foreach({
            if ($psitem.Keys.count -gt 0)
            {
                try{
                    $ScriptResult += $psitem
                }
                catch{
                    Write-Warning $psitem
                }
            }
        })

        foreach ($key in $ScriptResult.keys){
            $obj = [PSCustomObject]@{
                VariableName = $key 
                Value = $scriptResult[$key]
                Source = $ScriptPath.BaseName
            }
            $null = $result.add($obj)
        }

    } catch {
        Write-Warning $psitem
    } finally {
        $runspace.Dispose()
    }

    return $result
}
