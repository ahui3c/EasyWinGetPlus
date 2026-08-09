# Changelog / 更新紀錄

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
