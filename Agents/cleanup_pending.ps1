# Nome del processo o parte del comando da cercare
$scriptName = "GEO_python.ps1"

# Ottieni tutti i processi PowerShell
$psProcesses = Get-Process powershell -ErrorAction SilentlyContinue

foreach ($p in $psProcesses) {
    try {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)").CommandLine
        if ($cmdLine -match $scriptName) {
            Write-Host "Terminando processo $($p.Id) che esegue $scriptName"
            Stop-Process -Id $p.Id -Force
        }
    } catch {
        # ignora eventuali errori
    }
}
