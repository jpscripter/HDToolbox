<#
.SYNOPSIS
Registers a key-down event to trigger a custom search function when Control + F is pressed.

.DESCRIPTION
The `New-HdtContolFSearch` function registers an event handler for the `KeyDown` event of a specified `HdtForm` object. 
When the user presses `Control + F`, it triggers a custom search function (in this case, invoking the `Start-HdtContolFSearch` function). 
This is typically used to enable a search dialog or functionality within a custom form-based application.

.PARAMETER HdtForm
The `HdtForm` object representing the form or window on which the key-down event handler should be registered. 
The form must have an accessible `form` property that represents the UI component (such as a `Window`) for event handling.

.EXAMPLE
$form = Get-HdtFormInstance
New-HdtContolFSearch -HdtForm $form

This example registers the Control+F key press event on the form `$form` and triggers the search function when Control+F is pressed.

.NOTES
- This function does not directly execute any search action. It simply triggers a custom search handler (`Start-HdtContolFSearch`) when the key combination is pressed.
- The event handler checks for the `Control` and `F` keys, and if they are pressed together, it calls `Start-HdtContolFSearch`.

.INPUTS
[HdtForm]
The `HdtForm` object that is the target for registering the key-down event.

.OUTPUTS
None. This function registers an event handler for key-down events and invokes another function (if Control+F is pressed).

.FUNCTIONALITY
- Registers a key-down event for the Control+F key combination.
- Invokes `Start-HdtContolFSearch` when Control+F is pressed.

.TAGS
Event Handling, Search, HdtForm, KeyPress

#>

Function New-HdtContolFSearch{
[CmdletBinding()]
param (
	[HdtForm]
	$HdtForm
)
	# Filter Keys Dwn event
	$HdtForm.form.tag = @{'HdtForm' = $HdtForm}
	$HdtForm.form.Add_KeyDown({
		param($sender, $e)
		if ($e.Key -eq "F" -and [System.Windows.Input.Keyboard]::Modifiers -eq "Control") {
			Start-HdtContolFSearch -HdtForm $Sender.tag['HdtForm']
		}
	})

}
