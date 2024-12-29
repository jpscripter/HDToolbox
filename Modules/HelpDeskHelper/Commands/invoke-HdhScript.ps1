<#
.SYNOPSIS
Executes a PowerShell script in a separate runspace and returns the results as a hashtable.

.DESCRIPTION
The Invoke-HdhScript cmdlet runs a PowerShell script located at a specified path in an isolated runspace.
This approach allows for script execution without affecting the main session.
Results are captured and returned as a hashtable.

.PARAMETER Script
Specifies the Script Object in the ui to to execute. The file must exist and be accessible.

.PARAMETER AvailableParameters
An array of the variables we can add to the script.

.OUTPUTS
Output Stream as a string

.EXAMPLE
Invoke-HdhScript -ScriptPath "C:\Scripts\MyScript.ps1"

Runs the script located at the specified path and returns the results in a hashtable.

.NOTES
Ensure the script file exists and has the necessary permissions before invoking this cmdlet.
#>
function Invoke-HdhScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $ScriptPath,
        [PSCustomObject[]]
        $AvailableParameters
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
