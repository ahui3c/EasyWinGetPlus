$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$source = Get-Content -LiteralPath (Join-Path $projectRoot 'EasyWinGetPlus.ps1') -Raw

foreach ($requiredPattern in @(
    'https://api\.github\.com/repos/ahui3c/EasyWinGetPlus/releases/latest',
    'OnlineUpdateButton',
    'DownloadFileTaskAsync',
    'Test-DownloadedUpdateExecutable',
    'Get-FileHash.+SHA256',
    "Verb = 'runas'",
    '-EncodedCommand'
)) {
    if ($source -notmatch $requiredPattern) { throw "Online updater requirement is missing: $requiredPattern" }
}

$functionStart = $source.IndexOf('function ConvertTo-PowerShellSingleQuotedLiteral')
$functionEnd = $source.IndexOf('function Complete-OnlineUpdateCheck')
if ($functionStart -lt 0 -or $functionEnd -le $functionStart) { throw 'Could not extract the update-helper functions.' }
Invoke-Expression $source.Substring($functionStart, $functionEnd - $functionStart)

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('EasyWinGetPlus-UpdateSmoke-' + [guid]::NewGuid().ToString('N'))
$resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
$resolvedRoot = [IO.Path]::GetFullPath($tempRoot)
if (-not $resolvedRoot.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe update smoke-test path.' }

try {
    $downloadDirectory = Join-Path $tempRoot 'download'
    New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null
    $currentExe = Join-Path $tempRoot 'EasyWinGetPlus.exe'
    $packageExe = Join-Path $downloadDirectory 'EasyWinGetPlus.exe'
    'old-version' | Set-Content -LiteralPath $currentExe -Encoding ASCII
    'new-version' | Set-Content -LiteralPath $packageExe -Encoding ASCII
    $hash = (Get-FileHash -LiteralPath $packageExe -Algorithm SHA256).Hash
    $encoded = New-UpdateHelperEncodedCommand $currentExe $packageExe $hash 0 $downloadDirectory $false

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded
    if ($LASTEXITCODE -ne 0) { throw "Update helper exited with code $LASTEXITCODE." }
    if ((Get-Content -LiteralPath $currentExe -Raw).Trim() -ne 'new-version') { throw 'Update helper did not replace the executable.' }
    if (Test-Path -LiteralPath "$currentExe.update-backup") { throw 'Update helper left a backup behind after success.' }
    if (Test-Path -LiteralPath $downloadDirectory) { throw 'Update helper did not clean its download directory.' }
} finally {
    if (Test-Path -LiteralPath $resolvedRoot) { Remove-Item -LiteralPath $resolvedRoot -Recurse -Force }
}

'ONLINE_UPDATE_SMOKE_OK'
