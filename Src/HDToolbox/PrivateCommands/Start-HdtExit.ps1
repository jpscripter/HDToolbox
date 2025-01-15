<#
.SYNOPSIS
Displays a WPF dialog window with "About" information for the HDT application.

.DESCRIPTION
The Start-HdtExit.function creates and displays a simple WPF dialog using PowerShell.
The dialog contains a `TextBlock` element with information about the HDT application, 
such as its name, version, and copyright details. The window is centered on the screen 
and is non-resizable.

.EXAMPLE
Start-HdtAbout

This example shows how to invoke the Start-HdtExit.function to display the "About" dialog.

.NOTES
Author: JPS
Date: January 14, 2025
Version: 1.0
#>
function Start-HdtExit {
	[CmdletBinding()]
	param (
		[HdtForm]
		$HdtForm
	)

    # Create a WPF window
    $HdtForm.form.Close()
}
