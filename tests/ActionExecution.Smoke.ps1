$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'EasyWinGetPlus.ps1'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | ForEach-Object Message | Out-String) }

$definitions = @($ast.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
}, $true))
foreach ($name in @('Get-DefaultSettings','Set-OverallProgress','Set-PackageActionControlsEnabled','Begin-PackageAction','End-PackageAction','Start-WingetAction','Start-WingetActionQueue','Start-NextWingetActionQueue','Format-UninstallError')) {
    $definition = $definitions | Where-Object Name -eq $name | Select-Object -First 1
    if (-not $definition) { throw "Missing function: $name" }
    . ([scriptblock]::Create($definition.Extent.Text))
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Get-UiText {
    param([string]$Key, [object[]]$Values)
    switch ($Key) {
        'ActionComplete' { "complete $($Values[0])" }
        'ActionStarted' { "started $($Values[0])" }
        'ActionQueueProgress' { "progress $($Values[0])/$($Values[1]) $($Values[2])" }
        'ActionQueueSummary' { "summary $($Values[0])/$($Values[1])" }
        'OverallProgress' { "overall $($Values[0])/$($Values[1]) $($Values[2])" }
        'OperationFailed' { "failed $($Values[0]): $($Values[1])" }
        default { $Key }
    }
}
function Set-Status { param([string]$Message, [bool]$IsError = $false) $script:LastStatus = $Message }
function Show-Error { param([string]$Message) $script:LastError = $Message }
function Invoke-ActionRefresh { param([string]$RefreshAfter) $script:LastRefreshAfter = $RefreshAfter }

$defaults = Get-DefaultSettings
Assert-True ([bool]$defaults.HideActionWindows) 'Action windows should be hidden by default.'

$script:Winget = 'mock-winget'
$script:Settings = [pscustomobject]@{ HideActionWindows = $true }
$script:QueryCalls = 0
$script:LastShowWindow = $null
$script:ActionProgressPanel = [pscustomobject]@{ Visibility = 'Collapsed' }
$script:ActionProgressText = [pscustomobject]@{ Text = '' }
$script:ActionProgressBar = [pscustomobject]@{ IsIndeterminate = $false; Minimum = 0; Maximum = 1; Value = 0 }
foreach ($name in @('InstallButton','UpgradeSelectedButton','UpgradeAllButton','InstallImportedButton','UninstallButton','UpgradeSingleMenuItem','UninstallUpgradeMenuItem','UninstallSingleMenuItem')) {
    Set-Variable -Scope Script -Name $name -Value ([pscustomobject]@{ IsEnabled = $true })
}
$script:ActionInProgress = $false
function Start-WingetQuery {
    param($Arguments, $Activity, $OnSuccess, $OnFailure, $State, [switch]$ShowWindow)
    $script:QueryCalls++
    $script:LastShowWindow = [bool]$ShowWindow
    $script:ControlsLockedDuringQuery = -not $script:InstallButton.IsEnabled -and -not $script:UninstallButton.IsEnabled -and -not $script:UpgradeSingleMenuItem.IsEnabled
    & $OnSuccess @('ok') $State
}

Start-WingetAction @('install','--id','Example.App') 'install Example' -RefreshAfter Installed
Assert-True ($script:QueryCalls -eq 1) 'Hidden mode did not use the background process runner.'
Assert-True (-not $script:LastShowWindow) 'Hidden mode opened a visible process.'
Assert-True ($script:LastStatus -eq 'complete install Example') 'Hidden mode did not report completion.'
Assert-True ($script:ActionProgressBar.Value -eq 1) 'Single-action progress did not reach 1/1.'
Assert-True ($script:LastRefreshAfter -eq 'Installed') 'Single install did not request an installed-list refresh.'
Assert-True $script:ControlsLockedDuringQuery 'Action controls were not locked while the task was running.'
Assert-True $script:InstallButton.IsEnabled 'Action controls were not restored after completion.'

$script:Settings.HideActionWindows = $false
Start-WingetAction @('upgrade','--id','Example.App') 'upgrade Example'
Assert-True $script:LastShowWindow 'Visible mode did not request a normal process window.'

$script:Settings.HideActionWindows = $true
$script:QueryCalls = 0
$jobs = @(
    [pscustomobject]@{ Arguments = @('install','--id','One'); Activity = 'install One' },
    [pscustomobject]@{ Arguments = @('install','--id','Two'); Activity = 'install Two' }
)
Start-WingetActionQueue $jobs -RefreshAfter Both
Assert-True ($script:QueryCalls -eq 2) 'Hidden batch actions were not processed sequentially.'
Assert-True ($script:LastStatus -eq 'summary 2/0') 'Hidden batch action summary is incorrect.'
Assert-True ($script:ActionProgressBar.Value -eq 2) 'Batch progress did not reach the total count.'
Assert-True ($script:ActionProgressText.Text -match 'overall 2/2') 'Batch progress text is incorrect.'
Assert-True ($script:LastRefreshAfter -eq 'Both') 'Batch update did not request both list refreshes.'

# A failed action must also restore every locked control.
function Start-WingetQuery {
    param($Arguments, $Activity, $OnSuccess, $OnFailure, $State, [switch]$ShowWindow)
    & $OnFailure 'simulated failure' $State
}
$script:LastError = ''
Start-WingetAction @('upgrade','--id','Failing.App') 'upgrade Failing'
Assert-True (-not $script:ActionInProgress) 'Failed action left the global action lock enabled.'
Assert-True $script:UpgradeAllButton.IsEnabled 'Failed action did not restore update controls.'
Assert-True ($script:LastError -match 'simulated failure') 'Failed action did not report its error.'

# A second action cannot begin until the active action is ended.
Assert-True (Begin-PackageAction) 'Could not begin an action from the idle state.'
Assert-True (-not (Begin-PackageAction)) 'A duplicate action was allowed while another action was active.'
Assert-True (-not $script:InstallImportedButton.IsEnabled) 'Batch install remained enabled during an active action.'
End-PackageAction
Assert-True $script:UninstallSingleMenuItem.IsEnabled 'Context-menu actions were not restored after completion.'

'ACTION_EXECUTION_SMOKE_OK'
