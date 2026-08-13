$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'EasyWinGetPlus.ps1'
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | ForEach-Object Message | Out-String) }

$definitions = @($ast.FindAll({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst]
}, $true))
foreach ($name in @('ConvertFrom-WingetTable','Get-Field','Convert-ToPackageRows')) {
    $definition = $definitions | Where-Object Name -eq $name | Select-Object -First 1
    if (-not $definition) { throw "Missing function: $name" }
    . ([scriptblock]::Create($definition.Extent.Text))
}

function Write-AppLog { param([string]$Message, [string]$Level) $script:LastLog = $Message }
function Format-LogText { param([string]$Text, [int]$MaximumLength = 12000) $Text }
function Test-PackageIsExcluded { $false }
function Assert-True([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }

$script:Settings = [pscustomobject]@{ SkipAutoUpgradePackages = @() }
$header = '{0,-18}{1,-25}{2,-14}{3,-14}{4}' -f 'Programm','Kennung','Fassung','Neu','Quelle'
$row = '{0,-18}{1,-25}{2,-14}{3,-14}{4}' -f 'Example App','Vendor.Example','1.0','2.0','winget'
$lines = @($header, ('─' * $header.Length), $row)
$table = @(ConvertFrom-WingetTable $lines 'upgrade')
$packages = @(Convert-ToPackageRows $table -Upgrade)
Assert-True ($packages.Count -eq 1) 'A localized Winget table did not produce one package.'
Assert-True ($packages[0].Name -eq 'Example App') 'The localized name column was not resolved by ordinal fallback.'
Assert-True ($packages[0].Id -eq 'Vendor.Example') 'The localized package ID column was not resolved by ordinal fallback.'
Assert-True ($packages[0].Available -eq '2.0') 'The localized available-version column was not resolved by ordinal fallback.'
Assert-True ($packages[0].Source -eq 'winget') 'The localized source column was not resolved by ordinal fallback.'

$noUpdates = @(ConvertFrom-WingetTable @('No available upgrade found.') 'upgrade')
Assert-True ($noUpdates.Count -eq 0) 'A legitimate no-updates response was not accepted.'

$threw = $false
try { [void](ConvertFrom-WingetTable @('unexpected successful output') 'list') } catch { $threw = $true }
Assert-True $threw 'Unrecognized successful Winget output was incorrectly reported as zero results.'
Assert-True ($script:LastLog -match 'Unrecognized Winget table') 'A parser failure was not written to the diagnostic log.'

$source = Get-Content -LiteralPath $sourcePath -Raw
foreach ($required in @('StandardOutputEncoding = $utf8','StandardErrorEncoding = $utf8','OpenLogFolderButton','Write-AppLog','EasyWinGetPlus-{0}.log')) {
    if ($source -notmatch [regex]::Escape($required)) { throw "Missing data-collection diagnostic behavior: $required" }
}

'WINGET_DATA_COLLECTION_SMOKE_OK'
