$authUsername = $env:WINTRACK_AUTH_USER
$authPassword = $env:WINTRACK_AUTH_PASS
$apiKey = $env:WINTRACK_API_KEY

if (-not $authUsername -or -not $authPassword) {
    Write-Error "Variabili d'ambiente WINTRACK_AUTH_USER o WINTRACK_AUTH_PASS non trovate. Impostale."
    exit 1
}
if (-not $apiKey) {
    Write-Error "Variabile d'ambiente WINTRACK_API_KEY non trovata. Impostala."
    exit 1
}

$securePassword = ConvertTo-SecureString $authPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($authUsername, $securePassword)

Add-Type -AssemblyName System.Device
$geo = New-Object System.Device.Location.GeoCoordinateWatcher
$geo.Start()
Start-Sleep -Seconds 5
$pos = $geo.Position

$lat = $pos.Location.Latitude
$lon = $pos.Location.Longitude

if ([double]::IsNaN($lat) -or [double]::IsNaN($lon) -or $lat -eq 0 -or $lon -eq 0) {
    Write-Warning "Geolocalizzazione non valida (lat/lon sono 0 o NaN). Uscita."
    exit
}

$timestamp = (Get-Date).ToString("dd-MM-yyyy HH:mm")

$body = @{
    device = $env:COMPUTERNAME
    lat = $lat
    lon = $lon
    timestamp = $timestamp
} | ConvertTo-Json

Invoke-RestMethod `
    -Uri "<YOUR-URL-HERE>/update_position" `
    -Method POST `
    -Body $body `
    -ContentType "application/json" `
    -Headers @{ "X-API-Key" = $apiKey } `
    -Credential $credential `
    -TimeoutSec 10

exit
