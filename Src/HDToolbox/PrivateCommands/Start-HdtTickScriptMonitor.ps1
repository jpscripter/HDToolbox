  <#
    .SYNOPSIS
    Monitors and processes the execution of scripts running in separate runspaces.

    .DESCRIPTION
    The `Start-HdtTickScriptMonitor` function monitors the status of scripts running in separate runspaces 
    and updates the associated UI elements with the script's output, state, warnings, and errors. 
    It processes each script's result asynchronously, updates the state and output in the grid, and handles completed scripts.

    .PARAMETER HdtForm
    An instance of the `HdtForm` object representing the parent form or UI context where the monitoring 
    and updates are displayed.

    .EXAMPLE
    $form = Get-HdtFormInstance
    Start-HdtTickScriptMonitor -HdtForm $form

    This example starts the script monitor for the provided form instance.

    .NOTES
    - The function uses a synchronization hash table (`$Script:syncHash`) to manage script results.
    - UI elements, such as grids, are updated dynamically based on the script's state and output.
    - Warnings and errors from the script's execution are captured and reflected in the UI.

    .INPUTS
    [HdtForm]
    The `HdtForm` object representing the application's form or UI context.

    .OUTPUTS
    None. Updates UI elements as a side effect.

    .COMPONENT
    This function is a part of the HDToolbox suite and is designed to work with scripts running asynchronously in runspaces.

    .FUNCTIONALITY
    - Monitors the completion state of scripts.
    - Updates the grid UI with script results.
    - Handles warnings, errors, and successful script outputs.
    - Removes completed scripts from the monitoring list.

    .LIMITATIONS
    - Assumes the presence of a global synchronization hash table `$Script:syncHash["ScriptResults"]` Created by Start.
    - Relies on the `HdtForm` object's structure and naming conventions for UI elements.

    .TAGS
    Scripts, Monitoring, Runspaces, HDToolbox

    #>
function Start-HdtTickScriptMonitor {
	[CmdletBinding()]
	param (
		[HdtForm]
		$HdtForm
	)
	$completedscripts = @{}
	:RunspaceMonitoring foreach ($script in $Script:syncHash["ScriptResults"].Keys){
		$Details = $Script:syncHash["ScriptResults"][$script]
		if ((-not $Details.resultasync.IsCompleted) ){
			continue RunspaceMonitoring
		}
		$runspace = $details.Runspace
		$Parent = $HdtForm.Form.FindName('TemplateExpander').Parent
		$gridExpander = $parent.Children.where({$psitem.name -eq ($details.Script.Grid + 'ScriptExpander')})
		$grid = $gridExpander.Content
		$warnings = $runspace.Streams.Warning -join '\n '
		$Errors = $runspace.Streams.Error -join '\n '
		if ($Errors -or $runspace.HadErrors){
			$details.State = [ScriptState]::Error
			$Details.output += "$errors"
		}elseif ($Warnings){
			$Details.output = $details.runspace.EndInvoke($details.resultAsync) -join '\n '
			$details.State = [ScriptState]::Warning
		}else{
			$Details.output = $details.runspace.EndInvoke($details.resultAsync) -join '\n '
			$details.state = [ScriptState]::Complete
		}

		$scriptName = $details.Script.Name
		$grid.ItemsSource.Where({$PSItem.name -eq $scriptName}).Foreach({$PSItem.state = $details.State; $psitem.Output = $details.output})
		$completedscripts.add($script,$details)
		$Grid.Items.Refresh() 
	}
	foreach($RemoveScript in $completedscripts.keys){
		$Script:syncHash["ScriptResults"].Remove($RemoveScript)
	}
}
