<#
.SYNOPSIS
Retrieves the source code from a Git repository using default credentials and stores it in a temporary folder.

.DESCRIPTION
The `Get-HdtGitSource` cmdlet checks if the specified Git repository URL is accessible with default credentials. 
It creates a temporary folder in the user's temp directory, downloads the repository as a ZIP file, and extracts its contents to the temporary folder.

.PARAMETER SourceURL
The URL of the Git repository (e.g., GitHub) to retrieve. The URL must point to the ZIP file of the repository's branch or release.

.EXAMPLE
Get-HdtGitSource -SourceURL "https://github.com/username/repo/archive/refs/heads/main.zip"

This example retrieves the source code from the specified GitHub repository's main branch.

.EXAMPLE
Get-HdtGitSource -SourceURL "https://example.com/private-repo/branch.zip"

This example retrieves the source code from a private repository that requires default credentials for authentication.

.NOTES
Author: Jps
Date: 1/10/2025
Version: 1.0

#>

function Get-HdtGitSource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the URL to the Git repository ZIP file.")]
        [string]$SourceURL
    )

    # Check if the URL is accessible with default credentials
    try {
        $response = Invoke-WebRequest -Uri $SourceURL -UseDefaultCredentials -Method Head -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
           Write-verbose "Access to the repository is successful."
        } else {
            Write-Error "Unable to access the repository. Status Code: $($response.StatusCode)" -ErrorAction Stop
        }
    } catch {
        Write-Error "Access check failed: $PsItem" -ErrorAction Stop
    }

    # Create a temporary folder
    $segments = $SourceURL.trim('.zip').split('/')
    $RepoName = $segments[3..($segments.count-1)] -join '-'
    $tempFolder = [System.IO.Path]::Combine($env:TEMP, "$RepoName-$(Get-Date -Format 'yyyyMMddHHmmss')")
    New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null
    Write-verbose "Temporary folder created at: $tempFolder"

    # Clone the repository using Invoke-RestMethod
    try {
        Invoke-RestMethod -Uri $SourceURL -OutFile "$tempFolder\repo.zip" -UseDefaultCredentials
        Write-verbose "Repository downloaded to $tempFolder\repo.zip"

        # Unzip the downloaded file
        Expand-Archive -Path "$tempFolder\repo.zip" -DestinationPath $tempFolder -Force
        Remove-Item "$tempFolder\repo.zip" -Force
       Write-verbose "Repository extracted to: $tempFolder"
    } catch {
        Write-Error "Failed to clone the repository: $PsItem"
        Remove-Item -Recurse -Force $tempFolder
    }

    return $tempFolder
}
