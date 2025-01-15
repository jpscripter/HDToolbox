<#
.SYNOPSIS
Displays a WPF dialog window with "About" information for the HDT application.

.DESCRIPTION
The Start-HdtAbout function creates and displays a simple WPF dialog using PowerShell.
The dialog contains a `TextBlock` element with information about the HDT application, 
such as its name, version, and copyright details. The window is centered on the screen 
and is non-resizable.

.EXAMPLE
Start-HdtAbout

This example shows how to invoke the Start-HdtAbout function to display the "About" dialog.

.NOTES
Author: JPS
Date: January 14, 2025
Version: 1.0
#>
function Start-HdtAbout {
	[CmdletBinding()]
	param (
		[HdtForm]
		$HdtForm
	)

    # Create a WPF window
    $window = New-Object System.Windows.Window
    $window.Title = "About Helpdesk Toolbox"
	$window.SizeToContent = "WidthAndHeight"
    $window.WindowStartupLocation = "CenterScreen"
    $window.ResizeMode = "NoResize"

    # Create a Grid to organize content
    $grid = New-Object System.Windows.Controls.Grid

    # Create a TextBlock
    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = @"
Config: 
	Company: $($HdtForm.SelectedConfig.CompanyName)
	Author: $($HdtForm.SelectedConfig.Author)
	Version: $($HdtForm.SelectedConfig.Version)
	Description: $($HdtForm.SelectedConfig.Description)

HelpDesk Tooldbox Application v1.0
Special thanks to Paul Wetter for his great Ideas and feedback!
© 2025 Jeff Scripter. All rights reserved.
"@

    $textBlock.FontSize = 12
    $textBlock.Margin = 10

    # Add the TextBlock to the Grid
    $grid.Children.Add($textBlock)

    # Set the Grid as the content of the window
    $window.Content = $grid

    # Show the window
    $null = $window.ShowDialog() 
	$window.close()
	$window = $null
}
