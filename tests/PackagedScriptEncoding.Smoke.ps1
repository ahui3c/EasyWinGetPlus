$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$buildDirectory = Join-Path $env:TEMP ('EasyWinGetPlus-EncodingSmoke-' + [guid]::NewGuid().ToString('N'))
$extractedScript = Join-Path $buildDirectory 'EasyWinGetPlus.ps1'

try {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $projectRoot 'build.ps1') -OutputDirectory $buildDirectory
    if ($LASTEXITCODE -ne 0) { throw "Build failed with exit code $LASTEXITCODE." }

    $executable = Join-Path $buildDirectory 'EasyWinGetPlus.exe'
    $extractProcess = Start-Process -FilePath $executable -ArgumentList @('--extract-script', ('"{0}"' -f $extractedScript)) -Wait -PassThru
    if ($extractProcess.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $extractedScript)) {
        throw 'The packaged launcher did not extract its embedded script.'
    }

    $bytes = [IO.File]::ReadAllBytes($extractedScript)
    if ($bytes.Length -lt 3 -or $bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
        throw 'The extracted PowerShell script does not begin with a UTF-8 BOM.'
    }

    $tokens = $null
    $parseErrors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($extractedScript, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) {
        throw "The packaged PowerShell script has parser errors: $($parseErrors[0].Message)"
    }

    $decoded = [Text.Encoding]::UTF8.GetString($bytes)
    if ($decoded -notmatch '簡單、透明的 Windows 軟體管理工具') {
        throw 'Traditional Chinese text was not preserved in the packaged script.'
    }
} finally {
    $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    $resolvedBuild = [IO.Path]::GetFullPath($buildDirectory)
    if ($resolvedBuild.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedBuild)) {
        Remove-Item -LiteralPath $resolvedBuild -Recurse -Force
    }
}

'PACKAGED_SCRIPT_ENCODING_SMOKE_OK'
