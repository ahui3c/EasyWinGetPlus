$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework
$sourcePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'EasyWinGetPlus.ps1'
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | ForEach-Object Message | Out-String) }

$definition = $ast.FindAll({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-PackagesToExclude'
}, $true) | Select-Object -First 1
if (-not $definition) { throw 'Missing function: Get-PackagesToExclude' }
. ([scriptblock]::Create($definition.Extent.Text))

$source = Get-Content -LiteralPath $sourcePath -Raw
foreach ($requiredText in @('ExcludeInstalledMenuItem','ExcludeUpgradeMenuItem','-SelectedItemOnly')) {
    if ($source -notmatch [regex]::Escape($requiredText)) { throw "Missing context-menu exclusion wiring: $requiredText" }
}

$installedMenuOrder = '(?s)InstalledContextMenu\.Items\.Add\(\$script:UninstallSingleMenuItem\).*?InstalledContextMenu\.Items\.Add\(\[System\.Windows\.Controls\.Separator\]::new\(\)\).*?InstalledContextMenu\.Items\.Add\(\$script:ExcludeInstalledMenuItem\)'
if ($source -notmatch $installedMenuOrder) { throw 'Installed Apps context menu must place Add to exclusions last.' }

$upgradeMenuOrder = '(?s)UpgradeContextMenu\.Items\.Add\(\$script:UpgradeSingleMenuItem\).*?UpgradeContextMenu\.Items\.Add\(\$script:UninstallUpgradeMenuItem\).*?UpgradeContextMenu\.Items\.Add\(\[System\.Windows\.Controls\.Separator\]::new\(\)\).*?UpgradeContextMenu\.Items\.Add\(\$script:ExcludeUpgradeMenuItem\)'
if ($source -notmatch $upgradeMenuOrder) { throw 'Updates context menu must place Add to exclusions last.' }

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
$checked = [pscustomobject]@{ Id = 'Checked.App'; Name = 'Checked'; Selected = $true }
$rightClicked = [pscustomobject]@{ Id = 'RightClicked.App'; Name = 'Right clicked'; Selected = $false }
$contextTargets = @(Get-PackagesToExclude -Items @($checked, $rightClicked) -SelectedItem $rightClicked -SelectedItemOnly)
Assert-True ($contextTargets.Count -eq 1 -and $contextTargets[0].Id -eq 'RightClicked.App') 'The context-menu action did not target only the right-clicked app.'

$toolbarTargets = @(Get-PackagesToExclude -Items @($checked, $rightClicked) -SelectedItem $rightClicked)
Assert-True ($toolbarTargets.Count -eq 1 -and $toolbarTargets[0].Id -eq 'Checked.App') 'The toolbar action no longer prefers checked apps.'

$fallbackTargets = @(Get-PackagesToExclude -Items @($rightClicked) -SelectedItem $rightClicked)
Assert-True ($fallbackTargets.Count -eq 1 -and $fallbackTargets[0].Id -eq 'RightClicked.App') 'The toolbar fallback no longer uses the highlighted row.'

'EXCLUSION_LOGIC_SMOKE_OK'
