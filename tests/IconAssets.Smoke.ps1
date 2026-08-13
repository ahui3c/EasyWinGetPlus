$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path $PSScriptRoot -Parent
$pngPath = Join-Path $projectRoot 'assets\icons\EasyWinGetPlus.png'
$iconPath = Join-Path $projectRoot 'assets\icons\EasyWinGetPlus.ico'
$buildSource = Get-Content -LiteralPath (Join-Path $projectRoot 'build.ps1') -Raw
$installerSource = Get-Content -LiteralPath (Join-Path $projectRoot 'installer\EasyWinGetPlus.iss') -Raw

foreach ($path in @($pngPath, $iconPath)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing application icon asset: $path" }
    if ((Get-Item -LiteralPath $path).Length -lt 1024) { throw "Application icon asset is unexpectedly small: $path" }
}

$image = [System.Drawing.Bitmap]::new($pngPath)
try {
    if ($image.Width -ne 1024 -or $image.Height -ne 1024) { throw 'The master application icon is not 1024 x 1024.' }
    if ($image.GetPixel(0, 0).A -ne 0) { throw 'The master application icon does not have transparent corners.' }
} finally { $image.Dispose() }

$iconBytes = [IO.File]::ReadAllBytes($iconPath)
if ([BitConverter]::ToUInt16($iconBytes, 0) -ne 0 -or [BitConverter]::ToUInt16($iconBytes, 2) -ne 1) {
    throw 'The Windows icon header is invalid.'
}
$entryCount = [BitConverter]::ToUInt16($iconBytes, 4)
$iconSizes = for ($index = 0; $index -lt $entryCount; $index++) {
    $widthByte = $iconBytes[6 + ($index * 16)]
    if ($widthByte -eq 0) { 256 } else { [int]$widthByte }
}
foreach ($requiredSize in @(16,20,24,32,40,48,64,128,256)) {
    if ($iconSizes -notcontains $requiredSize) { throw "The Windows icon is missing the ${requiredSize}px representation." }
}

if ($buildSource -notmatch '/win32icon:\$iconPath') { throw 'The application build does not embed the custom icon.' }
if ($installerSource -notmatch 'SetupIconFile=.*EasyWinGetPlus\.ico') { throw 'The installer does not use the custom icon.' }

'ICON_ASSETS_SMOKE_OK'
