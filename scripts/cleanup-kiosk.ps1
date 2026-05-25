#Requires -RunAsAdministrator
# Desatorador de kiosk — elimina la tarea DashboardKiosk y mata el browser.
# COMO USARLO MIENTRAS EL KIOSK ESTA TRABADO (sin necesidad de cerrar nada primero):
#
#   1. Presiona Ctrl+Alt+Del en el PC Stick
#   2. Haz clic en "Administrador de tareas"
#   3. Ve a: Archivo -> Ejecutar nueva tarea
#   4. Escribe (con tu unidad USB, p.ej. D: o E:):
#        powershell -ExecutionPolicy Bypass -File D:\dashboard-setup\cleanup-kiosk.ps1
#   5. Marca "Crear esta tarea con privilegios de administrador" -> Aceptar
#
# Despues del cleanup puedes ejecutar setup-display.ps1 para reconfigurar.

param(
    [switch]$NoRestart   # Agrega -NoRestart para no reiniciar al final
)

Write-Host ''
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host '  CLEANUP KIOSK - NCTECH Showroom' -ForegroundColor Cyan
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ''

# 1. Crear archivo STOP para que el launcher no relance el browser si vuelve a correr
$installPath = 'C:\Dashboards'
if (Test-Path $installPath) {
    New-Item -Path "$installPath\STOP" -ItemType File -Force | Out-Null
    Write-Host '[1] Archivo STOP creado en C:\Dashboards\' -ForegroundColor Green
} else {
    Write-Host '[1] C:\Dashboards\ no existe, se omite STOP file' -ForegroundColor Gray
}

# 2. Matar browsers
$killed = $false
'msedge','chrome' | ForEach-Object {
    $procs = Get-Process -Name $_ -ErrorAction SilentlyContinue
    if ($procs) {
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "[2] Proceso '$_' terminado ($($procs.Count) instancia/s)" -ForegroundColor Green
        $killed = $true
    }
}
if (-not $killed) { Write-Host '[2] No habia procesos de browser activos' -ForegroundColor Gray }

# 3. Eliminar tarea programada
$task = Get-ScheduledTask -TaskName 'DashboardKiosk' -ErrorAction SilentlyContinue
if ($task) {
    Unregister-ScheduledTask -TaskName 'DashboardKiosk' -Confirm:$false
    Write-Host '[3] Tarea DashboardKiosk eliminada' -ForegroundColor Green
} else {
    Write-Host '[3] Tarea DashboardKiosk no encontrada (ya eliminada)' -ForegroundColor Gray
}

# 4. Deshabilitar auto-logon
$wl = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$autoLogon = (Get-ItemProperty -Path $wl -Name 'AutoAdminLogon' -ErrorAction SilentlyContinue).AutoAdminLogon
if ($autoLogon -eq '1') {
    Set-ItemProperty -Path $wl -Name 'AutoAdminLogon' -Value '0'
    Set-ItemProperty -Path $wl -Name 'DefaultPassword' -Value '' -ErrorAction SilentlyContinue
    Write-Host '[4] Auto-logon deshabilitado' -ForegroundColor Green
} else {
    Write-Host '[4] Auto-logon ya estaba deshabilitado' -ForegroundColor Gray
}

Write-Host ''
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host '  Kiosk limpiado correctamente.' -ForegroundColor Green
Write-Host '  Ahora puedes ejecutar setup-display.ps1' -ForegroundColor Green
Write-Host '  para instalar el dashboard correcto.' -ForegroundColor Green
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ''

if (-not $NoRestart) {
    Write-Host 'Reiniciando en 15 segundos... (cierra esta ventana o Ctrl+C para cancelar)' -ForegroundColor Yellow
    Start-Sleep -Seconds 15
    Restart-Computer -Force
}
