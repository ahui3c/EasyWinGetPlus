#requires -Version 5.1

<#+
Easy WinGet Plus - a dependency-free WPF front end for Windows Package Manager.
Settings and exclusions use a portable JSON file beside this script.
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# A wide host buffer keeps long package identifiers from being truncated in
# winget's table output. This is unavailable in some hidden/non-console hosts.
try {
    $buffer = $Host.UI.RawUI.BufferSize
    if ($buffer.Width -lt 240) { $buffer.Width = 240; $Host.UI.RawUI.BufferSize = $buffer }
} catch { }

$script:AppName = 'Easy WinGet Plus'
$script:AppVersion = '0.1.0'
$script:DataDirectory = if ($env:EASYWINGETPLUS_HOME) { $env:EASYWINGETPLUS_HOME } else { $PSScriptRoot }
$script:SettingsPath = Join-Path $script:DataDirectory 'EasyWinGetPlus.settings.json'
$script:LegacySettingsPath = Join-Path (Join-Path $env:LOCALAPPDATA 'EasyWinGetPlus') 'settings.json'
$script:Settings = $null
$script:Winget = $null
$script:SearchResults = @()
$script:InstalledApps = @()
$script:UpgradeApps = @()
$script:ImportedApps = @()
$script:AsyncOperations = [System.Collections.ArrayList]::new()

$script:Translations = @{
    'zh-TW' = @{
        Subtitle='簡單、透明的 Windows 軟體管理工具'; Version='版本 {0}'; About='關於'; Close='關閉'; WingetAvailable='● Winget 可用'; WingetMissing='● 找不到 Winget'
        TabUpgrade='軟體更新'; TabSearch='搜尋與安裝'; TabInstalled='已安裝程式管理'; TabImport='匯入與批次安裝'; TabSettings='設定'
        NotScanned='尚未掃描'; Refresh='重新掃描'; AddExclusion='加入排除項目'; UpgradeSelected='升級選取項目'; UpgradeAll='一鍵全部升級'; FilterList='過濾清單'; FilterTip='輸入名稱、套件識別碼、版本或來源'
        Select='選取'; Name='名稱'; PackageId='套件識別碼'; CurrentVersion='目前版本'; NewVersion='新版本'; VersionColumn='版本'; Source='來源'; SkipAutoUpgrade='不自動更新'
        UpgradeExclusionHint='「加入排除」會從兩份清單隱藏；右側「不自動更新」仍保留顯示，只會在一鍵全部升級時略過。'
        SearchTip='輸入名稱或套件識別碼'; Search='搜尋'; SearchIntro='輸入關鍵字搜尋 Winget 軟體來源。'; InstallSelected='安裝選取程式'
        ExportSelected='匯出勾選清單'; RemoveChecked='依序移除勾選程式'; InstalledHint='兩份清單共用排除項目；勾選程式可依序移除、匯出或加入排除，右鍵可單獨移除。'
        ImportNotLoaded='尚未載入清單'; ChooseBackup='選擇備份檔'; Install='安裝'; InstallChecked='安裝所有勾選程式'
        InstallUpdate='安裝與更新'; SilentInstall='安裝時使用靜默模式（若套件支援）'; SilentUpgrade='更新時使用靜默全自動模式（若套件支援）'
        InterfaceLanguage='介面語言'; InterfaceLanguageHint='第一次啟動時會要求手動選擇，之後可在此隨時切換。'
        DescriptionTranslation='軟體說明翻譯'; AutoTranslate='選取搜尋結果時自動翻譯說明'; TargetLanguage='目標語言'; TranslationPrivacy='翻譯透過 MyMemory 公開服務完成；軟體說明文字會送至該服務。若離線或服務不可用，將保留原文。'
        SharedExclusions='共用排除與隱藏項目'; ExclusionSettingsHint='軟體更新與已安裝程式管理共用同一份排除清單。清除後，程式會在下一次掃描時重新出現在兩邊清單中。'; ClearExclusions='清除所有排除項目'; DataLocation='資料位置'
        AboutPurpose='使用 Windows 內建 Winget 搜尋、安裝、更新、移除與備份軟體清單。'; Author='作者'; Email='郵件'; Website='網站'; Ready='準備就緒'; RemoveSingle='單獨移除此程式'; UpgradeSingle='單獨升級此程式'
        InstalledCount='{0} 個可識別程式'; UpgradeCount='{0} 個可用更新'; FilteredInstalledCount='{0} / {1} 個可識別程式'; FilteredUpgradeCount='{0} / {1} 個可用更新'; ResultsFound='找到 {0} 筆結果。'; SelectForDescription='選取程式即可載入簡介。'; NoResults='找不到符合的程式。'
        BackgroundRunning='{0}（背景執行中，畫面仍可操作）'; ScanningInstalled='正在掃描已安裝程式…'; CheckingUpdates='正在檢查更新…'; ScanComplete='掃描完成，共 {0} 個可識別程式。'; UpdateComplete='更新檢查完成，共 {0} 個更新。'; Searching='正在搜尋「{0}」…'; LoadingDescription='正在背景載入說明，您可以繼續操作其他功能…'; DescriptionLoaded='軟體說明載入完成。'; LanguageChanged='介面語言已切換為繁體中文。'
        WingetRequired='找不到 winget。請先從 Microsoft Store 安裝「應用程式安裝程式」。'; Translating='正在翻譯軟體說明…'; TranslationUnavailable='翻譯服務暫時無法使用，已顯示原文。'; TranslationComplete='軟體說明翻譯完成。'; ActionStarted='{0} 已啟動；完成後請按重新掃描。'; EnterKeyword='請先輸入搜尋關鍵字。'
        SelectExclude='請先勾選或反白要排除的程式。'; ExcludedCount='已排除並隱藏 {0} 個程式；自動更新將略過這些項目。'; NoExclusions='目前沒有任何排除項目。'; ClearConfirm='確定要清除所有排除與隱藏設定嗎？清除後將重新掃描清單。'; ClearStarted='所有排除設定已清除，正在重新掃描清單…'
        SelectBackup='請先勾選要備份的程式。'; ExportTitle='匯出安裝清單'; ExportedCount='已匯出 {0} 個程式。'; ImportTitle='匯入安裝清單'; InvalidList='這不是有效的 Easy WinGet Plus 安裝清單。'; ImportLoaded='{0} 個程式已載入'; ImportReady='安裝清單已載入；可取消不需要的項目後批次安裝。'; NoImportSelected='清單中沒有勾選的程式。'; BatchInstallStarted='已啟動 {0} 個程式的批次安裝。'
        SelectRemove='請先勾選要移除的程式。'; RemoveConfirm="將依序移除 {0} 個程式：`n`n{1}`n`n確定繼續嗎？"; SequentialRemoveStarted='已啟動 {0} 個程式的依序移除；完成後請重新掃描。'; SelectInstall='請先選取要安裝的程式。'; SelectUpgrade='請先勾選要升級的程式。'; NoAutoUpgrade='沒有可自動升級的程式。'; UpgradesStarted='已啟動 {0} 個程式的升級，並略過排除項目。'; RightClickApp='請先在程式項目上按滑鼠右鍵。'; RemoveOneConfirm='確定要單獨移除 {0}？'; InstallActivity='安裝 {0}'; UpgradeActivity='升級 {0}'; RemoveActivity='移除 {0}'; LoadingAppDescription='正在載入 {0} 的說明…'; DescriptionFailed='無法載入說明：{0}'
        MoreApps='…以及其他 {0} 個程式'; SequentialWindowTitle='Easy WinGet Plus - 依序移除程式'; RemovingStep='[{0}/{1}] 正在移除：{2}'; RemoveFailedContinue='移除失敗，繼續下一個項目。'; RemoveDone='移除完成。'; AllRemoveDone='所有移除工作已處理完成，可以關閉此視窗。'; PressEnter='按 Enter 關閉'; OperationFailed="{0}失敗。`n{1}"; OperationError='{0}失敗：{1}'
    }
    'en' = @{
        Subtitle='A simple, transparent Windows software manager'; Version='Version {0}'; About='About'; Close='Close'; WingetAvailable='● Winget available'; WingetMissing='● Winget not found'
        TabUpgrade='Updates'; TabSearch='Search & Install'; TabInstalled='Installed Apps'; TabImport='Import & Batch Install'; TabSettings='Settings'
        NotScanned='Not scanned'; Refresh='Refresh'; AddExclusion='Add to exclusions'; UpgradeSelected='Upgrade selected'; UpgradeAll='Upgrade all'; FilterList='Filter'; FilterTip='Filter by name, package ID, version, or source'
        Select='Select'; Name='Name'; PackageId='Package ID'; CurrentVersion='Current version'; NewVersion='New version'; VersionColumn='Version'; Source='Source'; SkipAutoUpgrade='Skip auto update'
        UpgradeExclusionHint='“Add to exclusions” hides an app from both lists. “Skip auto update” keeps it visible and only skips it during Upgrade all.'
        SearchTip='Enter an app name or package ID'; Search='Search'; SearchIntro='Enter a keyword to search Winget sources.'; InstallSelected='Install selected app'
        ExportSelected='Export selected list'; RemoveChecked='Remove checked apps in order'; InstalledHint='Both lists share exclusions. Checked apps can be removed, exported, or excluded; right-click an app to remove it alone.'
        ImportNotLoaded='No list loaded'; ChooseBackup='Choose backup file'; Install='Install'; InstallChecked='Install all checked apps'
        InstallUpdate='Installation and updates'; SilentInstall='Use silent mode when installing (if supported)'; SilentUpgrade='Use fully automatic silent updates (if supported)'
        InterfaceLanguage='Interface language'; InterfaceLanguageHint='You choose the language manually on first launch and can change it here anytime.'
        DescriptionTranslation='App description translation'; AutoTranslate='Automatically translate the selected search result'; TargetLanguage='Target language'; TranslationPrivacy='Translations use the public MyMemory service. App description text is sent to that service; the original is kept when offline or unavailable.'
        SharedExclusions='Shared exclusions and hidden apps'; ExclusionSettingsHint='Updates and Installed Apps use the same exclusion list. After clearing it, apps return to both lists on the next scan.'; ClearExclusions='Clear all exclusions'; DataLocation='Data location'
        AboutPurpose='Use the built-in Windows Winget to search, install, update, remove, and back up app lists.'; Author='Author'; Email='Email'; Website='Website'; Ready='Ready'; RemoveSingle='Remove this app'; UpgradeSingle='Upgrade this app'
        InstalledCount='{0} recognized apps'; UpgradeCount='{0} available updates'; FilteredInstalledCount='{0} / {1} recognized apps'; FilteredUpgradeCount='{0} / {1} available updates'; ResultsFound='{0} results found.'; SelectForDescription='Select an app to load its description.'; NoResults='No matching apps found.'
        BackgroundRunning='{0} (running in the background; the window remains responsive)'; ScanningInstalled='Scanning installed apps…'; CheckingUpdates='Checking for updates…'; ScanComplete='Scan complete: {0} recognized apps.'; UpdateComplete='Update check complete: {0} updates.'; Searching='Searching for “{0}”…'; LoadingDescription='Loading the description in the background. You can continue using the app…'; DescriptionLoaded='App description loaded.'; LanguageChanged='Interface language changed to English.'
        WingetRequired='Winget was not found. Install App Installer from the Microsoft Store first.'; Translating='Translating the app description…'; TranslationUnavailable='The translation service is unavailable; showing the original text.'; TranslationComplete='App description translated.'; ActionStarted='{0} started. Refresh the list when it finishes.'; EnterKeyword='Enter a search keyword first.'
        SelectExclude='Check or highlight an app to exclude first.'; ExcludedCount='{0} apps were excluded and hidden; automatic upgrades will skip them.'; NoExclusions='There are no excluded apps.'; ClearConfirm='Clear all exclusion and hidden-app settings? The lists will be scanned again.'; ClearStarted='All exclusions were cleared. Scanning the lists again…'
        SelectBackup='Check the apps to back up first.'; ExportTitle='Export installation list'; ExportedCount='Exported {0} apps.'; ImportTitle='Import installation list'; InvalidList='This is not a valid Easy WinGet Plus installation list.'; ImportLoaded='{0} apps loaded'; ImportReady='The installation list is loaded. Uncheck unwanted apps, then start batch installation.'; NoImportSelected='No apps are checked in the list.'; BatchInstallStarted='Batch installation started for {0} apps.'
        SelectRemove='Check the apps to remove first.'; RemoveConfirm="Remove {0} apps in order?`n`n{1}`n`nContinue?"; SequentialRemoveStarted='Sequential removal started for {0} apps. Refresh when it finishes.'; SelectInstall='Select an app to install first.'; SelectUpgrade='Check the apps to upgrade first.'; NoAutoUpgrade='There are no apps available for automatic upgrade.'; UpgradesStarted='Started upgrading {0} apps and skipped exclusions.'; RightClickApp='Right-click an app first.'; RemoveOneConfirm='Remove {0}?'; InstallActivity='Installing {0}'; UpgradeActivity='Upgrading {0}'; RemoveActivity='Removing {0}'; LoadingAppDescription='Loading the description for {0}…'; DescriptionFailed='Could not load the description: {0}'
        MoreApps='…and {0} more apps'; SequentialWindowTitle='Easy WinGet Plus - Sequential Removal'; RemovingStep='[{0}/{1}] Removing: {2}'; RemoveFailedContinue='Removal failed; continuing to the next app.'; RemoveDone='Removal complete.'; AllRemoveDone='All removal tasks have been processed. You can close this window.'; PressEnter='Press Enter to close'; OperationFailed="{0} failed.`n{1}"; OperationError='{0} failed: {1}'
    }
}

