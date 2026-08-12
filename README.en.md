# Easy WinGet Plus

**English** | [繁體中文](README.md)

Easy WinGet Plus is a portable graphical software manager for Windows. It uses the built-in Windows Package Manager (Winget) to search, install, update, remove, and back up application lists.

**Free to use, ad-free, and open source.**

Current version: **0.1.6**

## What's new in 0.1.6

- Centered the Select and Skip auto update column headers to align with their checkboxes
- Made name, package ID, version, and source columns read-only so double-clicking no longer enters a meaningless text-editing state
- Preserved normal interaction for selection, skip-update, and import-install checkboxes
- Added Add to exclusions at the bottom of the Updates and Installed Apps context menus; it excludes only the app that was right-clicked

## What's new in 0.1.5

- Fixed the packaged PowerShell script missing a UTF-8 BOM, which made Windows PowerShell 5.1 interpret Traditional Chinese as ANSI and fail during parsing
- Added a packaged-script encoding test that extracts the resource from the EXE and validates its BOM, Traditional Chinese text, and PowerShell syntax

## What's new in 0.1.4

- Fixed hidden PowerShell or WPF startup failures that could make the application appear to do nothing
- Startup failures now show bilingual error details and the PowerShell exit code
- Full startup diagnostics are written to `%LOCALAPPDATA%\EasyWinGetPlus\Logs`
- The launcher explicitly checks for Windows PowerShell and uses `%TEMP%` as a fallback diagnostic location
- Added Online update to the About popup for automatic GitHub release download, in-place replacement, and restart
- Protected install locations automatically request UAC consent; updates are checked by version, PE header, and SHA-256 before replacement

## What's new in 0.1.3

- Prevent duplicate application windows with single-instance startup protection
- Warn before updates and removals that a separate installer or uninstaller window may require manual interaction
- Show installation and update failures in a dedicated, scrollable error-report window with a Close button
- Enlarge and visually emphasize the primary Upgrade all button
- Redesign selected-tab styling for clearer active-state and content contrast
- Fix inherited heading colors and reduce excess spacing on the Settings page

## Features

- Search Winget sources by keyword, view descriptions, and install apps
- Optionally translate app descriptions into a selected target language
- Scan recognized installed apps and available updates in the background without freezing the interface
- Upgrade checked apps manually or upgrade every app that allows automatic updates
- Mark individual updates as “Skip auto update”: they remain visible and can still be upgraded manually
- Share one hidden exclusion list between the Updates and Installed Apps views
- Filter lists by name, package ID, version, or source without losing checked selections
- Export selected installed apps and import the list for batch installation on another PC
- Remove checked apps sequentially, or right-click to upgrade or remove one app
- Show overall progress for installation, update, and removal while locking related actions to prevent duplicate execution
- Automatically rescan update and installed-app lists after tasks finish
- Prevent multiple main windows and warn when an update or removal may require user interaction
- Show installation and update failures in a dedicated, scrollable, closable error-report window
- Keep all settings beside the program for portable use
- Update online from the About popup; the app replaces itself and restarts automatically after download
- Traditional Chinese and English interface with a manual first-launch language choice

## Interface preview

### Software updates

Scan for available updates, upgrade checked apps or all eligible apps, add shared hidden exclusions, and use the right-side checkbox to skip an app during automatic upgrades.

![Easy WinGet Plus software updates](軟體畫面/軟體更新.jpg)

### Search, installation, and description translation

Search Winget sources by keyword and select a result to view its description. When translation is enabled, the description is shown in the configured target language.

![Easy WinGet Plus search, installation, and description translation](軟體畫面/搜尋與安裝，支援翻譯.jpg)

### Installed app management

Browse and filter installed apps recognized by Winget, export checked apps, remove them sequentially, manage shared exclusions, or right-click to remove one app.

![Easy WinGet Plus installed app management](軟體畫面/以安裝程式管理.jpg)

### Import and batch installation

Load a previously exported backup, uncheck unwanted entries, and install the remaining apps in sequence—useful for setting up a new PC or sharing an app collection.

![Easy WinGet Plus import and batch installation](軟體畫面/匯入安裝.jpg)

### Portable settings

Switch the interface language, configure silent installation and updates, enable description translation, and manage exclusions shared by both lists. Changes are saved automatically.

![Easy WinGet Plus settings](軟體畫面/設定.jpg)

## Requirements

- Windows 10 version 1809 or later, or Windows 11
- Windows PowerShell 5.1
- `winget.exe`, supplied by Microsoft App Installer
- Access to GitHub and GitHub Releases when using Online update

Windows 11 normally includes Winget. If the app reports that Winget is missing, install or update **App Installer** from the Microsoft Store.

## Download and run

1. Open [Releases](https://github.com/ahui3c/EasyWinGetPlus/releases) and download `EasyWinGetPlus.exe`.
2. Put the executable in a folder where you have write access.
3. Double-click it and choose Traditional Chinese or English on first launch.

The executable is not commercially code-signed. Windows SmartScreen may display an unknown-publisher warning. Confirm that the file came from this repository before deciding whether to run it.

## Run from source

Download or clone the repository, then double-click:

```text
Start-EasyWinGetPlus.vbs
```

You can also launch it from PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\EasyWinGetPlus.ps1
```

## Build the executable

The build requires no downloaded packages. It uses the .NET Framework C# compiler included with Windows:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

The output is `dist\EasyWinGetPlus.exe`. The executable embeds the complete PowerShell/WPF application and starts without a visible console window.

## Portable data

The app creates this file beside the executable or main script:

```text
EasyWinGetPlus.settings.json
```

It stores the interface and translation languages, silent-mode choices, automatic-update skip list, hidden exclusions, and last export location. This personal file is excluded through `.gitignore`.

## Privacy

- No translation service is contacted unless description translation is enabled.
- When enabled, up to 450 characters of an app description are sent to the public MyMemory translation service.
- The app contacts GitHub Releases only when the user presses Online update, to check and download a public release.
- Exported installation lists contain package IDs, names, and sources only; they do not contain a Windows account or device identifier.

## License

This project is licensed under the [MIT License](LICENSE). You may freely use, modify, and distribute it under the license terms.

## Author

- 廖阿輝
- Email: <chehui@gmail.com>
- Website: [https://ahui3c.com](https://ahui3c.com)
