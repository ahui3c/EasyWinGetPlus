Option Explicit

Dim shell, fileSystem, scriptDirectory, command
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

scriptDirectory = fileSystem.GetParentFolderName(WScript.ScriptFullName)
command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File """ _
    & scriptDirectory & "\EasyWinGetPlus.ps1"""

' Window style 0 keeps the PowerShell console hidden while WPF remains visible.
If WScript.Arguments.Named.Exists("validate") Then
    WScript.Echo command
Else
    shell.Run command, 0, False
End If
