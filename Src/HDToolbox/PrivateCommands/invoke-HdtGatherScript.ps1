<#
.SYNOPSIS
Executes multiple PowerShell scripts in separate runspaces and combines the results into an array of Files to collect.

.DESCRIPTION
The Invoke-HdtGatherScripts cmdlet runs multiple PowerShell scripts located at specified paths in isolated runspaces.
The results are combined into a single array of objects.

.PARAMETER ScriptPaths
Specifies an array of full paths to PowerShell script files to execute. The files must exist and be accessible.

.OUTPUTS
Array
A combined array containing objects returned from all scripts.

.EXAMPLE
Invoke-HdtGatherScripts -ScriptPaths @("C:\Scripts\Script1.ps1", "C:\Scripts\Script2.ps1")

Runs the specified scripts and returns the combined results as an array of objects.

.NOTES
Ensure all script files exist and have the necessary permissions before invoking this cmdlet.
#>

function Invoke-HdtGatherScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [io.FileInfo[]]$ScriptPaths
    )

    # Initialize a combined results array
    $FilesToGather = new-object -type collections.Arraylist

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
            $Null = $FilesToGather.add($output )
        } catch {
            Write-Warning "Error executing script '$($scriptPath.FullName)': $_"
        } finally {
            $runspace.Dispose()
        }
    }

    return $FilesToGather
}
