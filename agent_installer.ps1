# =====================================================================
#  WinTrack – Agent Installer Script
#  Scarica la cartella "Agents" dalla repository GitHub
#  Ne copia il contenuto in C:\Program\Data\wintrack
#  Crea due Scheduled Tasks:
#     - WinTrack-Tracker  (ogni 10 min, delay 2 min)
#     - WinTrack-Cleanup  (ogni 20 min, delay 11 min)
# =====================================================================

Write-Host "[*] Avvio installazione WinTrack..."

# -------------------------------
# 1) Preparazione percorso temporaneo
# -------------------------------
$tmp = Join-Path $env:TEMP ("wintrack_" + [guid]::NewGuid().ToString())
New-Item -Path $tmp -ItemType Directory | Out-Null

Write-Host "[*] Cartella temporanea creata: $tmp"

# -------------------------------
# 2) Download della repository ZIP da GitHub
# -------------------------------
$zip = Join-Path $tmp "repo.zip"
$repoUrl = "https://github.com/Uriel-SG/WinTrack/archive/refs/heads/main.zip"

Write-Host "[*] Download della repository GitHub..."
Invoke-WebRequest -Uri $repoUrl -OutFile $zip -UseBasicParsing

# -------------------------------
# 3) Estrazione ZIP
# -------------------------------
Write-Host "[*] Estrazione dello ZIP..."
Expand-Archive -Path $zip -DestinationPath $tmp -Force

# Trova la cartella della repo estratta (WinTrack-main)
$repoDir = Get-ChildItem -Path $tmp -Directory | Where-Object { $_.Name -like "WinTrack-*" } | Select-Object -First 1

if (-not $repoDir) {
    Write-Error "!!! ERRORE: impossibile trovare la cartella della repository estratta."
    exit 1
}

Write-Host "[*] Repository estratta: $($repoDir.FullName)"

# -------------------------------
# 4) Copia cartella Agents → C:\ProgramData\wintrack
# -------------------------------
$agentsSrc = Join-Path $repoDir.FullName "Agents"
$dest = "C:\ProgramData\wintrack"

Write-Host "[*] Creazione cartella finale: $dest"
New-Item -Path $dest -ItemType Directory -Force | Out-Null

if (Test-Path $agentsSrc) {
    Write-Host "[*] Copia dei file Agents → wintrack..."
    Copy-Item -Path (Join-Path $agentsSrc "*") -Destination $dest -Recurse -Force
} else {
    Write-Warning "!!! ATTENZIONE: Cartella 'Agents' NON trovata nella repository!"
}

# -------------------------------
# 5) Elimina cartella temporanea
# -------------------------------
Write-Host "[*] Pulizia cartella temporanea..."
Remove-Item -Path $tmp -Recurse -Force


# -------------------------------
# 6) Richiesta URL e modifica position.ps1
# -------------------------------
Write-Host "[*] Configurazione URL per position.ps1..."
$customUrl = Read-Host "Inserisci l'URL completo (includi http:// o https://)"

if ($customUrl -notmatch '^https?://') {
    Write-Warning "!!! ATTENZIONE: L'URL deve iniziare con http:// o https://"
    exit 1
}

$positionFile = Join-Path $dest "position.ps1"

if (Test-Path $positionFile) {
    Write-Host "[*] Aggiornamento del file position.ps1 con l'URL fornito..."
    (Get-Content $positionFile) -replace '<YOUR-URL-HERE>', $customUrl | Set-Content $positionFile
    Write-Host "[OK] URL aggiornato correttamente in position.ps1"
} else {
    Write-Warning "!!! ATTENZIONE: Il file position.ps1 non è stato trovato in $dest"
}


# -------------------------------
# 7) Richiesta API KEY e impostazione variabile ambiente
# -------------------------------
Write-Host "[*] Configurazione API Key..."
$apiKey = Read-Host "Inserisci la API Key fornita dall'amministratore"

if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Error "!!! ERRORE: API Key non valida."
    exit 1
}

Write-Host "[*] Imposto variabile ambiente di sistema WINTRACK_API_KEY..."
setx WINTRACK_API_KEY "$apiKey" /M | Out-Null

Write-Host "[OK] API Key salvata come variabile ambiente di sistema."

# -------------------------------
# 8) Configura l'utilità di pianificazione
# -------------------------------
Write-Host "[*] Configurazione Utilità di Pianificazione..."

$action = New-ScheduledTaskAction -Execute "C:\ProgramData\wintrack\tracker.bat"
$triggerA = New-ScheduledTaskTrigger -AtStartup
$startTime = (Get-Date).AddMinutes(2)
$triggerB = New-ScheduledTaskTrigger -Once -At $startTime -RepetitionInterval (New-TimeSpan -Minutes 10)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$task = New-ScheduledTask -Action $action -Trigger $triggerA,$triggerB -Principal $principal -Settings $settings
Register-ScheduledTask -TaskName "Wintrack-Tracker" -InputObject $task

$action = New-ScheduledTaskAction -Execute "C:\ProgramData\wintrack\cleanup.bat"
$triggerA = New-ScheduledTaskTrigger -AtStartup
$startTime = (Get-Date).AddMinutes(11)
$triggerB = New-ScheduledTaskTrigger -Once -At $startTime -RepetitionInterval (New-TimeSpan -Minutes 20)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$task = New-ScheduledTask -Action $action -Trigger $triggerA,$triggerB -Principal $principal -Settings $settings
Register-ScheduledTask -TaskName "Wintrack-Cleanup" -InputObject $task

# -------------------------------
# Fine
# -------------------------------
Write-Host ""
Write-Host "[OK] Installazione completata!"
Write-Host "[OK] Cartella WinTrack: $dest"
Write-Host "[OK] Task creati: WinTrack-Tracker, WinTrack-Cleanup"
Write-Host ""
