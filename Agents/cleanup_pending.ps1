$scriptName = "position.ps1"

$psProcesses = Get-Process powershell -ErrorAction SilentlyContinue

foreach ($p in $psProcesses) {
    try {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)").CommandLine
        if ($cmdLine -match $scriptName) {
            Write-Host "Terminando processo $($p.Id) che esegue $scriptName"
            Stop-Process -Id $p.Id -Force
        }
    } catch {
        # ignorare eventuali errori
    }
}

