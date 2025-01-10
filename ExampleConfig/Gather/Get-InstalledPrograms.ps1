<#
.SYNOPSIS
    Retrieves a list of installed programs from Add/Remove Programs (ARP).

.DESCRIPTION
    This script retrieves installed program information from both machine-wide 
    (HKLM) and user-specific (HKEY_USERS) registry locations. The results are 
    written to a text file, and the file path is returned.

.OUTPUTS
    A string containing the path to the output file with installed program details.

.EXAMPLE
    PS> Get-InstalledPrograms
    Retrieves installed programs (excluding system components) and writes them to a file.

.EXAMPLE
    PS> Get-InstalledPrograms 
    Retrieves all installed programs, including system components, and writes them to a file.

.NOTES
    Requires administrative privileges to access certain registry locations.

.LINK
    https://docs.microsoft.com/en-us/windows/win32/msi/standard-registry-keys
#>


[CmdletBinding()]
param (
)

# Registry paths for Add/Remove Programs
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

# Add HKEY_USERS paths
$userSIDs = Get-ChildItem -Path "HKU:\" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -notlike "*Classes" }
foreach ($userSID in $userSIDs) {
    $registryPaths += @(
        "HKU:\$($userSID.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    )
}

# Initialize an array for storing program data
$programs = @()

foreach ($path in $registryPaths) {
    if (Test-Path $path) {
        $subKeys = Get-ChildItem -Path $path -ErrorAction SilentlyContinue

        foreach ($subKey in $subKeys) {
            $program = Get-ItemProperty -Path $subKey.PSPath -ErrorAction SilentlyContinue

            $programs += [pscustomobject]@{
                Name         = $program.DisplayName
                Version      = $program.DisplayVersion
                Publisher    = $program.Publisher
                InstallDate  = $program.InstallDate
                UninstallCmd = $program.UninstallString
                RegistryPath = $subKey.PSPath
                SystemComponent = $program.SystemComponent
            }
        }
    }
}

# Define output file path
$filename = "InstalledPrograms_$env:Computername-$env:USERDOMAIN-$(Get-Date -Format 'yyyyMMddHHmmss').txt"
$outputFile = Join-Path -Path $env:Temp -ChildPath $filename

# Write program list to the file
$programs |ConvertTo-Csv | Out-File -FilePath $outputFile -Encoding utf8

# Return the file path
return $outputFile