function Get-UiText {
    param([Parameter(Mandatory)][string]$Key, [object[]]$Values)
    $language = if ($script:Settings -and $script:Settings.InterfaceLanguage) { $script:Settings.InterfaceLanguage } else { 'en' }
    if (-not $script:Translations.ContainsKey($language)) { $language = 'en' }
    $value = $script:Translations[$language][$Key]
    if ($null -eq $value) { $value = $script:Translations['en'][$Key] }
    if ($Values.Count) { return ($value -f $Values) }
    $value
}

function Apply-InterfaceLanguage {
    if (-not $script:Window) { return }
    $language = $script:Settings.InterfaceLanguage
    if (-not $script:Translations.ContainsKey($language)) { $language = 'en'; $script:Settings.InterfaceLanguage = 'en' }
    foreach ($key in $script:Translations[$language].Keys) { $script:Window.Resources[$key] = $script:Translations[$language][$key] }
    $script:HeaderVersionText.Text = Get-UiText 'Version' @($script:AppVersion)
    $script:AboutVersionText.Text = Get-UiText 'Version' @($script:AppVersion)
    $script:WingetBadgeText.Text = if ($script:Winget) { Get-UiText 'WingetAvailable' } else { Get-UiText 'WingetMissing' }
    if ($script:UpgradeGrid) {
        $keys = @('Select','Name','PackageId','CurrentVersion','NewVersion','SkipAutoUpgrade')
        for ($i = 0; $i -lt $keys.Count; $i++) { $script:UpgradeGrid.Columns[$i].Header = Get-UiText $keys[$i] }
    }
    if ($script:InstalledGrid) {
        $keys = @('Select','Name','PackageId','VersionColumn','Source')
        for ($i = 0; $i -lt $keys.Count; $i++) { $script:InstalledGrid.Columns[$i].Header = Get-UiText $keys[$i] }
    }
    if ($script:SearchGrid) {
        $keys = @('Name','PackageId','VersionColumn','Source')
        for ($i = 0; $i -lt $keys.Count; $i++) { $script:SearchGrid.Columns[$i].Header = Get-UiText $keys[$i] }
    }
    if ($script:ImportGrid) {
        $keys = @('Install','Name','PackageId','Source')
        for ($i = 0; $i -lt $keys.Count; $i++) { $script:ImportGrid.Columns[$i].Header = Get-UiText $keys[$i] }
    }
    if ($script:UninstallSingleMenuItem) { $script:UninstallSingleMenuItem.Header = Get-UiText 'RemoveSingle' }
    if ($script:UninstallUpgradeMenuItem) { $script:UninstallUpgradeMenuItem.Header = Get-UiText 'RemoveSingle' }
    if ($script:UpgradeSingleMenuItem) { $script:UpgradeSingleMenuItem.Header = Get-UiText 'UpgradeSingle' }
    if ($script:ImportedApps.Count -and $script:ImportCount) { $script:ImportCount.Text = Get-UiText 'ImportLoaded' @($script:ImportedApps.Count) }
    if ($script:UpgradeScanned) { Apply-PackageListFilter Upgrade }
    if ($script:InstalledScanned) { Apply-PackageListFilter Installed }
}

function Show-FirstRunLanguageDialog {
    $dialog = [System.Windows.Window]::new()
    $dialog.Title = 'Easy WinGet Plus'
    $dialog.Width = 460
    $dialog.Height = 250
    $dialog.ResizeMode = 'NoResize'
    $dialog.WindowStartupLocation = 'CenterScreen'
    $dialog.Background = '#FF0B1120'
    $dialog.Foreground = '#FFE5E7EB'
    $dialog.FontFamily = 'Segoe UI'

    $panel = [System.Windows.Controls.StackPanel]::new()
    $panel.Margin = '32'
    $heading = [System.Windows.Controls.TextBlock]::new()
    $heading.Text = '選擇介面語言 / Choose interface language'
    $heading.FontSize = 21
    $heading.FontWeight = 'Bold'
    $heading.HorizontalAlignment = 'Center'
    $heading.Margin = '0,5,0,8'
    [void]$panel.Children.Add($heading)

    $hint = [System.Windows.Controls.TextBlock]::new()
    $hint.Text = "第一次啟動請選擇語言。`nChoose a language to continue."
    $hint.Foreground = '#FF94A3B8'
    $hint.TextAlignment = 'Center'
    $hint.Margin = '0,0,0,24'
    [void]$panel.Children.Add($hint)

    $buttons = [System.Windows.Controls.StackPanel]::new()
    $buttons.Orientation = 'Horizontal'
    $buttons.HorizontalAlignment = 'Center'
    foreach ($choice in @(
        [pscustomobject]@{ Text = '繁體中文'; Language = 'zh-TW' },
        [pscustomobject]@{ Text = 'English'; Language = 'en' }
    )) {
        $button = [System.Windows.Controls.Button]::new()
        $button.Content = $choice.Text
        $button.Tag = $choice.Language
        $button.Width = 150
        $button.Padding = '12,10'
        $button.Margin = '8'
        $button.Background = '#FF2563EB'
        $button.Foreground = 'White'
        $button.BorderThickness = '0'
        $button.FontWeight = 'SemiBold'
        $button.Add_Click({
            param($sender, $eventArgs)
            $dialog.Tag = [string]$sender.Tag
            $dialog.DialogResult = $true
        })
        [void]$buttons.Children.Add($button)
    }
    [void]$panel.Children.Add($buttons)
    $dialog.Content = $panel
    $result = $dialog.ShowDialog()
    if ($result -and $dialog.Tag) { return [string]$dialog.Tag }
    $null
}

function Get-DefaultSettings {
    [ordered]@{
        InterfaceLanguage = $null
        AutoTranslate = $false
        TargetLanguage = 'zh-TW'
        SilentInstall = $true
        SilentUpgrade = $true
        ExcludedPackages = @()
        SkipAutoUpgradePackages = @()
        LastExportDirectory = [Environment]::GetFolderPath('MyDocuments')
    }
}

