<#
.SYNOPSIS
    Retrieves detailed system information and specifications, including last boot time.

.DESCRIPTION
    This script gathers system information using built-in PowerShell cmdlets and
    utilities like `Get-CimInstance`, `Get-WmiObject`, and `systeminfo`. The
    results are written to a text file, and the file path is returned.

.OUTPUTS
    A string containing the path to the output file with system information.

.EXAMPLE
    PS> Get-SystemInfo
    Retrieves essential system specifications and writes them to a file.

.NOTES
    Requires administrative privileges for certain WMI/CIM queries.

.LINK
    https://docs.microsoft.com/en-us/powershell/scripting/overview
#>

    [CmdletBinding()]
    param (
    )

    # Collect system information
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $lastBootTime = $os.LastBootUpTime

    $systemInfo = @{
        "ComputerName"      = $env:COMPUTERNAME
        "UserName"          = $env:USERNAME
        "Domain"            = $env:USERDOMAIN
        "OSVersion"         = $os.Caption
        "OSArchitecture"    = $os.OSArchitecture
        "Processor"         = (Get-CimInstance -ClassName Win32_Processor).Name
        "Memory (GB)"       = "{0:N2}" -f ($os.TotalVisibleMemorySize / 1MB)
        "BIOSVersion"       = (Get-CimInstance -ClassName Win32_BIOS).SMBIOSBIOSVersion
        "BootDevice"        = $os.BootDevice
        "LastBootTime"      = $lastBootTime
    }

    # Define output file path
    $filename = "SystemInfo_$env:Computername-$env:USERDOMAIN-$(Get-Date -Format 'yyyyMMddHHmmss').txt"
    $outputFile = Join-Path -Path $env:Temp -ChildPath $filename

    # Write system info to the file
    $systemInfo.GetEnumerator() | ForEach-Object {
        "$($_.Key): $($_.Value)"
    } | Out-File -FilePath $outputFile -Encoding utf8

    # Return the file path
    return $outputFile
