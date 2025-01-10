<#
.SYNOPSIS
Gathers specified files into a temporary folder, creates a ZIP archive, and copies the archive to a specified location.

.DESCRIPTION
The Start-HdtGather cmdlet accepts a list of file paths to gather, copies them into a temporary folder, compresses them into a ZIP archive, and saves the archive to the specified destination. The temporary folder is cleaned up after the operation.

.PARAMETER FilesToGather
An array of file paths to include in the ZIP archive.

.PARAMETER ZipFilePath
The destination path where the ZIP archive will be saved.

.EXAMPLE
Start-HdtGather -FilesToGather @("C:\Path\To\File1.txt", "C:\Path\To\File2.txt") -ZipFilePath "C:\Path\To\Output.zip"

Gathers the specified files into a ZIP archive and saves it to the given path.

.NOTES
Ensure the files exist and the destination path is accessible.
#>

function Start-HdtGather {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$FilesToGather,

        [Parameter(Mandatory = $true)]
        [string]$ZipFilePath
    )

    # Create a temporary folder
    $tempFolder = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tempFolder | Out-Null

    try {
        # Copy files to the temporary folder
        foreach ($file in $FilesToGather) {
            if (Test-Path $file) {
                Copy-Item -Path $file -Destination $tempFolder
            } else {
                Write-Warning "File not found: $file"
            }
        }

        # Create the ZIP file from the temporary folder
        $zipTempPath = [System.IO.Path]::Combine($tempFolder, "Archive.zip")
        Compress-Archive -Path (Get-ChildItem -Path $tempFolder -File).FullName -DestinationPath $zipTempPath -Force

        # Copy the ZIP file to the desired location
        Copy-Item -Path $zipTempPath -Destination $ZipFilePath -Force

        Write-Output "ZIP file created successfully: $ZipFilePath"
    } catch {
        Write-Error "An error occurred: $_"
    } finally {
        # Clean up the temporary folder
        Remove-Item -Path $tempFolder -Recurse -Force
    }
}
