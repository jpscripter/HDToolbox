<#
.SYNOPSIS
A sample script that demonstrates parameters.

.DESCRIPTION
This script accepts several parameters and performs some operations.

.PARAMETER TestParam
Specifies the name of a person.

#>
[CmdletBinding()]
param (
    $TestParam
)
Throw "Stopped"