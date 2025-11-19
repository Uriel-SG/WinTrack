Add-Type -AssemblyName System.Device
$geo = New-Object System.Device.Location.GeoCoordinateWatcher
$geo.Start()
Start-Sleep -Seconds 5
$pos = $geo.Position

$lat = $pos.Location.Latitude
$lon = $pos.Location.Longitude

$timestamp = (Get-Date).ToString("dd-MM-yyyy HH:mm")

$apiKey = $env:WINTRACK_API_KEY

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
    -ContentType "application/json"
    -Headers @{ "X-API-Key" = $apiKey }

exit



