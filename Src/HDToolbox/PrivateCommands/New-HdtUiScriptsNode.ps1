<#
.SYNOPSIS
Adds a UI expander for a node and populates it with PowerShell script metadata.

.DESCRIPTION
This cmdlet creates a UI expander for a given node, populates it with metadata from PowerShell scripts found in the node's script directory, and returns the expander object. The metadata includes the script name, full path, synopsis, parameters, and folder name.

.PARAMETER Node
The node object containing script information, including the script path and node name.

.PARAMETER XamlString
The XAML template string used to create the expander UI element.

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

        [HashTable]$Columns = [Ordered]@{
            'Folder'= $Null
            'Name'= $Null
            'Output'= 300
            'Synopsis'= $Null
            'Parameters'= $Null
        }
    )

    # Retrieve scripts from the specified path
    $scripts = Get-ChildItem -Path $Node.Scripts -Recurse -Filter *.ps1
    if ($scripts.Count -lt 1) {
        Write-Warning -Message "Node ($($Node.Name)): No scripts found in $($Node.Scripts)"
        return $null
    }

    # Collect script metadata
    $scriptObjects = New-Object -TypeName Collections.ObjectModel.ObservableCollection[Object]
    $scriptRef = New-Variable -Name ($Node.Name + "ScriptList") -Value $scriptObjects -Scope script -force -PassThru
    foreach ($script in $scripts) {
        $help = Get-Help $script.FullName -Detailed
        $obj = [ScriptModel]@{
            Name       = $script.BaseName
            Synopsis   = $help.SYNOPSIS
            Parameters = $help.Parameters.Parameter.Name -join ';'
            Folder     = $script.Directory.Name
            FullPath   = $script.FullName

            Grid       = $Node.Name
        }
        $null = $scriptObjects.Add($obj)
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
    $TemplateExecute.Add_Click({
        $menuItem = $PSItem.OriginalSource
        $contextMenu = $menuItem.Parent
        $dataGrid = $contextMenu.PlacementTarget
        $SelectedScripts = $dataGrid.SelectedItems 
        $scriptRefsAll = Get-Variable -Name ($dataGrid.name + "ScriptList") -Scope script 
        $scriptRefsAll.value.Where({$PSItem -in $SelectedScripts}).Foreach({$PSItem.state = "Running"; $psitem.Output = ""})
        $dataGrid.Items.Refresh() 
        $variablesGrid = $uiform.FindName("Variables") 
        Invoke-HdtScript -SelectedScripts $SelectedScripts -AvailableParameters $variablesGrid.Items
        $dataGrid.UnselectAll()  
    })

    if (-not $NodeGrid) {
        Throw "Template grid not found in the expander."
    }

    $NodeGrid.ItemsSource = $scriptRef.value

    # add columns
    foreach ($column in $Columns.keys){
        $newColumn = new-Object -type System.Windows.Controls.DataGridTextColumn
        $newColumn.Header = $column
        $newColumn.Binding = [System.Windows.Data.Binding]::new($column)
        
        $NodeGrid.columns.add($newColumn)
    }
    return $NodeExpander
}
