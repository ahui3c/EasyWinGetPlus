$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$sourcePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'EasyWinGetPlus.ps1'
$source = Get-Content -LiteralPath $sourcePath -Raw
$match = [regex]::Match($source, '(?s)\[xml\]\$xaml = @''\r?\n(.*?)\r?\n''@')
if (-not $match.Success) { throw 'The application XAML block was not found.' }

[xml]$xaml = $match.Groups[1].Value
$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$tabs = $window.FindName('MainTabs')
if (-not $tabs -or $tabs.Items.Count -ne 5) { throw 'The main tab control did not load correctly.' }
$onlineUpdateButton = $window.FindName('OnlineUpdateButton')
if (-not $onlineUpdateButton) { throw 'The About popup online-update button did not load.' }
$openLogFolderButton = $window.FindName('OpenLogFolderButton')
if (-not $openLogFolderButton) { throw 'The Settings runtime-log button did not load.' }

$upgradeGrid = $window.FindName('UpgradeGrid')
$searchGrid = $window.FindName('SearchGrid')
$installedGrid = $window.FindName('InstalledGrid')
$importGrid = $window.FindName('ImportGrid')
foreach ($grid in @($upgradeGrid, $searchGrid, $installedGrid, $importGrid)) {
    if (-not $grid) { throw 'A package data grid did not load.' }
    foreach ($column in $grid.Columns) {
        if ($column -is [System.Windows.Controls.DataGridTextColumn] -and -not $column.IsReadOnly) {
            throw "Text column '$($column.Header)' in '$($grid.Name)' is still editable."
        }
    }
}

if ($upgradeGrid.Columns[0].IsReadOnly -or $upgradeGrid.Columns[5].IsReadOnly -or $importGrid.Columns[0].IsReadOnly) {
    throw 'A checkbox column was made read-only while disabling text editing.'
}

foreach ($headerColumn in @($upgradeGrid.Columns[0], $upgradeGrid.Columns[5], $installedGrid.Columns[0])) {
    $centerSetter = @($headerColumn.HeaderStyle.Setters | Where-Object {
        $_ -is [System.Windows.Setter] -and $_.Property -eq [System.Windows.Controls.Control]::HorizontalContentAlignmentProperty
    }) | Select-Object -First 1
    if (-not $centerSetter -or $centerSetter.Value -ne [System.Windows.HorizontalAlignment]::Center) {
        throw "The '$($headerColumn.Header)' column header is not horizontally centered."
    }
}

$tabs.SelectedIndex = 4
$settingsTab = $tabs.Items[4]
if ($settingsTab.Foreground.ToString() -ne '#FFE2E8F0') {
    throw "The settings page foreground is not the expected light color: $($settingsTab.Foreground)"
}

$window.Close()
'UI_XAML_SMOKE_OK'
