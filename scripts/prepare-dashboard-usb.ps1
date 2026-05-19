# Run on the MAIN PC to prepare a USB for a specific display PC Stick.
# Usage: .\prepare-dashboard-usb.ps1 -DriveLetter E -DashboardNumber 3

param (
    [Parameter(Mandatory)]
    [string]$DriveLetter,

    [Parameter(Mandatory)]
    [ValidateRange(1, 10)]
    [int]$DashboardNumber
)

$dashboardMap = @{
    1  = '01_recepcion.html'
    2  = '02_digital_factory.html'
    3  = '03_instantmes.html'
    4  = '04_trazabilidad.html'
    5  = '05_produccion.html'
    6  = '06_calidad.html'
    7  = '07_mantenimiento.html'
    8  = '08_ecosistema.html'
    9  = '09_edge_iot_gateway.html'
    10 = '10_dashboard_ejecutivo.html'
}

$baseUrl  = 'https://landersolano-pixel.github.io/showroom-displays'
$fileName = $dashboardMap[$DashboardNumber]
$drive    = $DriveLetter.TrimEnd(':') + ':'
$usbRoot  = "$drive\"
$setupDir = Join-Path $usbRoot 'dashboard-setup'
$repoRoot = Split-Path $PSScriptRoot -Parent

if (-not (Test-Path $usbRoot)) {
    Write-Error "Unidad $drive no encontrada."
    exit 1
}

New-Item -ItemType Directory -Force -Path $setupDir | Out-Null

# Copy setup scripts
Copy-Item (Join-Path $PSScriptRoot 'setup-display.ps1')    $setupDir -Force
Copy-Item (Join-Path $PSScriptRoot 'launch-dashboard.ps1') $setupDir -Force

# Write dashboard assignment
@{
    dashboard = $DashboardNumber.ToString('D2')
    fileName  = $fileName
    baseUrl   = $baseUrl
} | ConvertTo-Json | Set-Content (Join-Path $setupDir 'dashboard-assignment.json') -Encoding UTF8

# Copy HTML from local repo, or download from GitHub Pages as fallback
$localHtml = Join-Path $repoRoot $fileName
if (Test-Path $localHtml) {
    Copy-Item $localHtml $setupDir -Force
    Write-Host "HTML copiado desde repo local: $fileName" -ForegroundColor Green
} else {
    Write-Host "Descargando $fileName desde GitHub Pages..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri "$baseUrl/$fileName" -OutFile (Join-Path $setupDir $fileName) -UseBasicParsing
        Write-Host "Descargado correctamente" -ForegroundColor Green
    } catch {
        Write-Warning "No se pudo descargar HTML. El PC necesitara internet en el primer arranque."
    }
}

# Write README on USB root
@"
SHOWROOM DASHBOARD SETUP
========================
Dashboard #$DashboardNumber : $fileName

INSTRUCCIONES
-------------
1. Conecta este USB al PC Stick destino
2. Abre PowerShell como Administrador
3. Ejecuta:
   powershell -ExecutionPolicy Bypass -File "${drive}\dashboard-setup\setup-display.ps1"
4. Sigue las instrucciones en pantalla
5. El PC se reiniciara automaticamente

COMPORTAMIENTO
--------------
- Al iniciar: abre el dashboard en pantalla completa automaticamente
- Online:  carga desde GitHub Pages (siempre la version mas reciente)
- Offline: carga desde cache local (guardada en C:\Dashboards\)

ACTUALIZAR DESDE PC PRINCIPAL
------------------------------
Edita los HTML -> git push -> GitHub Pages se actualiza automaticamente.
Cada PC Stick descarga la nueva version en el proximo reinicio (si tiene internet).
"@ | Set-Content (Join-Path $usbRoot 'README.txt') -Encoding UTF8

Write-Host ''
Write-Host "USB listo para Dashboard #$DashboardNumber ($fileName)" -ForegroundColor Cyan
Write-Host "Conecta al PC Stick y ejecuta: ${drive}\dashboard-setup\setup-display.ps1"
