Set objShell = CreateObject("Wscript.Shell")
objShell.Run "cmd /c powershell -NoProfile -ExecutionPolicy Bypass -File ""GEO_python.ps1""", 0, False
