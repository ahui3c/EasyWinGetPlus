$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'EasyWinGetPlus.ps1'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | ForEach-Object Message | Out-String) }

$requiredFunctions = @('Format-UninstallError','Start-PackageUninstall','Start-NextSequentialUninstall')
$definitions = @($ast.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
}, $true))
foreach ($name in $requiredFunctions) {
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
        'RetryingRemoveByName' { "retry $($Values[0])" }
        'RemoveActivity' { "remove $($Values[0])" }
        'RemovingStep' { "step $($Values[0])/$($Values[1]) $($Values[2])" }
        'RemoveSummary' { "summary $($Values[0])/$($Values[1])" }
        'RemoveFailedDetails' { "failed $($Values[0]): $($Values[1])" }
        'MoreApps' { "more $($Values[0])" }
        default { $Key }
    }
}
function Set-Status { param([string]$Message, [bool]$IsError = $false) $script:LastStatus = $Message }
function Set-OverallProgress { param([int]$Completed, [int]$Total, [string]$Activity, [bool]$IsIndeterminate = $false) $script:LastOverallProgress = "$Completed/$Total" }
function End-PackageAction { $script:ActionEnded = $true }
function Show-Error { param([string]$Message) $script:LastError = $Message }
function Refresh-AfterUninstall { $script:RefreshCalled = $true }

# ID failure must retry by exact app name and complete successfully.
$script:Winget = 'mock-winget'
$script:Calls = [System.Collections.Generic.List[object]]::new()
function Start-WingetQuery {
    param($Arguments, $Activity, $OnSuccess, $OnFailure, $State)
    [void]$script:Calls.Add(@($Arguments))
    if ($Arguments -contains '--id') { & $OnFailure 'id failed' $State }
    else { & $OnSuccess @('name succeeded') $State }
}
$script:CompletionResult = $null
$onComplete = {
    param($Succeeded, $Message, $State)
    $script:CompletionResult = [pscustomobject]@{ Succeeded = $Succeeded; Message = $Message; State = $State }
}
$package = [pscustomobject]@{ Id = 'ARP\Machine\X64\Example'; Name = 'Example App' }
Start-PackageUninstall -Package $package -OnComplete $onComplete -State 'caller-state'
Assert-True ($script:Calls.Count -eq 2) 'Expected ID attempt followed by name retry.'
Assert-True ($script:Calls[1] -contains '--name') 'Second attempt did not use --name.'
Assert-True ($script:CompletionResult.Succeeded -eq $true) 'Name retry did not report success.'
Assert-True ($script:CompletionResult.State -eq 'caller-state') 'Caller state was not preserved.'

# Two failures must return both error messages instead of disappearing.
function Start-WingetQuery {
    param($Arguments, $Activity, $OnSuccess, $OnFailure, $State)
    if ($Arguments -contains '--id') { & $OnFailure 'id failed' $State }
    else { & $OnFailure 'name failed' $State }
}
$script:CompletionResult = $null
Start-PackageUninstall -Package $package -OnComplete $onComplete -State $null
Assert-True ($script:CompletionResult.Succeeded -eq $false) 'Double failure incorrectly reported success.'
Assert-True ($script:CompletionResult.Message -match 'ID: id failed') 'ID error was not retained.'
Assert-True ($script:CompletionResult.Message -match 'Name: name failed') 'Name error was not retained.'

# Sequential queue must wait for each completion and summarize successes/failures.
function Start-PackageUninstall {
    param($Package, $OnComplete, $State)
    if ($Package.Name -eq 'Good App') { & $OnComplete $true 'ok' $State }
    else { & $OnComplete $false 'simulated failure' $State }
}
$script:RefreshCalled = $false
$script:LastError = ''
$queue = [pscustomobject]@{
    Packages = @(
        [pscustomobject]@{ Id = 'Good'; Name = 'Good App' },
        [pscustomobject]@{ Id = 'Bad'; Name = 'Bad App' }
    )
    Index = 0
    SuccessCount = 0
    Failures = [System.Collections.Generic.List[string]]::new()
}
Start-NextSequentialUninstall $queue
Assert-True ($queue.Index -eq 2) 'Sequential queue did not process every package.'
Assert-True ($queue.SuccessCount -eq 1) 'Sequential success count is incorrect.'
Assert-True ($queue.Failures.Count -eq 1) 'Sequential failure count is incorrect.'
Assert-True $script:RefreshCalled 'Lists were not refreshed after sequential removal.'
Assert-True ($script:LastError -match 'summary 1/1') 'Sequential summary was not shown.'
Assert-True ($script:LastOverallProgress -eq '2/2') 'Sequential removal progress did not reach the total count.'
Assert-True $script:ActionEnded 'Action controls were not released after sequential removal.'

# Error status must expose a clear action; clearing returns to the normal state.
$setStatusDefinition = $definitions | Where-Object Name -eq 'Set-Status' | Select-Object -First 1
if (-not $setStatusDefinition) { throw 'Missing function: Set-Status' }
. ([scriptblock]::Create($setStatusDefinition.Extent.Text))
$script:StatusText = [pscustomobject]@{ Text = ''; Foreground = '' }
$script:ClearStatusButton = [pscustomobject]@{ Visibility = 'Collapsed' }
Set-Status 'simulated removal failure' $true
Assert-True ($script:ClearStatusButton.Visibility -eq 'Visible') 'Clear message action was not shown for an error.'
Set-Status 'Ready'
Assert-True ($script:StatusText.Text -eq 'Ready') 'Status text was not cleared.'
Assert-True ($script:ClearStatusButton.Visibility -eq 'Collapsed') 'Clear message action did not hide after clearing.'

'UNINSTALL_LOGIC_SMOKE_OK'