function Import-AppSettings {
    $defaults = Get-DefaultSettings
    $sourcePath = $script:SettingsPath
    $migratingLegacySettings = $false
    if (-not (Test-Path -LiteralPath $sourcePath) -and (Test-Path -LiteralPath $script:LegacySettingsPath)) {
        $sourcePath = $script:LegacySettingsPath
        $migratingLegacySettings = $true
    }
    if (Test-Path -LiteralPath $sourcePath) {
        try {
            $saved = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($name in @($defaults.Keys)) {
                if ($null -ne $saved.PSObject.Properties[$name]) { $defaults[$name] = $saved.$name }
            }
            if ($migratingLegacySettings) {
                [pscustomobject]$defaults | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $script:SettingsPath -Encoding UTF8
            }
        } catch {
            # Keep defaults when a settings file was interrupted or manually corrupted.
        }
    }
    [pscustomobject]$defaults
}

function Save-AppSettings {
    try {
        $script:Settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $script:SettingsPath -Encoding UTF8
    } catch {
        Set-Status "無法儲存設定：$($_.Exception.Message)" $true
    }
}

function Find-Winget {
    $command = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $candidate = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
    if (Test-Path -LiteralPath $candidate) { return $candidate }
    $null
}

function Invoke-WingetText {
    param([Parameter(Mandatory)][string[]]$Arguments)
    if (-not $script:Winget) { throw '找不到 winget。請先從 Microsoft Store 安裝「應用程式安裝程式」。' }
    $output = & $script:Winget @Arguments 2>&1 | ForEach-Object { $_.ToString() }
    if ($LASTEXITCODE -ne 0) {
        $message = ($output | Where-Object { $_ -and $_ -notmatch '^\s*[-\\|/]\s*$' } | Select-Object -Last 4) -join "`n"
        throw "winget 執行失敗 (0x$('{0:X8}' -f ([uint32]$LASTEXITCODE)))。`n$message"
    }
    $output
}

function ConvertTo-NativeArgumentString {
    param([string[]]$Arguments)
    (($Arguments | ForEach-Object {
        if ($_ -notmatch '[\s"]') { $_ }
        else {
            $value = $_ -replace '(\\*)"', '$1$1\"'
            $value = $value -replace '(\\+)$', '$1$1'
            '"' + $value + '"'
        }
    }) -join ' ')
}

function Update-AsyncIndicator {
    if (-not $script:BusyProgress) { return }
    $script:BusyProgress.Visibility = if ($script:AsyncOperations.Count) { 'Visible' } else { 'Collapsed' }
}

function Start-WingetQuery {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$Activity,
        [Parameter(Mandatory)][scriptblock]$OnSuccess,
        [scriptblock]$OnFailure,
        $State
    )
    if (-not $script:Winget) { Show-Error (Get-UiText 'WingetRequired'); return }
    try {
        $info = [System.Diagnostics.ProcessStartInfo]::new()
        $info.FileName = $script:Winget
        $info.Arguments = ConvertTo-NativeArgumentString $Arguments
        $info.UseShellExecute = $false
        $info.CreateNoWindow = $true
        $info.RedirectStandardOutput = $true
        $info.RedirectStandardError = $true
        $process = [System.Diagnostics.Process]::new()
        $process.StartInfo = $info
        if (-not $process.Start()) { throw '無法啟動 winget。' }
        $operation = [pscustomobject]@{
            Kind = 'Process'; Activity = $Activity; Process = $process
            OutputTask = $process.StandardOutput.ReadToEndAsync()
            ErrorTask = $process.StandardError.ReadToEndAsync()
            OnSuccess = $OnSuccess; OnFailure = $OnFailure; State = $State
        }
        [void]$script:AsyncOperations.Add($operation)
        Update-AsyncIndicator
        Set-Status (Get-UiText 'BackgroundRunning' @($Activity))
    } catch {
        if ($OnFailure) { & $OnFailure $_.Exception.Message } else { Show-Error $_.Exception.Message }
    }
}

function Start-TranslationQuery {
    param([string]$Text, [string]$TargetLanguage, [scriptblock]$OnSuccess, $State)
    if ([string]::IsNullOrWhiteSpace($Text)) { & $OnSuccess $Text $State; return }
    try {
        $encoded = [Uri]::EscapeDataString($Text.Substring(0, [Math]::Min(450, $Text.Length)))
        $uri = "https://api.mymemory.translated.net/get?q=$encoded&langpair=en|$TargetLanguage"
        $client = [System.Net.WebClient]::new()
        $client.Encoding = [Text.Encoding]::UTF8
        $operation = [pscustomobject]@{
            Kind = 'Translation'; Activity = (Get-UiText 'Translating'); Client = $client
            Task = $client.DownloadStringTaskAsync([Uri]$uri)
            OriginalText = $Text; OnSuccess = $OnSuccess; OnFailure = $null; State = $State
        }
        [void]$script:AsyncOperations.Add($operation)
        Update-AsyncIndicator
        Set-Status (Get-UiText 'Translating')
    } catch {
        & $OnSuccess $Text $State
        Set-Status (Get-UiText 'TranslationUnavailable') $true
    }
}

function Start-AsyncMonitor {
    $script:AsyncTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $script:AsyncTimer.Interval = [TimeSpan]::FromMilliseconds(150)
    $script:AsyncTimer.Add_Tick({
        foreach ($operation in @($script:AsyncOperations)) {
            $complete = if ($operation.Kind -eq 'Process') { $operation.Process.HasExited } else { $operation.Task.IsCompleted }
            if (-not $complete) { continue }
            [void]$script:AsyncOperations.Remove($operation)
            try {
                if ($operation.Kind -eq 'Process') {
                    $exitCode = $operation.Process.ExitCode
                    $stdout = $operation.OutputTask.Result
                    $stderr = $operation.ErrorTask.Result
                    $operation.Process.Dispose()
                    $lines = @(($stdout -split "\r?\n") | Where-Object { $null -ne $_ })
                    if ($exitCode -ne 0) {
                        $message = (($stderr, $stdout -join "`n").Trim())
                        if (-not $message) { $message = "winget 結束代碼：$exitCode" }
                        if ($operation.OnFailure) { $failure = $operation.OnFailure; & $failure $message $operation.State }
                        else { Show-Error (Get-UiText 'OperationFailed' @($operation.Activity, $message)) }
                    } else {
                        $success = $operation.OnSuccess
                        # Passing (, $lines) creates a nested one-item array in
                        # Windows PowerShell 5.1. Pass the array directly so the
                        # parser receives the actual output lines.
                        & $success $lines $operation.State
                    }
                } else {
                    if ($operation.Task.IsFaulted -or $operation.Task.IsCanceled) {
                        $success = $operation.OnSuccess; & $success $operation.OriginalText $operation.State
                        Set-Status (Get-UiText 'TranslationUnavailable') $true
                    } else {
                        $response = $operation.Task.Result | ConvertFrom-Json
                        $translated = [string]$response.responseData.translatedText
                        if (-not $translated) { $translated = $operation.OriginalText }
                        $success = $operation.OnSuccess; & $success $translated $operation.State
                        Set-Status (Get-UiText 'TranslationComplete')
                    }
                    $operation.Client.Dispose()
                }
            } catch {
                if ($operation.Kind -eq 'Translation') {
                    $success = $operation.OnSuccess; & $success $operation.OriginalText $operation.State
                    try { $operation.Client.Dispose() } catch { }
                }
                Set-Status (Get-UiText 'OperationError' @($operation.Activity, $_.Exception.Message)) $true
            }
        }
        Update-AsyncIndicator
    })
    $script:AsyncTimer.Start()
}

function ConvertFrom-WingetTable {
    param([string[]]$Lines)
    # Be defensive about output captured from different winget/console builds.
    # Remove terminal colour/progress sequences and flatten accidental nesting.
    $ansiPattern = [char]27 + '\[[0-?]*[ -/]*[@-~]'
    $Lines = @($Lines | ForEach-Object {
        if ($_ -is [System.Array]) { $_ | ForEach-Object { ([string]$_) -replace $ansiPattern, '' } }
        else { ([string]$_) -replace $ansiPattern, '' }
    })
    $separatorIndex = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\s*-{5,}\s*$' -or $Lines[$i] -match '^\s*-{2,}(\s+-{2,})+') { $separatorIndex = $i; break }
    }
    if ($separatorIndex -lt 1) { return @() }

    $header = $Lines[$separatorIndex - 1]
    $separator = $Lines[$separatorIndex]
    $runs = [regex]::Matches($separator, '-+')
    # Newer winget builds use one continuous separator; older/localized builds
    # may use a dash run per column. Header positions work for both variants.
    $headerFields = [regex]::Matches($header, '\S(?:.*?\S)?(?=\s{2,}|$)')
    $starts = if ($runs.Count -ge 2) { @($runs | ForEach-Object Index) } else { @($headerFields | ForEach-Object Index) }
    if ($starts.Count -lt 2) { return @() }
    $columns = for ($c = 0; $c -lt $starts.Count; $c++) {
        $start = $starts[$c]
        $end = if ($c -lt $starts.Count - 1) { $starts[$c + 1] } else { [int]::MaxValue }
        $nameLength = if ($end -eq [int]::MaxValue) { $header.Length - $start } else { $end - $start }
        $name = if ($start -lt $header.Length) { $header.Substring($start, [Math]::Min($nameLength, $header.Length - $start)).Trim() } else { "Column$c" }
        [pscustomobject]@{ Name = $name; Start = $start; End = $end }
    }

    $items = @()
    for ($i = $separatorIndex + 1; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        if ([string]::IsNullOrWhiteSpace($line) -or $line -match '^\s*\d+\s+(upgrades?|更新)' -or $line -match '^\s*(No |沒有)') { continue }
        $record = [ordered]@{}
        foreach ($column in $columns) {
            if ($column.Start -ge $line.Length) { $value = '' }
            else {
                $length = if ($column.End -eq [int]::MaxValue) { $line.Length - $column.Start } else { [Math]::Min($column.End - $column.Start, $line.Length - $column.Start) }
                $value = $line.Substring($column.Start, $length).Trim()
            }
            $record[$column.Name] = $value
        }
        $items += [pscustomobject]$record
    }
    $items
}

