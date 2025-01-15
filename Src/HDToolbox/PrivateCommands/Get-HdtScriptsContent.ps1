
<#
.SYNOPSIS
Retrieves the raw content of one or more specified script files.

.DESCRIPTION
The `Get-HdtScriptsContent` function reads the raw content of one or more script files specified by the user and returns a hashtable. 
The keys in the hashtable are the full paths of the scripts, and the values are the corresponding file contents. This is to cache the script content in memory on launch to ensure
the scripts cant be changed between reading the signature and execution.

.PARAMETER Scripts
Specifies the script files to read. This parameter accepts one or more file paths as input. It is mandatory.

.INPUTS
System.IO.FileInfo[]
You can pipe file objects (e.g., from Get-ChildItem) to this function.

.OUTPUTS
System.Collections.Hashtable
The function outputs a hashtable where the keys are the full paths of the script files and the values are their raw contents.

.EXAMPLES

# Example 1
Get-HdtScriptsContent -Scripts (Get-Item "C:\Scripts\MyScript.ps1")
This command retrieves the content of the specified script file and returns it as a hashtable.

# Example 2
Get-ChildItem -Path "C:\Scripts" -Filter "*.ps1" | Get-HdtScriptsContent
This command retrieves all `.ps1` files in the specified directory and passes them to the function, returning a hashtable of file paths and their content.

# Example 3
$scripts = Get-ChildItem -Path "C:\MyScripts" -Filter "*.ps1"
Get-HdtScriptsContent -Scripts $scripts
This command stores all `.ps1` files in the specified folder in a variable and retrieves their content using the function.

.NOTES
Author: JPS
Date: 1/15/2025
Version: 1.0
This function uses the `Get-Content` cmdlet to read file contents in raw mode.

#>
function Get-HdtScriptsContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [io.FileInfo[]]$Scripts
    )
    $scriptContent = @{}
    foreach ($script in $scripts) {
        $content = Get-Content -Raw -Path $script.FullName
        $null = $scriptContent.Add($script.FullName, $content)
    }
    return $scriptContent
}
