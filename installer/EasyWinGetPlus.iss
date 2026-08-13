#define MyAppName "Easy WinGet Plus"
#define MyAppVersion "0.1.8"
#define MyAppPublisher "廖阿輝"
#define MyAppURL "https://github.com/ahui3c/EasyWinGetPlus"
#define MyAppExeName "EasyWinGetPlus.exe"

[Setup]
AppId={{73C714AA-D55A-49E7-B604-8B5030107EC9}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={autopf64}\Easy WinGet Plus
DefaultGroupName=Easy WinGet Plus
DisableProgramGroupPage=yes
LicenseFile=..\LICENSE
OutputDir=..\release
OutputBaseFilename=EasyWinGetPlus-v{#MyAppVersion}-Setup-x64
SetupIconFile=..\assets\icons\EasyWinGetPlus.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no
MinVersion=10.0.17763
VersionInfoVersion={#MyAppVersion}.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} installer
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\dist\EasyWinGetPlus.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "EasyWinGetPlus.installed"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Easy WinGet Plus"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,Easy WinGet Plus}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Easy WinGet Plus"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,Easy WinGet Plus}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: files; Name: "{app}\EasyWinGetPlus.installed"