function Get-Field {
    param($Object, [string[]]$Names)
    foreach ($name in $Names) {
        $property = $Object.PSObject.Properties | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        if ($property) { return [string]$property.Value }
    }
    ''
}

function Test-PackageIsExcluded {
    param([string]$Id)
    if ([string]::IsNullOrWhiteSpace($Id)) { return $false }
    @($script:Settings.ExcludedPackages) -contains $Id.Trim()
}

function Convert-ToPackageRows {
    param([object[]]$Rows, [switch]$Upgrade)
    foreach ($row in $Rows) {
        $name = Get-Field $row @('Name', '名稱')
        $id = Get-Field $row @('Id', '識別碼')
        $version = Get-Field $row @('Version', '版本')
        $available = Get-Field $row @('Available', '可用')
        $source = Get-Field $row @('Source', '來源')
        if (-not $id) { continue }
        [pscustomobject]@{
            Selected = $false
            Name = $name
            Id = $id
            Version = $version
            Available = $available
            Source = $source
            Excluded = [bool](Test-PackageIsExcluded $id)
            SkipAutoUpgrade = [bool](@($script:Settings.SkipAutoUpgradePackages) -contains $id)
        }
    }
}

function Test-PackageFilterMatch {
    param($Package, [string]$Keyword)
    if ([string]::IsNullOrWhiteSpace($Keyword)) { return $true }
    $keywordValue = $Keyword.Trim()
    foreach ($value in @($Package.Name, $Package.Id, $Package.Version, $Package.Available, $Package.Source)) {
        if ($null -ne $value -and ([string]$value).IndexOf($keywordValue, [StringComparison]::CurrentCultureIgnoreCase) -ge 0) { return $true }
    }
    $false
}

function Apply-PackageListFilter {
    param([Parameter(Mandatory)][ValidateSet('Upgrade','Installed')][string]$ListKind)
    if ($ListKind -eq 'Upgrade') {
        $grid = $script:UpgradeGrid; $items = @($script:UpgradeApps); $box = $script:UpgradeFilterBox; $count = $script:UpgradeCount
        if ($grid.SelectedItem) { $script:UpgradeFocusedId = $grid.SelectedItem.Id }
        $focusedId = $script:UpgradeFocusedId; $countKey = 'UpgradeCount'; $filteredCountKey = 'FilteredUpgradeCount'
    } else {
        $grid = $script:InstalledGrid; $items = @($script:InstalledApps); $box = $script:InstalledFilterBox; $count = $script:InstalledCount
        if ($grid.SelectedItem) { $script:InstalledFocusedId = $grid.SelectedItem.Id }
        $focusedId = $script:InstalledFocusedId; $countKey = 'InstalledCount'; $filteredCountKey = 'FilteredInstalledCount'
    }
    try { $grid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true) | Out-Null } catch { }
    $keyword = if ($box) { $box.Text } else { '' }
    $visible = @($items | Where-Object { Test-PackageFilterMatch $_ $keyword })
    $grid.ItemsSource = $visible
    if ($focusedId) {
        $focusedItem = $visible | Where-Object Id -eq $focusedId | Select-Object -First 1
        if ($focusedItem) { $grid.SelectedItem = $focusedItem }
    }
    $count.Text = if ([string]::IsNullOrWhiteSpace($keyword)) { Get-UiText $countKey @($items.Count) } else { Get-UiText $filteredCountKey @($visible.Count, $items.Count) }
}

function Find-VisualAncestor {
    param([System.Windows.DependencyObject]$Element, [Type]$AncestorType)
    $current = $Element
    while ($current) {
        if ($AncestorType.IsInstanceOfType($current)) { return $current }
        try { $current = [System.Windows.Media.VisualTreeHelper]::GetParent($current) }
        catch { $current = [System.Windows.LogicalTreeHelper]::GetParent($current) }
    }
    $null
}

function Select-RowOnCheckboxClick {
    param($Grid, [System.Windows.DependencyObject]$OriginalSource)
    if (-not (Find-VisualAncestor $OriginalSource ([System.Windows.Controls.CheckBox]))) { return }
    $row = [System.Windows.Controls.ItemsControl]::ContainerFromElement($Grid, $OriginalSource)
    if ($row -is [System.Windows.Controls.DataGridRow]) { $Grid.SelectedItem = $row.Item }
}

function Set-Status {
    param([string]$Message, [bool]$IsError = $false)
    if (-not $script:StatusText) { return }
    $script:StatusText.Text = $Message
    $script:StatusText.Foreground = if ($IsError) { '#FFFCA5A5' } else { '#FFA7F3D0' }
}

function Show-Error {
    param([string]$Message)
    Set-Status $Message $true
    [System.Windows.MessageBox]::Show($script:Window, $Message, $script:AppName, 'OK', 'Error') | Out-Null
}

function Get-PackageDescriptionFromLines {
    param([string[]]$Lines)
    $description = ''
    $capture = $false
    foreach ($line in $Lines) {
        if ($line -match '^\s*(Description|描述)\s*:\s*(.*)$') {
            $description = $matches[2].Trim(); $capture = $true; continue
        }
        if ($capture) {
            if ($line -match '^\S[^:]{1,30}:') { break }
            if ($line.Trim()) { $description += "`n" + $line.Trim() }
        }
    }
    if (-not $description) { $description = ($Lines | Select-Object -First 12) -join "`n" }
    $description.Trim()
}

function Invoke-Translation {
    param([string]$Text, [string]$TargetLanguage)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $Text }
    try {
        $encoded = [Uri]::EscapeDataString($Text.Substring(0, [Math]::Min(450, $Text.Length)))
        $language = if ($TargetLanguage -eq 'zh-TW') { 'zh-TW' } else { $TargetLanguage }
        $uri = "https://api.mymemory.translated.net/get?q=$encoded&langpair=en|$language"
        $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 12 -UseBasicParsing
        if ($response.responseData.translatedText) { return [string]$response.responseData.translatedText }
    } catch {
        Set-Status '翻譯服務暫時無法使用，已顯示原文。' $true
    }
    $Text
}

function Start-WingetAction {
    param([string[]]$Arguments, [string]$Activity)
    if (-not $script:Winget) { Show-Error (Get-UiText 'WingetRequired'); return }
    try {
        Start-Process -FilePath $script:Winget -ArgumentList $Arguments -WindowStyle Normal | Out-Null
        Set-Status (Get-UiText 'ActionStarted' @($Activity))
    } catch { Show-Error $_.Exception.Message }
}

function Refresh-Installed {
    Start-WingetQuery @('list', '--accept-source-agreements', '--disable-interactivity') (Get-UiText 'ScanningInstalled') {
        param($lines)
        $rows = ConvertFrom-WingetTable $lines
        $script:InstalledApps = @(Convert-ToPackageRows $rows | Where-Object { -not $_.Excluded })
        $script:InstalledScanned = $true
        Apply-PackageListFilter Installed
        Set-Status (Get-UiText 'ScanComplete' @($script:InstalledApps.Count))
    }
}

function Refresh-Upgrades {
    Start-WingetQuery @('upgrade', '--accept-source-agreements', '--disable-interactivity', '--include-unknown') (Get-UiText 'CheckingUpdates') {
        param($lines)
        $rows = ConvertFrom-WingetTable $lines
        $script:UpgradeApps = @(Convert-ToPackageRows $rows -Upgrade | Where-Object { -not $_.Excluded })
        $script:UpgradeScanned = $true
        Apply-PackageListFilter Upgrade
        Set-Status (Get-UiText 'UpdateComplete' @($script:UpgradeApps.Count))
    }
}

function Search-Packages {
    $query = $script:SearchBox.Text.Trim()
    if (-not $query) { Set-Status (Get-UiText 'EnterKeyword') $true; return }
    $script:LatestSearchQuery = $query
    $searchCompleted = {
        param($lines, $responseQuery)
        if ($responseQuery -ne $script:LatestSearchQuery) { return }
        $rows = ConvertFrom-WingetTable $lines
        $script:SearchResults = @(Convert-ToPackageRows $rows)
        $script:SearchGrid.ItemsSource = $script:SearchResults
        $script:SearchDescription.Text = if ($script:SearchResults.Count) { Get-UiText 'SelectForDescription' } else { Get-UiText 'NoResults' }
        Set-Status (Get-UiText 'ResultsFound' @($script:SearchResults.Count))
    }
    Start-WingetQuery -Arguments @('search', '--query', $query, '--accept-source-agreements', '--disable-interactivity') -Activity (Get-UiText 'Searching' @($query)) -OnSuccess $searchCompleted -State $query
}

function Add-PackagesToExclusions {
    param(
        [Parameter(Mandatory)]$Grid,
        [Parameter(Mandatory)][ValidateSet('Upgrade','Installed')][string]$ListKind
    )
    try { $Grid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true) | Out-Null } catch { }
    $items = if ($ListKind -eq 'Upgrade') { @($script:UpgradeApps) } else { @($script:InstalledApps) }
    $targets = @($items | Where-Object Selected)
    if (-not $targets.Count -and $Grid.SelectedItem) { $targets = @($Grid.SelectedItem) }
    if (-not $targets.Count) {
        Set-Status (Get-UiText 'SelectExclude') $true
        return
    }

    $newIds = @($targets | ForEach-Object Id | Where-Object { $_ } | Sort-Object -Unique)
    $script:Settings.ExcludedPackages = @(@($script:Settings.ExcludedPackages) + $newIds | Sort-Object -Unique)
    Save-AppSettings

    # Exclusions are shared by both views, so remove matching rows immediately.
    $script:UpgradeApps = @($script:UpgradeApps | Where-Object { -not (Test-PackageIsExcluded $_.Id) })
    $script:InstalledApps = @($script:InstalledApps | Where-Object { -not (Test-PackageIsExcluded $_.Id) })
    Apply-PackageListFilter Upgrade
    Apply-PackageListFilter Installed
    Set-Status (Get-UiText 'ExcludedCount' @($newIds.Count))
}

