# Changelog / 更新紀錄

## 0.1.8 — 2026-08-13

Application identity icon / 應用程式識別圖示

- Add a custom blue package-and-download icon based on concept 01
- Provide a transparent 1024-pixel PNG master and a multi-size Windows ICO
- Embed the icon into the portable executable and use it for Setup, shortcuts, and uninstall display

---

- 採用第 1 組藍色套件與下載箭頭圖示
- 提供透明背景 1024px PNG 主圖及 Windows 多尺寸 ICO
- 將圖示嵌入可攜版 EXE，並套用至安裝程式、捷徑及解除安裝顯示

---

## 0.1.7 — 2026-08-13

Winget data collection and runtime diagnostics / Winget 資料收集與運行診斷修正

- Decode captured Winget standard output and error output as UTF-8
- Parse package columns by stable ordinal positions when localized header names are unknown
- Accept both ASCII and Unicode Winget table separators
- Treat unrecognized successful output as a parsing error instead of reporting a misleading zero-result scan
- Write daily runtime logs for startup, Winget commands, exit codes, output summaries, and errors
- Add an Open log folder button to Settings; retain logs for 14 days and fall back to LocalAppData when the app directory is not writable
- Provide a complete per-machine installer alongside the portable EXE and ZIP, including shortcuts and standard uninstall support
- Store installed-edition settings and logs under LocalAppData while preserving beside-the-EXE storage for portable use

---

- 強制使用 UTF-8 解碼 Winget 標準輸出與錯誤輸出
- 無法識別本地化欄名時，依 Winget 穩定的欄位順序解析套件資料
- 同時支援 ASCII 與 Unicode Winget 表格分隔線
- 成功執行但輸出格式無法辨識時改為明確解析錯誤，不再誤報掃描結果為零筆
- 每日記錄啟動資訊、Winget 命令、結束碼、輸出摘要與錯誤
- 設定頁新增「開啟 Log 資料夾」；Log 保留 14 天，程式目錄不可寫入時自動改存 LocalAppData
- 除可攜 EXE 與 ZIP 外，同時提供完整的電腦安裝版本，包含捷徑與標準解除安裝功能
- 安裝版設定與 Log 儲存在 LocalAppData，可攜版則繼續儲存在 EXE 旁

---

## 0.1.6 — 2026-08-12

Read-only package lists and column alignment / 唯讀套件清單與欄位對齊

- Center the Select and Skip auto update column headers over their checkbox cells
- Mark all package-list text columns as read-only to prevent meaningless double-click editing
- Keep selection, skip-update, and import-install checkbox columns interactive
- Add a single-item Add to exclusions command at the bottom of the Updates and Installed Apps context menus
- Expand WPF UI smoke coverage for text-column editability and checkbox-column behavior

---

- 將「選取」及「不自動更新」欄位標題置中顯示，與欄內核取方塊對齊
- 所有套件清單文字欄位改為唯讀，避免雙擊進入沒有實際用途的編輯狀態
- 保留選取、不自動更新及匯入安裝核取方塊的正常操作
- 軟體更新與已安裝程式管理右鍵選單末端新增單一項目「加入排除項目」功能
- 擴充 WPF 介面測試，驗證文字欄位唯讀且核取方塊仍可操作

---

## 0.1.5 — 2026-08-12

Windows PowerShell 5.1 encoding compatibility / Windows PowerShell 5.1 編碼相容性修正

- Write the embedded application script as UTF-8 with BOM when extracting it from the packaged executable
- Prevent Windows PowerShell 5.1 from interpreting Traditional Chinese source text through the active ANSI code page
- Add an end-to-end packaged-resource test for the BOM, preserved Traditional Chinese text, and PowerShell parser validity

---

- 封裝版執行檔抽出內嵌主程式時，固定寫入 UTF-8 BOM
- 避免 Windows PowerShell 5.1 使用系統 ANSI 字碼頁解讀繁體中文原始碼
- 新增端對端封裝資源測試，驗證 BOM、繁體中文內容及 PowerShell 語法完整性

---

## 0.1.4 — 2026-08-09

Startup diagnostics and visible failure reporting / 啟動診斷與可見錯誤回報

