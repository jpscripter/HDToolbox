<#
.SYNOPSIS
Removes all of the Script UI expanders

.DESCRIPTION
This cmdlet Reverts and removes UI expanders for a given node

.PARAMETER UIForm
The Form ref object 

.EXAMPLE
Remove-HdtUiScriptsNode -HdtForm $HdtForm

#>
function Remove-HdtUiScriptsNode {
    [CmdletBinding()]
    param (
        [HdtForm]
        $HdtForm   
    )

    #Find All Script Nodes
    $GridRows = $HdtForm.form.FindName("GridRows")
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
