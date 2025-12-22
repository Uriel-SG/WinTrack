# --------------------------------------------------------------------------
# WinTrack Client Script (PowerShell)
# --------------------------------------------------------------------------

# Se connessione https -> TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 1. Caricamento variabili d'ambiente
$authUsername = $env:WINTRACK_AUTH_USER
$authPassword = $env:WINTRACK_AUTH_PASS
$apiKey       = $env:WINTRACK_API_KEY

if (-not $authUsername -or -not $authPassword) {
    Write-Error "Variabili d'ambiente WINTRACK_AUTH_USER o WINTRACK_AUTH_PASS non trovate. Impostale."
    exit 1
}
if (-not $apiKey) {
    Write-Error "Variabile d'ambiente WINTRACK_API_KEY non trovata. Impostala."
    exit 1
}

# 2. Header e Auth (Standard Curl-Like)
$authBytes  = [System.Text.Encoding]::ASCII.GetBytes("${authUsername}:${authPassword}")
$authBase64 = [Convert]::ToBase64String($authBytes)

$headers = @{
    "X-API-Key"     = $apiKey
    "Authorization" = "Basic $authBase64"
}

# 3. Ottenimento Posizione (Con attesa dinamica per precisione)
Add-Type -AssemblyName System.Device
$geo = New-Object System.Device.Location.GeoCoordinateWatcher
$geo.Start()

$timeout = 10
while ($geo.Status -ne 'Ready' -and $timeout -gt 0) {
    Start-Sleep -Seconds 1
    $timeout--
}

$pos = $geo.Position
$lat = [double]$pos.Location.Latitude
$lon = [double]$pos.Location.Longitude
$geo.Stop()

# Controllo validità prima di inviare
if ($pos.Location.IsUnknown -or $lat -eq 0 -or $lon -eq 0) {
    Write-Warning "Geolocalizzazione non valida. Salto invio."
    exit
}

$timestamp = (Get-Date).ToString("dd-MM-yyyy HH:mm")

# 4. Body JSON
$body = @{
    device    = $env:COMPUTERNAME
    lat       = $lat
    lon       = $lon
    timestamp = $timestamp
} | ConvertTo-Json

# 5. Invio con BYPASS PROXY e Basic Parsing
try {
    $response = Invoke-WebRequest `
        -Uri "<YOUR-URL-HERE>/update_position" `
        -Method POST `
        -Body $body `
        -ContentType "application/json" `
        -Headers $headers `
        -TimeoutSec 15 `
        -Proxy $null `
        -UseBasicParsing `

    if ($response.StatusCode -eq 200) {
        Write-Host "Inviato con successo per $($env:COMPUTERNAME) alle $timestamp" -ForegroundColor Green
    }
}
catch {
    Write-Host "FALLITO: $($_.Exception.Message)" -ForegroundColor Red
}

exit
