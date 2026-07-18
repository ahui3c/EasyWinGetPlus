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

$tabs.SelectedIndex = 4
$settingsTab = $tabs.Items[4]
if ($settingsTab.Foreground.ToString() -ne '#FFE2E8F0') {
    throw "The settings page foreground is not the expected light color: $($settingsTab.Foreground)"
}

$window.Close()
'UI_XAML_SMOKE_OK'
