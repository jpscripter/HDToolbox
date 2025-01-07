<#
.SYNOPSIS
Executes a PowerShell script in a separate runspace and returns the results as a hashtable.

.DESCRIPTION
The Invoke-HdtScript cmdlet runs a PowerShell script located at a specified path in an isolated runspace.
This approach allows for script execution without affecting the main session.
Results are captured and returned as a hashtable.

.PARAMETER SelectedScripts
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
function Invoke-HdtScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]
        $SelectedScripts,
        [PSCustomObject[]]
        $AvailableParameters
    )

    :script foreach ($script in $SelectedScripts){
        if (-not (Test-Path $Script.FullPath)){
            Write-Warning "The script path '$($Script.FullPath)' does not exist or is not a file."
            Continue script
        }

        # Create a runspace and script block
        $runspace = [powershell]::Create()
        $AddedCommand = $runspace.AddScript([System.IO.File]::ReadAllText($Script.FullPath))
        $runspace.RunspacePool = $Script:runspacePool

        # add params to runspace
        :params foreach ($param in $script.Parameters.Split(';')){
            $MatchingParam = $AvailableParameters.where({$PSitem.VariableName -eq $param})
            if (($null -eq $matchingParam) -or [string]::IsNullOrWhiteSpace($matchingParam.value))
            {
                continue params
            }
            $AddedCommand.AddParameter($param, $MatchingParam.Value)
        }

        #run
        Write-Debug "'$($Script.FullPath)' Executed"
        $result = $AddedCommand.BeginInvoke()
        #add to Hashset
        try{
            $Details= [PSCustomObject]@{
                Script = $script
                runspace = $runspace
                resultAsync = $result
                State = [ScriptState]::Running
                Output = ""
            }
            $script:syncHash["ScriptResults"].Add($runspace.InstanceId.guid, $Details)
        }
        catch{
            #wait-debugger
            Write-Error $PSitem -ErrorAction continue
        }
    }
}
