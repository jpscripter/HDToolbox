<#
.SYNOPSIS
Executes multiple PowerShell scripts in separate runspaces and combines the results into an array of objects.

.DESCRIPTION
The Invoke-HdtVariableScripts cmdlet runs multiple PowerShell scripts located at specified paths in isolated runspaces.
The results are combined into a single array of objects. Duplicate variable names are checked, and warnings are issued if conflicts occur.

.PARAMETER ScriptPaths
Specifies an array of full paths to PowerShell script files to execute. The files must exist and be accessible.

.OUTPUTS
Array
A combined array containing objects returned from all scripts.

.EXAMPLE
Invoke-HdtVariableScripts -ScriptPaths @("C:\Scripts\Script1.ps1", "C:\Scripts\Script2.ps1")

Runs the specified scripts and returns the combined results as an array of objects.

.NOTES
Ensure all script files exist and have the necessary permissions before invoking this cmdlet.
#>

function Invoke-HdtVariableScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [io.FileInfo[]]$ScriptPaths
    )

    # Initialize a combined results array
    $combinedResults = new-object -type collections.Arraylist

    foreach ($scriptPath in $ScriptPaths) {
        if (-not $scriptPath.Exists) {
            Write-Warning "The script path '$scriptPath' does not exist or is not a file."
            continue
        }

        # Create a runspace and script block
        $runspace = [powershell]::Create()
        $null = $runspace.AddScript([System.IO.File]::ReadAllText($scriptPath))

        try {
            # Open the runspace and invoke the script
            $output = $runspace.Invoke()

            # Process the script's output
            $output.foreach({
                if ($_ -is [hashtable]) {
                    foreach ($key in $_.Keys) {
                        # Check for duplicate variable names in the combined results
                        if ($combinedResults.where({ $PSItem.VariableName -eq $key })) {
                            Write-Warning "Duplicate variable name '$key' detected from script '$($scriptPath.FullName)'."
                        } else {
                            # Add the variable to the results array as an object
                            $Null = $combinedResults.add([PSCustomObject]@{
                                VariableName = $key
                                Value = $PSItem[$key]
                                Source = $scriptPath.BaseName
                            })
                        }
                    }
                }
            })
        } catch {
            Write-Warning "Error executing script '$($scriptPath.FullName)': $PSItem"
        } finally {
            $runspace.Dispose()
        }
    }

    return $combinedResults
}
