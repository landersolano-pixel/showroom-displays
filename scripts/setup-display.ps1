#Requires -RunAsAdministrator
# Run this once on each PC Stick from the USB.
# Reads dashboard-assignment.json placed next to this script by prepare-dashboard-usb.ps1.

$installPath = 'C:\Dashboards'
$scriptDir   = $PSScriptRoot

$assignmentFile = Join-Path $scriptDir 'dashboard-assignment.json'
if (-not (Test-Path $assignmentFile)) {
    Write-Error 'dashboard-assignment.json not found. Use prepare-dashboard-usb.ps1 to create the USB package.'
    exit 1
}
$assignment = Get-Content $assignmentFile -Raw | ConvertFrom-Json

Write-Host "Configurando Dashboard: $($assignment.fileName)" -ForegroundColor Cyan
Write-Host ''

# Create install directory
New-Item -ItemType Directory -Force -Path $installPath | Out-Null

# Copy launcher
Copy-Item (Join-Path $scriptDir 'launch-dashboard.ps1') "$installPath\launch-dashboard.ps1" -Force

# Copy or download offline HTML cache
$htmlOnUSB = Join-Path $scriptDir $assignment.fileName
if (Test-Path $htmlOnUSB) {
    Copy-Item $htmlOnUSB "$installPath\$($assignment.fileName)" -Force
    Write-Host "HTML copiado desde USB (cache offline)" -ForegroundColor Green
} else {
    Write-Host "Descargando HTML para cache offline..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest `
            -Uri "$($assignment.baseUrl)/$($assignment.fileName)" `
            -OutFile "$installPath\$($assignment.fileName)" `
            -UseBasicParsing
        Write-Host "Descargado correctamente" -ForegroundColor Green
    } catch {
        Write-Warning 'No se pudo descargar. El PC necesita internet en el primer arranque.'
    }
}

# Save runtime config
$assignment | ConvertTo-Json | Set-Content "$installPath\config.json" -Encoding UTF8

# Power settings — never sleep or dim screen
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change monitor-timeout-dc 0

# Disable screensaver
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'ScreenSaveActive' -Value '0' -ErrorAction SilentlyContinue

# Register Task Scheduler logon task
$currentUser  = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$taskAction   = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File `"$installPath\launch-dashboard.ps1`""
$taskTrigger  = New-ScheduledTaskTrigger -AtLogOn -User $currentUser
$taskSettings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask `
    -TaskName 'DashboardKiosk' `
    -Action $taskAction `
    -Trigger $taskTrigger `
    -Settings $taskSettings `
    -RunLevel Highest `
    -Force | Out-Null

Write-Host ''
Write-Host "Tarea programada registrada para: $currentUser" -ForegroundColor Green

# Optional: auto-logon (recommended for kiosk)
Write-Host ''
$resp = Read-Host 'Configurar inicio de sesion automatico? (s/N)'
if ($resp -eq 's') {
    $secPass = Read-Host 'Contrasena de esta cuenta (se guarda en el registro de Windows)' -AsSecureString
    $bstr    = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPass)
    $plain   = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

    $wl = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    Set-ItemProperty -Path $wl -Name 'AutoAdminLogon'   -Value '1'
    Set-ItemProperty -Path $wl -Name 'DefaultUserName'  -Value $env:USERNAME
    Set-ItemProperty -Path $wl -Name 'DefaultDomainName' -Value $env:USERDOMAIN
    Set-ItemProperty -Path $wl -Name 'DefaultPassword'  -Value $plain
    Write-Host 'Inicio automatico configurado.' -ForegroundColor Green
}

Write-Host ''
Write-Host "Setup completo. El dashboard se abrira automaticamente en cada inicio." -ForegroundColor Cyan
Write-Host 'Reiniciando en 10 segundos... (Ctrl+C para cancelar)'
Start-Sleep -Seconds 10
Restart-Computer -Force
