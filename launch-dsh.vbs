' DeepSeek Harness one-click launcher wrapper (portable).
' Uses wscript (no console window) to launch the PowerShell launcher hidden,
' so double-clicking does not flash a black box. The service's own console
' window is opened by the PowerShell script.
' Auto-locates launch-dsh.ps1 in the same folder as this .vbs file.
Option Explicit
Dim fso, sh, folder, ps1
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")
folder = fso.GetParentFolderName(WScript.ScriptFullName)
ps1    = fso.BuildPath(folder, "launch-dsh.ps1")
sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1 & """", 0, False
