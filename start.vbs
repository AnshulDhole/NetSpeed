Set shell = CreateObject("WScript.Shell")
scriptDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
shell.Run "powershell.exe -ExecutionPolicy Bypass -NoProfile -File """ & scriptDir & "\netspeed.ps1""", 0, False
