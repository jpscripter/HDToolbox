<#
.SYNOPSIS
Retrieves details about PowerShell scripts, including their name, synopsis, parameters, folder, and full path.

.DESCRIPTION
The `Get-HdtScriptsDetails` cmdlet takes one or more PowerShell script files as input and returns an observable collection of objects containing details about each script. 
The details include the script's name, synopsis, parameters, folder name, full path, and the grid node name.

.PARAMETER Scripts
An array of file paths representing the PowerShell script files to analyze. 
This parameter accepts objects of type `[io.FileInfo]`, which can be obtained using the `Get-ChildItem` cmdlet.

.OUTPUTS
[Collections.ObjectModel.ObservableCollection[Object]]
Returns an observable collection of objects, each containing the following properties:
- `Name`: The base name of the script file.
- `Synopsis`: The description or purpose of the script (retrieved from the help block in the script).
- `Parameters`: A semicolon-separated list of parameter names defined in the script.
- `Folder`: The name of the folder containing the script.
- `FullPath`: The full path to the script file.
- `Grid`: The name of the grid node (likely a system or contextual identifier).

.EXAMPLE
Get-HdtScriptsDetails -Scripts (Get-ChildItem -Path "C:\Scripts" -Filter "*.ps1")

This example retrieves details about all PowerShell scripts in the "C:\Scripts" directory.

.EXAMPLE
Get-HdtScriptsDetails -Scripts (Get-Item "C:\Scripts\MyScript.ps1")

This example retrieves details about a single script located at "C:\Scripts\MyScript.ps1".

.NOTES
- The function assumes that the `Get-Help` cmdlet can retrieve detailed help information for the scripts.
- The `Grid` property in the output is populated based on the value of `$Node.Name` in the environment.

.REMARKS
Ensure that the scripts being analyzed include properly formatted help comments to maximize the accuracy of the retrieved details.

#>


function Get-HdtScriptsDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [io.FileInfo[]]$Scripts

    )
    $scriptObjects = New-Object -TypeName Collections.ObjectModel.ObservableCollection[Object]
    foreach ($script in $scripts) {
        $Signature = Get-AuthenticodeSignature $script.FullName
        $help = Get-Help $script.FullName -Detailed

        $obj = [ScriptModel]@{
            Name       = $script.BaseName
            Synopsis   = $help.SYNOPSIS
            Parameters = $help.Parameters.Parameter.Name -join ';'
            Folder     = $script.Directory.Name
            FullPath   = $script.FullName
            Grid       = $Node.Name
            Signature  = $Signature.SignerCertificate.Subject 
            SignatureStatus = $Signature.status
        }
        if ($Signature.status -eq 'Valid'){

            $obj.SignatureThumbPrint  = $Signature.SignerCertificate.Thumbprint.ToString()
        }
        $null = $scriptObjects.Add($obj)
    }
    return $scriptObjects
}
