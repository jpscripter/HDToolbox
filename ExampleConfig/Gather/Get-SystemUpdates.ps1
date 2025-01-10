<#
.SYNOPSIS
    Retrieves a list of installed Windows updates.

.DESCRIPTION
    This script queries installed updates using the Get-HotFix cmdlet and WMI (Win32_QuickFixEngineering class).
    The results include details such as the update description, KB number, installation date, and installed by.

.OUTPUTS
    A string containing the path to the output file with installed update details.

.EXAMPLE
    PS> Get-WindowsUpdates
    Retrieves a list of installed Windows updates and writes the details to a file.

.NOTES
    - Requires administrative privileges to access update details.
    - Outputs both HotFix and WMI-sourced data for comparison when IncludeAllDetails is specified.

#>

[CmdletBinding()]
param (
)

# Retrieve updates using Get-HotFix
$hotFixes = Get-HotFix 

# Define output file path
$filename = "InstalledWindowsUpdates_$env:Computername-$(Get-Date -Format 'yyyyMMddHHmmss').txt"
$outputFile = Join-Path -Path $env:Temp -ChildPath $filename

# Write updates to the file
$hotFixes | convertTo-Csv| Out-File -FilePath $outputFile -Encoding utf8

# Return the file path
return $outputFile