function Set-PackageAutoUpgradeSkip {
    param([string]$Id, [bool]$Skip)
    if ([string]::IsNullOrWhiteSpace($Id)) { return }
    $savedIds = @($script:Settings.SkipAutoUpgradePackages)
    if ($Skip) {
        $savedIds = @($savedIds + $Id | Sort-Object -Unique)
    } else {
        $savedIds = @($savedIds | Where-Object { $_ -ne $Id })
    }
    $script:Settings.SkipAutoUpgradePackages = $savedIds
    Save-AppSettings
}

function Clear-AllExclusions {
    if (-not @($script:Settings.ExcludedPackages).Count) {
        Set-Status (Get-UiText 'NoExclusions')
        return
    }
    $answer = [System.Windows.MessageBox]::Show($script:Window, (Get-UiText 'ClearConfirm'), $script:AppName, 'YesNo', 'Question')
    if ($answer -ne 'Yes') { return }
    $script:Settings.ExcludedPackages = @()
    Save-AppSettings
    Set-Status (Get-UiText 'ClearStarted')
    Refresh-Upgrades
    Refresh-Installed
}

function Export-PackageList {
    $selected = @($script:InstalledApps | Where-Object Selected)
    if (-not $selected.Count) { Set-Status (Get-UiText 'SelectBackup') $true; return }
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Title = Get-UiText 'ExportTitle'
    $dialog.Filter = 'Easy WinGet Plus 清單 (*.ewp.json)|*.ewp.json|JSON (*.json)|*.json'
    $dialog.InitialDirectory = $script:Settings.LastExportDirectory
    $dialog.FileName = "winget-backup-$((Get-Date).ToString('yyyyMMdd')).ewp.json"
    if ($dialog.ShowDialog($script:Window)) {
        $payload = [ordered]@{
            format = 'EasyWinGetPlus.PackageList'
            version = 1
            createdAt = (Get-Date).ToUniversalTime().ToString('o')
            packages = @($selected | ForEach-Object { [ordered]@{ id = $_.Id; name = $_.Name; source = $_.Source } })
        }
        $payload | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $dialog.FileName -Encoding UTF8
        $script:Settings.LastExportDirectory = Split-Path -Parent $dialog.FileName
        Save-AppSettings
        Set-Status (Get-UiText 'ExportedCount' @($selected.Count))
    }
}

function Import-PackageList {
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Title = Get-UiText 'ImportTitle'
    $dialog.Filter = '支援的清單 (*.ewp.json;*.json)|*.ewp.json;*.json|所有檔案 (*.*)|*.*'
    if (-not $dialog.ShowDialog($script:Window)) { return }
    try {
        $data = Get-Content -LiteralPath $dialog.FileName -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($data.format -ne 'EasyWinGetPlus.PackageList' -or -not $data.packages) { throw (Get-UiText 'InvalidList') }
        $script:ImportedApps = @($data.packages | ForEach-Object {
            [pscustomobject]@{ Selected = $true; Name = [string]$_.name; Id = [string]$_.id; Source = [string]$_.source }
        })
        $script:ImportGrid.ItemsSource = $script:ImportedApps
        $script:ImportCount.Text = Get-UiText 'ImportLoaded' @($script:ImportedApps.Count)
        Set-Status (Get-UiText 'ImportReady')
    } catch { Show-Error $_.Exception.Message }
}

function Install-ImportedPackages {
    $selected = @($script:ImportedApps | Where-Object Selected)
    if (-not $selected.Count) { Set-Status (Get-UiText 'NoImportSelected') $true; return }
    $silent = [bool]$script:Settings.SilentInstall
    $commands = foreach ($package in $selected) {
        $id = $package.Id.Replace("'", "''")
        $extra = if ($silent) { "'--silent'" } else { '' }
        "& '$($script:Winget.Replace("'", "''"))' install --id '$id' --exact --accept-package-agreements --accept-source-agreements --disable-interactivity $extra"
    }
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(($commands -join "`r`n")))
    Start-Process powershell.exe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encoded) -WindowStyle Normal | Out-Null
    Set-Status (Get-UiText 'BatchInstallStarted' @($selected.Count))
}

function Start-SequentialUninstall {
    param([Parameter(Mandatory)][object[]]$Packages)
    $Packages = @($Packages | Where-Object { $_.Id })
    if (-not $Packages.Count) { Set-Status (Get-UiText 'SelectRemove') $true; return }

    $preview = @($Packages | Select-Object -First 8 | ForEach-Object { "• $($_.Name)" }) -join "`n"
    if ($Packages.Count -gt 8) { $preview += "`n" + (Get-UiText 'MoreApps' @(($Packages.Count - 8))) }
    $answer = [System.Windows.MessageBox]::Show(
        $script:Window,
        (Get-UiText 'RemoveConfirm' @($Packages.Count, $preview)),
        $script:AppName,
        'YesNo',
        'Warning'
    )
    if ($answer -ne 'Yes') { return }

    $wingetPath = $script:Winget.Replace("'", "''")
    $consoleTitle = (Get-UiText 'SequentialWindowTitle').Replace("'", "''")
    $removeFailed = (Get-UiText 'RemoveFailedContinue').Replace("'", "''")
    $removeDone = (Get-UiText 'RemoveDone').Replace("'", "''")
    $allDone = (Get-UiText 'AllRemoveDone').Replace("'", "''")
    $pressEnter = (Get-UiText 'PressEnter').Replace("'", "''")
    $commands = @("`$host.UI.RawUI.WindowTitle = '$consoleTitle'")
    for ($i = 0; $i -lt $Packages.Count; $i++) {
        $package = $Packages[$i]
        $id = ([string]$package.Id).Replace("'", "''")
        $name = ([string]$package.Name).Replace("'", "''")
        $number = $i + 1
        $stepText = (Get-UiText 'RemovingStep' @($number, $Packages.Count, $name)).Replace("'", "''")
        $commands += "Write-Host ''; Write-Host '$stepText' -ForegroundColor Cyan"
        $commands += "& '$wingetPath' uninstall --id '$id' --exact --disable-interactivity"
        $commands += "if (`$LASTEXITCODE -ne 0) { Write-Host '$removeFailed' -ForegroundColor Red } else { Write-Host '$removeDone' -ForegroundColor Green }"
    }
    $commands += "Write-Host ''; Write-Host '$allDone' -ForegroundColor Yellow"
    $commands += "Read-Host '$pressEnter'"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(($commands -join "`r`n")))
    Start-Process powershell.exe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encoded) -WindowStyle Normal | Out-Null
    Set-Status (Get-UiText 'SequentialRemoveStarted' @($Packages.Count))
}