- Capture PowerShell standard output and error output in the packaged launcher
- Detect non-zero PowerShell exit codes and display a bilingual startup error
- Write detailed startup diagnostics to the user's local application data directory, with a temporary-directory fallback
- Resolve and validate the built-in Windows PowerShell executable before launch
- Add a user-triggered online updater to the About popup using the latest public GitHub release
- Download EXE or Windows ZIP assets, validate the version and PE header, and recheck SHA-256 immediately before replacement
- Replace the running executable through a separate encoded update process, restart automatically, and restore the previous executable if replacement fails
- Request UAC consent automatically when the executable directory is not writable

---

- 封裝版啟動器會捕捉 PowerShell 標準輸出與錯誤輸出
- 偵測非零 PowerShell 結束代碼並顯示雙語啟動錯誤
- 將完整啟動診斷寫入使用者本機應用程式資料夾，失敗時改用暫存資料夾
- 啟動前明確解析並驗證系統內建 Windows PowerShell 執行檔
- 關於頁面新增由使用者觸發的線上更新，使用 GitHub 最新公開版本
- 支援下載 EXE 或 Windows ZIP，驗證版本與 PE 標頭，並在替換前再次核對 SHA-256
- 由獨立編碼更新程序替換執行中的 EXE、自動重新啟動，替換失敗時回復原執行檔
- 執行檔目錄不可寫入時自動要求 UAC 授權

---

## 0.1.3 — 2026-07-18

Single-instance, interaction guidance, and interface-contrast update / 單一執行、互動提醒與介面對比更新

- Single-instance guards for both the packaged executable and direct PowerShell launch
- Update and removal reminders when a separate installer or uninstaller may require manual interaction
- Dedicated scrollable error-report window for installation and update failures
- More prominent Upgrade all primary action
- Custom high-contrast selected-tab template without hover color changes
- Correct settings-page text inheritance and tighter section spacing
- Expanded smoke coverage for startup guards and WPF XAML loading

---

- EXE 與直接執行 PowerShell 版本皆加入單一執行個體保護
- 更新與移除可能需要操作獨立視窗時，開始前主動提醒
- 安裝與更新失敗改用可捲動的獨立錯誤報告視窗
- 強化「一鍵全部升級」主要操作的尺寸與視覺層級
- 使用自訂高對比頁籤範本，並取消游標滑入變色
- 修正設定頁文字顏色繼承並縮減區塊間距
- 增加啟動保護與 WPF XAML 載入測試

## 0.1.2 — 2026-07-18

Background task feedback and operation-safety update / 背景作業回饋與操作安全更新

- Optional hidden-window execution for installation and updates, matching the removal workflow
- Overall progress for single and batch installation, update, and removal operations
- Automatic action locking for buttons and context-menu commands while a task is active
- Automatic list rescanning after installation, update, and removal completes
- More reliable removal with exact-name fallback when package-ID removal fails
- Clearable error status and improved bilingual task feedback

---

- 安裝與更新可選擇隱藏執行視窗，操作方式與移除流程一致
- 單一及批次安裝、更新、移除皆顯示整體進度
- 工作執行期間自動鎖定相關按鈕與右鍵功能，避免重複操作
- 安裝、更新與移除完成後自動重新掃描相關清單
- 套件識別碼移除失敗時改用程式名稱重試，提高移除成功率
- 移除失敗訊息可清除，並改善中英文背景作業回饋

## 0.1.0 — 2026-07-17

Initial public release / 首次公開版本

- Graphical Winget search, installation, upgrade, and removal
- Background scanning and responsive WPF interface
- Per-app automatic-upgrade skip and shared hidden exclusion list
- Portable settings, import/export, and sequential batch operations
- Traditional Chinese and English interface
- Single-file Windows executable and source-mode launchers

---

- Winget 圖形化搜尋、安裝、更新與移除
- 背景掃描與不凍結的 WPF 操作介面
- 個別程式不自動更新，以及兩份清單共用的隱藏排除清單
- 可攜式設定、匯入匯出與循序批次作業
- 繁體中文與英文介面
- 單一 Windows 執行檔與原始碼啟動器
