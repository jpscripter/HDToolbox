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
$expander = New-HdtUiScriptsNode -Node $node -XamlString $xamlString

.NOTES
Ensure the node object contains valid script paths and the XAML template is well-formed.
#>
function New-HdtUiScriptsNode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Node,

        [Parameter(Mandatory = $true)]
        [string]$XamlString,

        [Parameter(Mandatory = $true)]
        [HdtForm]$HdtForm,

        [HashTable]$Columns = [Ordered]@{
            'Folder'= $Null
            'Name'= $Null
            'Output'= 300
            'Synopsis'= $Null
            'Parameters'= $Null
            'Signature' = $null
            'SignatureThumbPrint' = $null
        }
    )
    # Retrieve scripts from the specified path
    if ($HdtForm.configs[$HdtForm.selectedConfig.Name].scripts[$node.name].Count -lt 1) {
        Write-Warning -Message "Node ($($Node.Name)): No scripts found in $($Node.Scripts)"
        return $null
    }

    # Deserialize the XAML template to create a new expander
    $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader -ArgumentList $XamlString))
    $NodeExpander = [System.Windows.Markup.XamlReader]::Load($reader)
    # Update properties of the expander
    $NodeExpander.Name = $Node.Name + "ScriptExpander"
    $NodeExpander.Uid = $Node.Name + "ScriptExpander"
    $NodeExpander.Header = $Node.Name
    $NodeExpander.Visibility = $Node.Expanded

    # UpdateGridName
    $NodeGrid = $NodeExpander.FindName("Template")
    $NodeGrid.Name = $Node.Name 


    # UpdateContextMenu Name
    $TemplateExecute = $NodeExpander.FindName("TemplateExecute")
    $TemplateExecute.Name = $Node.Name + "Execute"
    $TemplateExecute.tag = @{'HdtForm' = $HdtForm}
    $TemplateExecute.Add_Click({
        param($sender, $e)
        Wait-Debugger
        $menuItem = $PSItem.OriginalSource
        $contextMenu = $menuItem.Parent
        $dataGrid = $contextMenu.PlacementTarget
        $SelectedScripts = $dataGrid.SelectedItems 
        $selectedConfig = $Sender.tag['HdtForm'].selectedConfig
        $scriptRef = $Sender.tag['HdtForm'].Configs[$selectedConfig.name].scripts[$dataGrid.name]
        $scriptRef.value.Where({$PSItem -in $SelectedScripts}).Foreach({$PSItem.state = "Running"; $psitem.Output = ""})
        $dataGrid.Items.Refresh() 
        $variablesGrid = $Sender.tag['HdtForm'].Form.FindName("Variables") 
        Invoke-HdtScript -SelectedScripts $SelectedScripts -AvailableParameters $variablesGrid.Items
        $dataGrid.UnselectAll()  
    })

    if (-not $NodeGrid) {
        Throw "Template grid not found in the expander."
    }
    $NodeGrid.ItemsSource = $HdtForm.configs[$HdtForm.selectedConfig.Name].scripts[$node.name]
    # add columns
    foreach ($column in $Columns.keys){
        $newColumn = new-Object -type System.Windows.Controls.DataGridTextColumn
        $newColumn.Header = $column
        $newColumn.Binding = [System.Windows.Data.Binding]::new($column)
        
        $NodeGrid.columns.add($newColumn)
    }
    return $NodeExpander
}