$script:Settings = Import-AppSettings
if (@('zh-TW', 'en') -notcontains [string]$script:Settings.InterfaceLanguage) {
    $firstRunLanguage = Show-FirstRunLanguageDialog
    if (-not $firstRunLanguage) { return }
    $script:Settings.InterfaceLanguage = $firstRunLanguage
}
Save-AppSettings
$script:Winget = Find-Winget

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Easy WinGet Plus" Width="1180" Height="760" MinWidth="920" MinHeight="620" WindowStartupLocation="CenterScreen" Background="#0B1120" Foreground="#E5E7EB" FontFamily="Segoe UI">
  <Window.Resources>
    <SolidColorBrush x:Key="Panel" Color="#111827"/><SolidColorBrush x:Key="Panel2" Color="#172033"/><SolidColorBrush x:Key="Accent" Color="#38BDF8"/>
    <Style TargetType="Button"><Setter Property="Background" Value="#2563EB"/><Setter Property="Foreground" Value="White"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Padding" Value="16,9"/><Setter Property="Margin" Value="4"/><Setter Property="Cursor" Value="Hand"/><Setter Property="FontWeight" Value="SemiBold"/></Style>
    <Style TargetType="TextBox"><Setter Property="Background" Value="#0F172A"/><Setter Property="Foreground" Value="#F8FAFC"/><Setter Property="BorderBrush" Value="#334155"/><Setter Property="Padding" Value="10,8"/><Setter Property="CaretBrush" Value="White"/></Style>
    <Style TargetType="ComboBox"><Setter Property="Background" Value="#0F172A"/><Setter Property="Foreground" Value="#111827"/><Setter Property="Padding" Value="8,5"/></Style>
    <Style TargetType="CheckBox"><Setter Property="Foreground" Value="#E5E7EB"/><Setter Property="Margin" Value="4"/><Setter Property="VerticalAlignment" Value="Center"/></Style>
    <Style TargetType="DataGrid"><Setter Property="Background" Value="#111827"/><Setter Property="Foreground" Value="#E5E7EB"/><Setter Property="RowBackground" Value="#111827"/><Setter Property="AlternatingRowBackground" Value="#172033"/><Setter Property="HorizontalGridLinesBrush" Value="#243244"/><Setter Property="VerticalGridLinesBrush" Value="#243244"/><Setter Property="BorderBrush" Value="#334155"/><Setter Property="HeadersVisibility" Value="Column"/><Setter Property="CanUserAddRows" Value="False"/><Setter Property="AutoGenerateColumns" Value="False"/><Setter Property="SelectionMode" Value="Single"/><Setter Property="SelectionUnit" Value="FullRow"/></Style>
    <Style TargetType="DataGridColumnHeader"><Setter Property="Background" Value="#1E293B"/><Setter Property="Foreground" Value="#CBD5E1"/><Setter Property="Padding" Value="8"/><Setter Property="FontWeight" Value="SemiBold"/></Style>
    <Style TargetType="TabItem"><Setter Property="Foreground" Value="#CBD5E1"/><Setter Property="Background" Value="#111827"/><Setter Property="Padding" Value="20,11"/><Setter Property="FontSize" Value="14"/><Setter Property="FontWeight" Value="SemiBold"/></Style>
  </Window.Resources>
  <Grid Margin="20"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
    <Grid Margin="4,0,4,16"><Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
      <StackPanel><TextBlock Text="Easy WinGet Plus" FontSize="28" FontWeight="Bold" Foreground="White"/><StackPanel Orientation="Horizontal" Margin="0,4,0,0"><TextBlock Text="{DynamicResource Subtitle}" Foreground="#94A3B8"/><TextBlock x:Name="HeaderVersionText" Foreground="#64748B" FontSize="11" Margin="10,2,0,0"/></StackPanel></StackPanel>
      <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center"><Button x:Name="AboutButton" Content="{DynamicResource About}" Background="#334155" Padding="13,7"/><Border x:Name="WingetBadge" CornerRadius="16" Padding="13,7" Margin="8,0,0,0" VerticalAlignment="Center"><TextBlock x:Name="WingetBadgeText" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center" TextAlignment="Center"/></Border></StackPanel>
    </Grid>
    <Popup x:Name="AboutPopup" Placement="Center" StaysOpen="False" AllowsTransparency="True" PopupAnimation="Fade">
      <Border Background="#FF111827" BorderBrush="#475569" BorderThickness="1" CornerRadius="10" Padding="28" Width="500"><Border.Effect><DropShadowEffect BlurRadius="24" ShadowDepth="5" Opacity="0.5" Color="Black"/></Border.Effect><StackPanel>
        <Grid><TextBlock Text="Easy WinGet Plus" FontSize="24" FontWeight="Bold" Foreground="White"/><Button x:Name="CloseAboutButton" Content="{DynamicResource Close}" HorizontalAlignment="Right" Background="#334155" Padding="13,6"/></Grid>
        <TextBlock x:Name="AboutVersionText" FontSize="12" Foreground="#64748B" Margin="0,4,0,20"/>
        <TextBlock Text="{DynamicResource AboutPurpose}" Foreground="#CBD5E1" TextWrapping="Wrap" Margin="0,0,0,22"/>
        <Separator Background="#334155" Margin="0,0,0,18"/>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="80"/><ColumnDefinition/></Grid.ColumnDefinitions><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
          <TextBlock Text="{DynamicResource Author}" Foreground="#94A3B8" Margin="0,5"/><TextBlock Grid.Column="1" Text="廖阿輝" Foreground="#F8FAFC" Margin="0,5"/>
          <TextBlock Grid.Row="1" Text="{DynamicResource Email}" Foreground="#94A3B8" Margin="0,5"/><TextBlock Grid.Row="1" Grid.Column="1" Margin="0,5"><Hyperlink x:Name="EmailLink" NavigateUri="mailto:chehui@gmail.com" Foreground="#38BDF8">chehui@gmail.com</Hyperlink></TextBlock>
          <TextBlock Grid.Row="2" Text="{DynamicResource Website}" Foreground="#94A3B8" Margin="0,5"/><TextBlock Grid.Row="2" Grid.Column="1" Margin="0,5"><Hyperlink x:Name="WebsiteLink" NavigateUri="https://ahui3c.com" Foreground="#38BDF8">https://ahui3c.com</Hyperlink></TextBlock>
        </Grid>
      </StackPanel></Border>
    </Popup>
    <TabControl x:Name="MainTabs" Grid.Row="1" SelectedIndex="0" Background="#0B1120" BorderBrush="#253047">
      <TabItem Header="{DynamicResource TabUpgrade}"><Grid Margin="14"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <Grid><TextBlock x:Name="UpgradeCount" Text="{DynamicResource NotScanned}" FontSize="17" FontWeight="SemiBold" VerticalAlignment="Center"/><StackPanel Orientation="Horizontal" HorizontalAlignment="Right"><Button x:Name="RefreshUpgradeButton" Content="{DynamicResource Refresh}"/><Button x:Name="ExcludeUpgradeButton" Content="{DynamicResource AddExclusion}" Background="#7C3AED"/><Button x:Name="UpgradeSelectedButton" Content="{DynamicResource UpgradeSelected}"/><Button x:Name="UpgradeAllButton" Content="{DynamicResource UpgradeAll}" Background="#059669"/></StackPanel></Grid>
        <Grid Grid.Row="1" Margin="0,10,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="320"/><ColumnDefinition/></Grid.ColumnDefinitions><TextBlock Text="{DynamicResource FilterList}" VerticalAlignment="Center" Margin="0,0,10,0" Foreground="#CBD5E1"/><TextBox x:Name="UpgradeFilterBox" Grid.Column="1" ToolTip="{DynamicResource FilterTip}"/></Grid>
        <DataGrid x:Name="UpgradeGrid" Grid.Row="2" Margin="0,10"><DataGrid.Columns><DataGridTemplateColumn Header="{DynamicResource Select}" Width="60"><DataGridTemplateColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding Selected, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" HorizontalAlignment="Center" VerticalAlignment="Center"/></DataTemplate></DataGridTemplateColumn.CellTemplate></DataGridTemplateColumn><DataGridTextColumn Header="{DynamicResource Name}" Binding="{Binding Name}" Width="2*"/><DataGridTextColumn Header="{DynamicResource PackageId}" Binding="{Binding Id}" Width="2*"/><DataGridTextColumn Header="{DynamicResource CurrentVersion}" Binding="{Binding Version}" Width="*"/><DataGridTextColumn Header="{DynamicResource NewVersion}" Binding="{Binding Available}" Width="*"/><DataGridTemplateColumn Header="{DynamicResource SkipAutoUpgrade}" Width="115"><DataGridTemplateColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding SkipAutoUpgrade, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" HorizontalAlignment="Center" VerticalAlignment="Center" ToolTip="{DynamicResource SkipAutoUpgrade}"/></DataTemplate></DataGridTemplateColumn.CellTemplate></DataGridTemplateColumn></DataGrid.Columns></DataGrid>
        <TextBlock Grid.Row="3" Text="{DynamicResource UpgradeExclusionHint}" Foreground="#94A3B8"/>
      </Grid></TabItem>
      <TabItem Header="{DynamicResource TabSearch}"><Grid Margin="14"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="150"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBox x:Name="SearchBox" FontSize="15" ToolTip="{DynamicResource SearchTip}"/><Button x:Name="SearchButton" Grid.Column="1" Content="{DynamicResource Search}" MinWidth="90" IsDefault="True"/></Grid>
        <DataGrid x:Name="SearchGrid" Grid.Row="1" Margin="0,12"><DataGrid.Columns><DataGridTextColumn Header="{DynamicResource Name}" Binding="{Binding Name}" Width="2*"/><DataGridTextColumn Header="{DynamicResource PackageId}" Binding="{Binding Id}" Width="2*"/><DataGridTextColumn Header="{DynamicResource VersionColumn}" Binding="{Binding Version}" Width="*"/><DataGridTextColumn Header="{DynamicResource Source}" Binding="{Binding Source}" Width="*"/></DataGrid.Columns></DataGrid>
        <Border Grid.Row="2" Background="#0F172A" BorderBrush="#253047" BorderThickness="1" CornerRadius="6" Padding="12"><ScrollViewer VerticalScrollBarVisibility="Auto"><TextBlock x:Name="SearchDescription" Text="{DynamicResource SearchIntro}" TextWrapping="Wrap" Foreground="#CBD5E1"/></ScrollViewer></Border>
        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right"><Button x:Name="InstallButton" Content="{DynamicResource InstallSelected}" MinWidth="145"/></StackPanel>
      </Grid></TabItem>
      <TabItem Header="{DynamicResource TabInstalled}"><Grid Margin="14"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <Grid><TextBlock x:Name="InstalledCount" Text="{DynamicResource NotScanned}" FontSize="17" FontWeight="SemiBold" VerticalAlignment="Center"/><StackPanel Orientation="Horizontal" HorizontalAlignment="Right"><Button x:Name="RefreshInstalledButton" Content="{DynamicResource Refresh}"/><Button x:Name="ExcludeInstalledButton" Content="{DynamicResource AddExclusion}" Background="#7C3AED"/><Button x:Name="ExportButton" Content="{DynamicResource ExportSelected}"/><Button x:Name="UninstallButton" Content="{DynamicResource RemoveChecked}" Background="#DC2626"/></StackPanel></Grid>
        <Grid Grid.Row="1" Margin="0,10,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="320"/><ColumnDefinition/></Grid.ColumnDefinitions><TextBlock Text="{DynamicResource FilterList}" VerticalAlignment="Center" Margin="0,0,10,0" Foreground="#CBD5E1"/><TextBox x:Name="InstalledFilterBox" Grid.Column="1" ToolTip="{DynamicResource FilterTip}"/></Grid>
        <DataGrid x:Name="InstalledGrid" Grid.Row="2" Margin="0,10"><DataGrid.Columns><DataGridTemplateColumn Header="{DynamicResource Select}" Width="60"><DataGridTemplateColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding Selected, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" HorizontalAlignment="Center" VerticalAlignment="Center"/></DataTemplate></DataGridTemplateColumn.CellTemplate></DataGridTemplateColumn><DataGridTextColumn Header="{DynamicResource Name}" Binding="{Binding Name}" Width="2*"/><DataGridTextColumn Header="{DynamicResource PackageId}" Binding="{Binding Id}" Width="2*"/><DataGridTextColumn Header="{DynamicResource VersionColumn}" Binding="{Binding Version}" Width="*"/><DataGridTextColumn Header="{DynamicResource Source}" Binding="{Binding Source}" Width="*"/></DataGrid.Columns></DataGrid>
        <TextBlock Grid.Row="3" Text="{DynamicResource InstalledHint}" Foreground="#94A3B8"/>
      </Grid></TabItem>
      <TabItem Header="{DynamicResource TabImport}"><Grid Margin="14"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <Grid><TextBlock x:Name="ImportCount" Text="{DynamicResource ImportNotLoaded}" FontSize="17" FontWeight="SemiBold" VerticalAlignment="Center"/><Button x:Name="ImportButton" Content="{DynamicResource ChooseBackup}" HorizontalAlignment="Right"/></Grid>
        <DataGrid x:Name="ImportGrid" Grid.Row="1" Margin="0,12"><DataGrid.Columns><DataGridCheckBoxColumn Header="{DynamicResource Install}" Binding="{Binding Selected, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" Width="60"/><DataGridTextColumn Header="{DynamicResource Name}" Binding="{Binding Name}" Width="2*"/><DataGridTextColumn Header="{DynamicResource PackageId}" Binding="{Binding Id}" Width="2*"/><DataGridTextColumn Header="{DynamicResource Source}" Binding="{Binding Source}" Width="*"/></DataGrid.Columns></DataGrid>
        <Button x:Name="InstallImportedButton" Grid.Row="2" Content="{DynamicResource InstallChecked}" HorizontalAlignment="Right" Background="#059669"/>
      </Grid></TabItem>
      <TabItem Header="{DynamicResource TabSettings}"><ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="24" MaxWidth="650" HorizontalAlignment="Left">
        <TextBlock Text="{DynamicResource InterfaceLanguage}" FontSize="20" FontWeight="Bold" Margin="0,0,0,8"/><ComboBox x:Name="InterfaceLanguageCombo" Width="220" HorizontalAlignment="Left"><ComboBoxItem Content="繁體中文" Tag="zh-TW"/><ComboBoxItem Content="English" Tag="en"/></ComboBox><TextBlock Text="{DynamicResource InterfaceLanguageHint}" Foreground="#94A3B8" TextWrapping="Wrap" Margin="4,8,4,0"/>
        <Separator Margin="0,18" Background="#334155"/><TextBlock Text="{DynamicResource InstallUpdate}" FontSize="20" FontWeight="Bold" Margin="0,0,0,12"/><CheckBox x:Name="SilentInstallCheck" Content="{DynamicResource SilentInstall}"/><CheckBox x:Name="SilentUpgradeCheck" Content="{DynamicResource SilentUpgrade}"/>
        <Separator Margin="0,18" Background="#334155"/><TextBlock Text="{DynamicResource DescriptionTranslation}" FontSize="20" FontWeight="Bold" Margin="0,0,0,12"/><CheckBox x:Name="AutoTranslateCheck" Content="{DynamicResource AutoTranslate}"/>
        <StackPanel Orientation="Horizontal" Margin="4,8"><TextBlock Text="{DynamicResource TargetLanguage}" Width="110" VerticalAlignment="Center"/><ComboBox x:Name="LanguageCombo" Width="220"><ComboBoxItem Content="繁體中文" Tag="zh-TW"/><ComboBoxItem Content="簡體中文" Tag="zh-CN"/><ComboBoxItem Content="日本語" Tag="ja"/><ComboBoxItem Content="한국어" Tag="ko"/><ComboBoxItem Content="English" Tag="en"/></ComboBox></StackPanel>
        <TextBlock Text="{DynamicResource TranslationPrivacy}" Foreground="#94A3B8" TextWrapping="Wrap" Margin="4,10"/>
        <Separator Margin="0,18" Background="#334155"/><TextBlock Text="{DynamicResource SharedExclusions}" FontSize="20" FontWeight="Bold" Margin="0,0,0,8"/><TextBlock Text="{DynamicResource ExclusionSettingsHint}" Foreground="#94A3B8" TextWrapping="Wrap" Margin="4,4,4,8"/><Button x:Name="ClearExclusionsButton" Content="{DynamicResource ClearExclusions}" Background="#DC2626" HorizontalAlignment="Left"/>
        <Separator Margin="0,18" Background="#334155"/><TextBlock Text="{DynamicResource DataLocation}" FontSize="20" FontWeight="Bold"/><TextBlock x:Name="SettingsPathText" Foreground="#94A3B8" TextWrapping="Wrap" Margin="4,10"/>
      </StackPanel></ScrollViewer></TabItem>
    </TabControl>
    <Border Grid.Row="2" Margin="0,12,0,0" Background="#111827" CornerRadius="6" Padding="12,8"><Grid><Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions><TextBlock x:Name="StatusText" Text="{DynamicResource Ready}" Foreground="#A7F3D0" TextTrimming="CharacterEllipsis"/><ProgressBar x:Name="BusyProgress" Grid.Column="1" Height="5" IsIndeterminate="True" Foreground="#38BDF8" Background="#253047" Visibility="Collapsed"/></Grid></Border>
  </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$script:Window = [Windows.Markup.XamlReader]::Load($reader)
