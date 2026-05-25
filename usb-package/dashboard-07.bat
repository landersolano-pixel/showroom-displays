@echo off
title Dashboard Kiosk - Estacion 07
cd /d "%~dp0"

:: Crear carpeta de dashboards
if not exist "C:\Dashboards\" mkdir "C:\Dashboards\"

:: Auto-instalar en Startup
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
copy "%~f0" "%STARTUP%\DashboardKiosk.bat" /Y >nul 2>&1

:: Copiar HTML del USB para cache offline
if exist "%~dp007_mantenimiento.html" (
    copy "%~dp007_mantenimiento.html" "C:\Dashboards\07_mantenimiento.html" /Y >nul 2>&1
)

:: Power settings
powercfg /change standby-timeout-ac 0 >nul 2>&1
powercfg /change monitor-timeout-ac 0 >nul 2>&1
powercfg /change standby-timeout-dc 0 >nul 2>&1
powercfg /change monitor-timeout-dc 0 >nul 2>&1

:: Deshabilitar protector de pantalla
reg add "HKCU\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 0 /f >nul 2>&1

:: Detectar browser y definir nombre de proceso
set "EDGE=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
set "CHROME=C:\Program Files\Google\Chrome\Application\chrome.exe"

if exist "%EDGE%" (
    set "BROWSER=%EDGE%"
    set "BROWSER_EXE=msedge.exe"
) else if exist "%CHROME%" (
    set "BROWSER=%CHROME%"
    set "BROWSER_EXE=chrome.exe"
) else (
    set "BROWSER="
    set "BROWSER_EXE="
)

:loop
set "URL="

:: Verificar internet
ping -n 1 -w 3000 landersolano-pixel.github.io >nul 2>&1
if not errorlevel 1 (
    set "URL=https://landersolano-pixel.github.io/showroom-displays/07_mantenimiento.html"
) else (
    if exist "C:\Dashboards\07_mantenimiento.html" (
        set "URL=file:///C:/Dashboards/07_mantenimiento.html"
    )
)

:: Sin URL disponible, reintentar en 10s
if not defined URL (
    timeout /t 10 /nobreak >nul
    goto loop
)

:: Cerrar instancias previas del browser antes de abrir
if defined BROWSER_EXE (
    taskkill /f /im "%BROWSER_EXE%" >nul 2>&1
    timeout /t 2 /nobreak >nul
)

:: Abrir dashboard
if defined BROWSER (
    start "" "%BROWSER%" --app="%URL%" --start-fullscreen --no-first-run --disable-extensions --disable-session-crashed-bubble --noerrdialogs
) else (
    start "" "%URL%"
)

:: Esperar a que el proceso aparezca
timeout /t 3 /nobreak >nul

:: Vigilar el proceso - solo relanzar cuando se cierre
:watch
timeout /t 5 /nobreak >nul
if defined BROWSER_EXE (
    tasklist /fi "imagename eq %BROWSER_EXE%" 2>nul | find /i "%BROWSER_EXE%" >nul
    if not errorlevel 1 goto watch
)

:: Browser cerrado - reiniciar
goto loop
