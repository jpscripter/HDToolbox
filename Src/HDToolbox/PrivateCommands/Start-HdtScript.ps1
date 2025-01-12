<#
.SYNOPSIS
Adds a UI expander for a node and populates it with PowerShell script metadata.

.DESCRIPTION
This cmdlet creates a UI expander for a given node, populates it with metadata from PowerShell scripts found in the node's script directory, and returns the expander object. The metadata includes the script name, full path, synopsis, parameters, and folder name.

.PARAMETER Node
The node object containing script information, including the script path and node name.

.PARAMETER XamlString
The XAML template string used to create the expander UI element.

.PARAMETER HdtForm
The HDTForm Window object to update

.OUTPUTS
A WPF expander object populated with script metadata.

.EXAMPLE
Start-HdtScript -Node $node -XamlString $xamlString

.NOTESHdtForm
Ensure the node object contains valid script paths and the XAML template is well-formed.
#>
function Start-HdtScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [HdtForm]$HdtForm
    )

        $menuItem = $PSItem.OriginalSource
        $contextMenu = $menuItem.Parent
        $dataGrid = $contextMenu.PlacementTarget
        $SelectedScripts = $dataGrid.SelectedItems 
        $selectedConfig = $HdtForm.selectedConfig
        $scriptRef = $HdtForm.Configs[$selectedConfig.name].scripts[$dataGrid.name]
        $scriptRef.value.Where({$PSItem -in $SelectedScripts}).Foreach({$PSItem.state = "Running"; $psitem.Output = ""})
        $dataGrid.Items.Refresh() 
        $variablesGrid = $HdtForm.Form.FindName("Variables") 
        Invoke-HdtScript -SelectedScripts $SelectedScripts -AvailableParameters $variablesGrid.Items
        $dataGrid.UnselectAll()  
    
}