foreach ($name in @('StatusText','BusyProgress','MainTabs','AboutButton','AboutPopup','CloseAboutButton','HeaderVersionText','AboutVersionText','EmailLink','WebsiteLink','WingetBadge','WingetBadgeText','SearchBox','SearchButton','SearchGrid','SearchDescription','InstallButton','UpgradeCount','UpgradeFilterBox','RefreshUpgradeButton','ExcludeUpgradeButton','UpgradeSelectedButton','UpgradeAllButton','UpgradeGrid','InstalledCount','InstalledFilterBox','RefreshInstalledButton','ExcludeInstalledButton','ExportButton','UninstallButton','InstalledGrid','ImportCount','ImportButton','ImportGrid','InstallImportedButton','InterfaceLanguageCombo','SilentInstallCheck','SilentUpgradeCheck','AutoTranslateCheck','LanguageCombo','ClearExclusionsButton','SettingsPathText')) {
    Set-Variable -Scope Script -Name $name -Value $script:Window.FindName($name)
}

$script:WingetBadge.Background = if ($script:Winget) { '#FF064E3B' } else { '#FF7F1D1D' }
$script:AboutPopup.PlacementTarget = $script:Window
$script:AboutPopup.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Center
$script:SilentInstallCheck.IsChecked = [bool]$script:Settings.SilentInstall
$script:SilentUpgradeCheck.IsChecked = [bool]$script:Settings.SilentUpgrade
$script:AutoTranslateCheck.IsChecked = [bool]$script:Settings.AutoTranslate
$script:SettingsPathText.Text = $script:SettingsPath
foreach ($item in $script:LanguageCombo.Items) { if ($item.Tag -eq $script:Settings.TargetLanguage) { $script:LanguageCombo.SelectedItem = $item; break } }
if ($script:LanguageCombo.SelectedIndex -lt 0) { $script:LanguageCombo.SelectedIndex = 0 }
foreach ($item in $script:InterfaceLanguageCombo.Items) { if ($item.Tag -eq $script:Settings.InterfaceLanguage) { $script:InterfaceLanguageCombo.SelectedItem = $item; break } }
if ($script:InterfaceLanguageCombo.SelectedIndex -lt 0) { $script:InterfaceLanguageCombo.SelectedIndex = 1 }
Apply-InterfaceLanguage
Start-AsyncMonitor

$script:AboutButton.Add_Click({ $script:AboutPopup.IsOpen = $true })
$script:CloseAboutButton.Add_Click({ $script:AboutPopup.IsOpen = $false })
$script:EmailLink.Add_RequestNavigate({
    param($sender, $eventArgs)
    Start-Process $eventArgs.Uri.AbsoluteUri
    $eventArgs.Handled = $true
})
$script:WebsiteLink.Add_RequestNavigate({
    param($sender, $eventArgs)
    Start-Process $eventArgs.Uri.AbsoluteUri
    $eventArgs.Handled = $true
})

$script:InstalledContextMenu = [System.Windows.Controls.ContextMenu]::new()
$script:UninstallSingleMenuItem = [System.Windows.Controls.MenuItem]::new()
$script:UninstallSingleMenuItem.Header = Get-UiText 'RemoveSingle'
[void]$script:InstalledContextMenu.Items.Add($script:UninstallSingleMenuItem)
$script:InstalledGrid.ContextMenu = $script:InstalledContextMenu
$script:InstalledGrid.Add_PreviewMouseRightButtonDown({
    try {
        $row = [System.Windows.Controls.ItemsControl]::ContainerFromElement($script:InstalledGrid, [System.Windows.DependencyObject]$_.OriginalSource)
        if ($row -is [System.Windows.Controls.DataGridRow]) { $script:InstalledGrid.SelectedItem = $row.Item }
    } catch { }
})
$script:InstalledGrid.Add_ContextMenuOpening({
    $script:UninstallSingleMenuItem.IsEnabled = [bool]$script:InstalledGrid.SelectedItem
})
$script:InstalledGrid.Add_PreviewMouseLeftButtonDown({ Select-RowOnCheckboxClick $script:InstalledGrid ([System.Windows.DependencyObject]$_.OriginalSource) })

$script:UpgradeContextMenu = [System.Windows.Controls.ContextMenu]::new()
$script:UpgradeSingleMenuItem = [System.Windows.Controls.MenuItem]::new()
$script:UpgradeSingleMenuItem.Header = Get-UiText 'UpgradeSingle'
$script:UninstallUpgradeMenuItem = [System.Windows.Controls.MenuItem]::new()
$script:UninstallUpgradeMenuItem.Header = Get-UiText 'RemoveSingle'
[void]$script:UpgradeContextMenu.Items.Add($script:UpgradeSingleMenuItem)
[void]$script:UpgradeContextMenu.Items.Add([System.Windows.Controls.Separator]::new())
[void]$script:UpgradeContextMenu.Items.Add($script:UninstallUpgradeMenuItem)
$script:UpgradeGrid.ContextMenu = $script:UpgradeContextMenu
$script:UpgradeGrid.Add_PreviewMouseRightButtonDown({
    try {
        $row = [System.Windows.Controls.ItemsControl]::ContainerFromElement($script:UpgradeGrid, [System.Windows.DependencyObject]$_.OriginalSource)
        if ($row -is [System.Windows.Controls.DataGridRow]) { $script:UpgradeGrid.SelectedItem = $row.Item }
    } catch { }
})
$script:UpgradeGrid.Add_ContextMenuOpening({
    $script:UpgradeSingleMenuItem.IsEnabled = [bool]$script:UpgradeGrid.SelectedItem
    $script:UninstallUpgradeMenuItem.IsEnabled = [bool]$script:UpgradeGrid.SelectedItem
})
$script:UpgradeGrid.Add_PreviewMouseLeftButtonDown({ Select-RowOnCheckboxClick $script:UpgradeGrid ([System.Windows.DependencyObject]$_.OriginalSource) })
$script:AutoUpgradeSkipChangedHandler = [System.Windows.RoutedEventHandler]{
    param($sender, $eventArgs)
    $checkBox = $eventArgs.OriginalSource
    if ($checkBox -isnot [System.Windows.Controls.CheckBox] -or -not $checkBox.DataContext) { return }
    $binding = [System.Windows.Data.BindingOperations]::GetBinding($checkBox, [System.Windows.Controls.Primitives.ToggleButton]::IsCheckedProperty)
    if (-not $binding -or $binding.Path.Path -ne 'SkipAutoUpgrade') { return }
    $checkBox.DataContext.SkipAutoUpgrade = [bool]$checkBox.IsChecked
    Set-PackageAutoUpgradeSkip -Id ([string]$checkBox.DataContext.Id) -Skip ([bool]$checkBox.IsChecked)
}
$script:UpgradeGrid.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::CheckedEvent, $script:AutoUpgradeSkipChangedHandler)
$script:UpgradeGrid.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::UncheckedEvent, $script:AutoUpgradeSkipChangedHandler)

