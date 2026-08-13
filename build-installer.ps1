#requires -Version 5.1
[CmdletBinding()]
param([string]$CompilerPath)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot

& (Join-Path $projectRoot 'build.ps1')
if ($LASTEXITCODE -ne 0) { throw 'The application build failed.' }

if ([string]::IsNullOrWhiteSpace($CompilerPath)) {
    $candidates = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe')
    )
    $CompilerPath = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
}
if (-not $CompilerPath -or -not (Test-Path -LiteralPath $CompilerPath)) {
    throw 'Inno Setup 6 compiler (ISCC.exe) was not found. Install Inno Setup 6 or pass -CompilerPath.'
}

$scriptPath = Join-Path $projectRoot 'installer\EasyWinGetPlus.iss'
& $CompilerPath $scriptPath
if ($LASTEXITCODE -ne 0) { throw "Installer build failed with compiler exit code $LASTEXITCODE." }

$outputPath = Join-Path $projectRoot 'release\EasyWinGetPlus-v0.1.8-Setup-x64.exe'
if (-not (Test-Path -LiteralPath $outputPath)) { throw 'The installer compiler did not create the expected setup file.' }
$file = Get-Item -LiteralPath $outputPath
Write-Host "Built $($file.FullName) ($($file.Length) bytes)" -ForegroundColor Green
