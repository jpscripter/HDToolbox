<#
.SYNOPSIS
Adds a UI expander for a node and populates it with PowerShell script metadata.

.DESCRIPTION
This cmdlet creates a UI expander for a given node, populates it with metadata from PowerShell scripts found in the node's script directory, and returns the expander object. The metadata includes the script name, full path, synopsis, parameters, and folder name.

.PARAMETER UIForm
The node object containing script information, including the script path and node name.

.EXAMPLE
$expander = New-HdhUiScriptsNode -Node $node -XamlString $xamlString

.NOTES
Ensure the node object contains valid script paths and the XAML template is well-formed.
#>
function Remove-HdhUiScriptsNode {
    [CmdletBinding()]
    param (
        [Ref]
        $Form   
    )

    $UiForm = $form.Value

    #Find All Script Nodes
    $GridRows = $uiform.FindName("GridRows")
    $ScriptNodes = $GridRows.Children.Where({$PSitem.Name -like '*ScriptExpander'})
    :node foreach ($node in $ScriptNodes){
        $NodeName = $node.Header
        $Rows = $GridRows.RowDefinitions
        :Row Foreach ($Row in $Rows){
            If ($row.name -eq ($NodeName + "GridRow")){
                $GridRows.RowDefinitions.Remove($row)
                Break row
            }
        }
        $GridRows.Children.Remove($Node)
    }
   
}
