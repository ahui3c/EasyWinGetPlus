#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $PSScriptRoot 'dist'
}
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) {
    throw 'The .NET Framework C# compiler was not found. Install or enable .NET Framework 4.x.'
}

$scriptPath = Join-Path $PSScriptRoot 'EasyWinGetPlus.ps1'
$launcherPath = Join-Path $PSScriptRoot 'src\EasyWinGetPlus.Launcher.cs'
$iconPath = Join-Path $PSScriptRoot 'assets\icons\EasyWinGetPlus.ico'
if (-not (Test-Path -LiteralPath $scriptPath) -or -not (Test-Path -LiteralPath $launcherPath) -or -not (Test-Path -LiteralPath $iconPath)) {
    throw 'Required source files are missing.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$outputPath = Join-Path $OutputDirectory 'EasyWinGetPlus.exe'

& $compiler /nologo /target:winexe /platform:anycpu /optimize+ `
    /reference:System.dll /reference:System.Windows.Forms.dll `
    "/win32icon:$iconPath" `
    "/resource:$scriptPath,EasyWinGetPlus.ps1" `
    "/out:$outputPath" `
    $launcherPath

if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $outputPath)) {
    throw "Build failed with compiler exit code $LASTEXITCODE."
}

$file = Get-Item -LiteralPath $outputPath
Write-Host "Built $($file.FullName) ($($file.Length) bytes)" -ForegroundColor Green
