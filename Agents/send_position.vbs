Set objShell = CreateObject("Wscript.Shell")
objShell.Run "cmd /c powershell -NoProfile -ExecutionPolicy Bypass -File ""position.ps1""", 0, False

