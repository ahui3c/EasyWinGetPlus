$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path $PSScriptRoot -Parent
$pngPath = Join-Path $projectRoot 'assets\icons\EasyWinGetPlus.png'
$iconPath = Join-Path $projectRoot 'assets\icons\EasyWinGetPlus.ico'
$buildSource = Get-Content -LiteralPath (Join-Path $projectRoot 'build.ps1') -Raw
$installerSource = Get-Content -LiteralPath (Join-Path $projectRoot 'installer\EasyWinGetPlus.iss') -Raw
$applicationSource = Get-Content -LiteralPath (Join-Path $projectRoot 'EasyWinGetPlus.ps1') -Raw
$launcherSource = Get-Content -LiteralPath (Join-Path $projectRoot 'src\EasyWinGetPlus.Launcher.cs') -Raw

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
if ($applicationSource -notmatch 'ExtractAssociatedIcon\(\$executablePath\)') { throw 'The WPF host does not load the launcher icon.' }
if ($applicationSource -notmatch '\$script:Window\.Icon = Get-ApplicationIconImageSource') { throw 'The main WPF window does not use the application icon.' }
if ($applicationSource -notmatch "SetCurrentProcessExplicitAppUserModelID\('Ahui3c\.EasyWinGetPlus'\)") { throw 'The PowerShell UI process does not set the application taskbar identity.' }
if ($launcherSource -notmatch 'SetCurrentProcessExplicitAppUserModelID\(AppUserModelId\)') { throw 'The launcher does not set the application taskbar identity.' }
if ($installerSource -notmatch 'AppUserModelID: "\{#MyAppUserModelId\}"') { throw 'The installed shortcuts do not share the application taskbar identity.' }

$taskbarTypeSourceMatch = [regex]::Match(
    $applicationSource,
    "Add-Type -TypeDefinition @'(?<source>[\s\S]*?)'@"
)
if (-not $taskbarTypeSourceMatch.Success) { throw 'The taskbar identity interop source could not be extracted for runtime testing.' }
Add-Type -TypeDefinition $taskbarTypeSourceMatch.Groups['source'].Value
if (-not ('EasyWinGetPlus.TaskbarIdentity' -as [type])) { throw 'The taskbar identity interop type is not accessible to Windows PowerShell.' }
$taskbarIdentityResult = [EasyWinGetPlus.TaskbarIdentity]::SetCurrentProcessExplicitAppUserModelID('Ahui3c.EasyWinGetPlus')
if ($taskbarIdentityResult -ne 0) { throw ('Setting the taskbar identity failed with HRESULT 0x{0:X8}.' -f $taskbarIdentityResult) }

'ICON_ASSETS_SMOKE_OK'
