<#
.SYNOPSIS
A sample script that demonstrates parameters.

.DESCRIPTION
This script accepts several parameters and performs some operations.

.PARAMETER Folder
Specifies the name of a person.

#>
[CmdletBinding()]
param (
    $Folder
)

Write-Output "Exists"