$script:SearchButton.Add_Click({ Search-Packages })
$script:SearchBox.Add_KeyDown({ if ($_.Key -eq 'Enter') { Search-Packages } })
$script:SearchGrid.Add_SelectionChanged({
    $package = $script:SearchGrid.SelectedItem
    if (-not $package) { return }
    $requestedId = $package.Id
    $script:SearchDescription.Text = Get-UiText 'LoadingDescription'
    $descriptionLoaded = {
        param($lines, $responseId)
        # Ignore a late response if the user selected another search result.
        if (-not $script:SearchGrid.SelectedItem -or $script:SearchGrid.SelectedItem.Id -ne $responseId) { return }
        $description = Get-PackageDescriptionFromLines $lines
        if ($script:Settings.AutoTranslate) {
            $translationLoaded = {
                param($translated, $translationId)
                if ($script:SearchGrid.SelectedItem -and $script:SearchGrid.SelectedItem.Id -eq $translationId) { $script:SearchDescription.Text = $translated }
            }
            Start-TranslationQuery $description $script:Settings.TargetLanguage $translationLoaded $responseId
        } else {
            $script:SearchDescription.Text = $description
            Set-Status (Get-UiText 'DescriptionLoaded')
        }
    }
    $descriptionFailed = {
        param($message, $responseId)
        if ($script:SearchGrid.SelectedItem -and $script:SearchGrid.SelectedItem.Id -eq $responseId) { $script:SearchDescription.Text = Get-UiText 'DescriptionFailed' @($message) }
    }
    Start-WingetQuery -Arguments @('show', '--id', $requestedId, '--exact', '--accept-source-agreements', '--disable-interactivity') -Activity (Get-UiText 'LoadingAppDescription' @($package.Name)) -OnSuccess $descriptionLoaded -OnFailure $descriptionFailed -State $requestedId
})
$script:InstallButton.Add_Click({
    $package = $script:SearchGrid.SelectedItem
    if (-not $package) { Set-Status (Get-UiText 'SelectInstall') $true; return }
    $args = @('install','--id', $package.Id, '--exact','--accept-package-agreements','--accept-source-agreements','--disable-interactivity')
    if ($script:Settings.SilentInstall) { $args += '--silent' }
    Start-WingetAction $args (Get-UiText 'InstallActivity' @($package.Name))
})
$script:RefreshUpgradeButton.Add_Click({ Refresh-Upgrades })
$script:RefreshInstalledButton.Add_Click({ Refresh-Installed })
$script:UpgradeFilterBox.Add_TextChanged({ Apply-PackageListFilter Upgrade })
$script:InstalledFilterBox.Add_TextChanged({ Apply-PackageListFilter Installed })
$script:ExcludeUpgradeButton.Add_Click({ Add-PackagesToExclusions -Grid $script:UpgradeGrid -ListKind Upgrade })
$script:ExcludeInstalledButton.Add_Click({ Add-PackagesToExclusions -Grid $script:InstalledGrid -ListKind Installed })
$script:UpgradeSelectedButton.Add_Click({
    $selected = @($script:UpgradeApps | Where-Object Selected)
    if (-not $selected.Count) { Set-Status (Get-UiText 'SelectUpgrade') $true; return }
    foreach ($package in $selected) {
        $args = @('upgrade','--id',$package.Id,'--exact','--accept-package-agreements','--accept-source-agreements','--disable-interactivity')
        if ($script:Settings.SilentUpgrade) { $args += '--silent' }
        Start-WingetAction $args (Get-UiText 'UpgradeActivity' @($package.Name))
    }
})
$script:UpgradeAllButton.Add_Click({
    $targets = @($script:UpgradeApps | Where-Object { -not $_.Excluded -and -not $_.SkipAutoUpgrade })
    if (-not $targets.Count) { Set-Status (Get-UiText 'NoAutoUpgrade') $true; return }
    $script:ImportedApps = @($targets | ForEach-Object { [pscustomobject]@{ Id = $_.Id } })
    $silent = [bool]$script:Settings.SilentUpgrade
    $commands = foreach ($package in $targets) {
        $extra = if ($silent) { '--silent' } else { '' }
        "& '$($script:Winget.Replace("'", "''"))' upgrade --id '$($package.Id.Replace("'", "''"))' --exact --accept-package-agreements --accept-source-agreements --disable-interactivity $extra"
    }
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(($commands -join "`r`n")))
    Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-EncodedCommand',$encoded) -WindowStyle Normal | Out-Null
    Set-Status (Get-UiText 'UpgradesStarted' @($targets.Count))
})
$script:ExportButton.Add_Click({ Export-PackageList })
$script:ImportButton.Add_Click({ Import-PackageList })
$script:InstallImportedButton.Add_Click({ Install-ImportedPackages })
$script:UninstallButton.Add_Click({
    try { $script:InstalledGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true) | Out-Null } catch { }
    $selected = @($script:InstalledApps | Where-Object Selected)
    if (-not $selected.Count) { Set-Status (Get-UiText 'SelectRemove') $true; return }
    Start-SequentialUninstall $selected
})
$script:UninstallSingleMenuItem.Add_Click({
    $package = $script:InstalledGrid.SelectedItem
    if (-not $package) { Set-Status (Get-UiText 'RightClickApp') $true; return }
    $answer = [System.Windows.MessageBox]::Show($script:Window, (Get-UiText 'RemoveOneConfirm' @($package.Name)), $script:AppName, 'YesNo', 'Warning')
    if ($answer -eq 'Yes') { Start-WingetAction @('uninstall','--id',$package.Id,'--exact','--disable-interactivity') (Get-UiText 'RemoveActivity' @($package.Name)) }
})
$script:UpgradeSingleMenuItem.Add_Click({
    $package = $script:UpgradeGrid.SelectedItem
    if (-not $package) { Set-Status (Get-UiText 'RightClickApp') $true; return }
    $args = @('upgrade','--id',$package.Id,'--exact','--accept-package-agreements','--accept-source-agreements','--disable-interactivity')
    if ($script:Settings.SilentUpgrade) { $args += '--silent' }
    Start-WingetAction $args (Get-UiText 'UpgradeActivity' @($package.Name))
})
$script:UninstallUpgradeMenuItem.Add_Click({
    $package = $script:UpgradeGrid.SelectedItem
    if (-not $package) { Set-Status (Get-UiText 'RightClickApp') $true; return }
    $answer = [System.Windows.MessageBox]::Show($script:Window, (Get-UiText 'RemoveOneConfirm' @($package.Name)), $script:AppName, 'YesNo', 'Warning')
    if ($answer -eq 'Yes') { Start-WingetAction @('uninstall','--id',$package.Id,'--exact','--disable-interactivity') (Get-UiText 'RemoveActivity' @($package.Name)) }
})
$script:SilentInstallCheck.Add_Checked({ $script:Settings.SilentInstall = $true; Save-AppSettings })
$script:SilentInstallCheck.Add_Unchecked({ $script:Settings.SilentInstall = $false; Save-AppSettings })
$script:SilentUpgradeCheck.Add_Checked({ $script:Settings.SilentUpgrade = $true; Save-AppSettings })
$script:SilentUpgradeCheck.Add_Unchecked({ $script:Settings.SilentUpgrade = $false; Save-AppSettings })
$script:AutoTranslateCheck.Add_Checked({ $script:Settings.AutoTranslate = $true; Save-AppSettings })
$script:AutoTranslateCheck.Add_Unchecked({ $script:Settings.AutoTranslate = $false; Save-AppSettings })
$script:LanguageCombo.Add_SelectionChanged({ if ($script:LanguageCombo.SelectedItem) { $script:Settings.TargetLanguage = [string]$script:LanguageCombo.SelectedItem.Tag; Save-AppSettings } })
$script:InterfaceLanguageCombo.Add_SelectionChanged({
    if (-not $script:InterfaceLanguageCombo.SelectedItem) { return }
    $language = [string]$script:InterfaceLanguageCombo.SelectedItem.Tag
    if ($language -eq $script:Settings.InterfaceLanguage) { return }
    $script:Settings.InterfaceLanguage = $language
    Save-AppSettings
    Apply-InterfaceLanguage
    Set-Status (Get-UiText 'LanguageChanged')
})
$script:ClearExclusionsButton.Add_Click({ Clear-AllExclusions })
$script:Window.Add_ContentRendered({
    if (-not $script:Winget) {
        Set-Status (Get-UiText 'WingetRequired') $true
        return
    }
    # The first scan is automatic; the buttons remain available for later refreshes.
    Refresh-Upgrades
    Refresh-Installed
})
$script:Window.Add_Closing({
    if ($script:AsyncTimer) { $script:AsyncTimer.Stop() }
    foreach ($operation in @($script:AsyncOperations)) {
        try {
            if ($operation.Kind -eq 'Process' -and -not $operation.Process.HasExited) { $operation.Process.Kill() }
            elseif ($operation.Kind -eq 'Translation') { $operation.Client.CancelAsync(); $operation.Client.Dispose() }
        } catch { }
    }
})

$script:Window.ShowDialog() | Out-Null
