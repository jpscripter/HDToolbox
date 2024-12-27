<#
.SYNOPSIS
Runs a WPF Window on a new thread and blocks interaction until the dialog is closed.

.DESCRIPTION
This cmdlet creates a new thread, passes a WPF Window object (`System.Windows.Window`) to it, and calls the `ShowDialog()` method to display the window. 
The cmdlet waits for the window to close and returns control back to the main thread.

.PARAMETER UIForm
The WPF Window object to display in a new thread. This must be an instance of `System.Windows.Window`.

.EXAMPLE
# Example 1: Launch a simple WPF Window
Add-Type -AssemblyName PresentationFramework

# Create a new WPF Window
$uiForm = New-Object System.Windows.Window
$uiForm.Title = "Sample UI"
$uiForm.Width = 300
$uiForm.Height = 200

# Display the window on a new thread
Start-HdhUi -UIForm $uiForm

.NOTES
Author: Jps
Date: 12/22/2024
Version: 1.0
#>
function Start-HdhUi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ref]$Form # Pass a WPF Window object
    )
		$uiform = $form.value
		# Validate form
		if (-not $uiform) {
			Throw "A valid form object is required."
		}
	
		$runspacePool = [runspacefactory]::CreateRunspacePool(1, 1)
		$runspacePool.Open()
	
		$runspace = [powershell]::Create().AddScript({
			param ($uiform)
			$uiform.ShowDialog() | Out-Null
		}).AddArgument($uiform)
	
		$runspace.RunspacePool = $runspacePool
	
		try {
			$null = $runspace.BeginInvoke()
		} catch {
			Throw "Failed to execute the form in a new runspace: $_"
		} finally {
			$runspace.Dispose()
			$runspacePool.Close()
			$runspacePool.Dispose()
		}
	}