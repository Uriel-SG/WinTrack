Set objShell = CreateObject("Wscript.Shell")
objShell.Run "cmd /c powershell -NoProfile -ExecutionPolicy Bypass -File ""C:\ProgramData\wintrack\position.ps1""", 0, False


