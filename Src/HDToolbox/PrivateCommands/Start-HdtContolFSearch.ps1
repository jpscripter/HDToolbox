
Function Start-HdtContolFSearch{
[CmdletBinding()]
param (
	[HdtForm]
	$HdtForm
)

    $selectedConfig = $HdtForm.selectedConfig
    $Config = $HdtForm.Configs[$selectedConfig.name]

    $XAML = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="Log Filter" Height="80" Width="400">
        <Grid Margin="10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="Auto" />
            </Grid.ColumnDefinitions>
            
            <!-- Dropdown List (ComboBox) -->
            <ComboBox x:Name="LogTypeComboBox" Grid.Column="0" Width="120" Margin="0,0,10,0">
                <ComboBoxItem>Message</ComboBoxItem>
                <ComboBoxItem>severity</ComboBoxItem>
                <ComboBoxItem>Source</ComboBoxItem>
                <ComboBoxItem>Component</ComboBoxItem>
            </ComboBox>
            
            <!-- Input Box (TextBox) -->
            <TextBox x:Name="FilterTextBox" Grid.Column="1" Height="25"  />

            <!-- OK Button -->
            <Button x:Name="OKButton" Content="OK" Grid.Column="2" Width="75" VerticalAlignment="Center" Margin="10,0,0,0" />
        </Grid>
    </Window>
"@

    # Load XAML
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$XAML)
    $Window = [Windows.Markup.XamlReader]::Load($reader)
    $LogTypeComboBox = $Window.FindName("LogTypeComboBox")
    $LogTypeComboBox.SelectedIndex = 0

    # add search
    $OKButton = $Window.FindName("OKButton")
    $okButton.tag = @{'HdtForm' = $HdtForm}
    $FilterDelegate = {
        param($sender, $e)
        $LogTypeComboBox = $Window.FindName("LogTypeComboBox")
        $filterProperty = $LogTypeComboBox.SelectedItem.Content
        $FilterTextBox = $Window.FindName("FilterTextBox")
        $Filtervalue = $FilterTextBox.text
        
        #addFilter
        $LogsGrid = $HdtForm.form.FindName("Logs")
        $LogsGrid.ItemsSource.Filter = {
            param ($item)
            $item.$filterProperty  -like "*$Filtervalue*"
        }
        $Null = $Window.Close()  # Close the window after clicking OK
    }
    $OKButton.Add_Click($FilterDelegate)

    # Show the window
    $null = $Window.ShowDialog()

}
