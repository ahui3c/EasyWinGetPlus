$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$installer = Get-Content -LiteralPath (Join-Path $projectRoot 'installer\EasyWinGetPlus.iss') -Raw
$launcher = Get-Content -LiteralPath (Join-Path $projectRoot 'src\EasyWinGetPlus.Launcher.cs') -Raw
$script = Get-Content -LiteralPath (Join-Path $projectRoot 'EasyWinGetPlus.ps1') -Raw

foreach ($required in @(
    'DefaultDirName={autopf64}\Easy WinGet Plus',
    'PrivilegesRequired=admin',
    'ArchitecturesInstallIn64BitMode=x64compatible',
    'EasyWinGetPlus.installed',
    '[UninstallDelete]',
    '{autodesktop}',
    '{uninstallexe}'
)) {
    if ($installer -notmatch [regex]::Escape($required)) { throw "Missing installer behavior: $required" }
}
if ($launcher -notmatch 'EASYWINGETPLUS_INSTALLED') { throw 'The launcher does not identify the installed edition.' }
if ($script -notmatch "InstalledMode.*LOCALAPPDATA.*EasyWinGetPlus" -and $script -notmatch '(?s)InstalledMode.*LOCALAPPDATA.*EasyWinGetPlus') {
    throw 'The installed edition does not store user data under LocalAppData.'
}

'INSTALLER_SMOKE_OK'
