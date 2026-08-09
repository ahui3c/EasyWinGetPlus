$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$scriptSource = Get-Content -LiteralPath (Join-Path $projectRoot 'EasyWinGetPlus.ps1') -Raw
$launcherSource = Get-Content -LiteralPath (Join-Path $projectRoot 'src\EasyWinGetPlus.Launcher.cs') -Raw

if ($scriptSource -notmatch 'EasyWinGetPlus\.AppInstance') { throw 'The PowerShell single-instance guard is missing.' }
if ($scriptSource -notmatch 'SingleInstanceMutex\.ReleaseMutex') { throw 'The PowerShell instance mutex is not released on normal shutdown.' }
if ($launcherSource -notmatch 'EasyWinGetPlus\.LauncherInstance') { throw 'The executable single-instance guard is missing.' }
if ($launcherSource -notmatch 'process\.WaitForExit\(\)') { throw 'The launcher does not retain its mutex for the application lifetime.' }
if ($launcherSource -notmatch 'RedirectStandardError = true') { throw 'The launcher does not capture PowerShell startup errors.' }
if ($launcherSource -notmatch 'process\.ExitCode != 0') { throw 'The launcher does not detect a failed PowerShell process.' }
if ($launcherSource -notmatch 'CreateDiagnosticLog') { throw 'The launcher does not write startup diagnostics.' }
if ($launcherSource -notmatch 'Environment\.SpecialFolder\.LocalApplicationData') { throw 'The launcher diagnostic location is not user-writable.' }
if ($launcherSource -notmatch 'EASYWINGETPLUS_EXECUTABLE') { throw 'The launcher does not expose its executable path to the online updater.' }
if ($launcherSource -notmatch 'EASYWINGETPLUS_LAUNCHER_PID') { throw 'The launcher does not expose its process ID to the online updater.' }

'STARTUP_GUARD_SMOKE_OK'
