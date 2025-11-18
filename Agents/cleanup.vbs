Set objShell = CreateObject("Wscript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -File ""C:\ProgramData\wintrack\cleanup_pending.ps1""", 0, False

