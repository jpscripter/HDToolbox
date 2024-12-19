

$Xaml = @"
<Window Title="MainWindow"  Width="800">
    <Grid>
        <Border Background="Gray" Height="50" VerticalAlignment="Top">
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Center">
                <Image Source="C:\Users\jpscr\Repos\HelpDeskHelper\th.jpg" Height="50" Margin="10,0" VerticalAlignment="Center"/>
                <TextBlock Text="My Company" FontSize="24" FontWeight="Bold" VerticalAlignment="Center" Foreground="White" Margin="10,0"/>
            </StackPanel>
        </Border>
        <StackPanel Margin="0,55,0,0">
            <Expander HorizontalAlignment="Stretch" Header="Variables&#xD;&#xA;" VerticalAlignment="Stretch" IsExpanded="True">
                <DataGrid d:ItemsSource="{d:SampleData ItemCount=5}" IsReadOnly="False"/>
            </Expander>
            <Expander HorizontalAlignment="Stretch" Header="Remediations&#xA;"  VerticalAlignment="Stretch"  IsExpanded="True">
                <DataGrid d:ItemsSource="{d:SampleData ItemCount=5}" IsReadOnly="True">
                    <DataGrid.ContextMenu>
                        <ContextMenu>
                            <MenuItem Header="Execute"/>
                        </ContextMenu>
                    </DataGrid.ContextMenu>
                </DataGrid>
            </Expander>
            <Expander HorizontalAlignment="Stretch" Header="Tests&#xA;" VerticalAlignment="Stretch" IsExpanded="True">
                <DataGrid d:ItemsSource="{d:SampleData ItemCount=5}" IsReadOnly="True">
                    <DataGrid.ContextMenu>
                        <ContextMenu>
                            <MenuItem Header="Execute"/>
                        </ContextMenu>
                    </DataGrid.ContextMenu>
                </DataGrid>
            </Expander>
            <Expander HorizontalAlignment="Stretch"  Header="Logs&#xA;" VerticalAlignment="Stretch" Height="200" IsExpanded="True">
                <DataGrid d:ItemsSource="{d:SampleData ItemCount=5}" IsReadOnly="True"/>
            </Expander>
        </StackPanel>
        <Button Name="StartGather" Margin="100,5" Height="30" Width="70" VerticalAlignment="Bottom" HorizontalAlignment="Right">Start Gather
        </Button>
        <Button Name="StopGather" Margin="5,5" Height="30" Width="70" VerticalAlignment="Bottom" HorizontalAlignment="Right">Stop Gather
        </Button>
    </Grid>
</Window>
"@