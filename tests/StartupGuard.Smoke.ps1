$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$scriptSource = Get-Content -LiteralPath (Join-Path $projectRoot 'EasyWinGetPlus.ps1') -Raw
$launcherSource = Get-Content -LiteralPath (Join-Path $projectRoot 'src\EasyWinGetPlus.Launcher.cs') -Raw

if ($scriptSource -notmatch 'EasyWinGetPlus\.AppInstance') { throw 'The PowerShell single-instance guard is missing.' }
if ($scriptSource -notmatch 'SingleInstanceMutex\.ReleaseMutex') { throw 'The PowerShell instance mutex is not released on normal shutdown.' }
if ($launcherSource -notmatch 'EasyWinGetPlus\.LauncherInstance') { throw 'The executable single-instance guard is missing.' }
if ($launcherSource -notmatch 'process\.WaitForExit\(\)') { throw 'The launcher does not retain its mutex for the application lifetime.' }

'STARTUP_GUARD_SMOKE_OK'
