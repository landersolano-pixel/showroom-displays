@echo off
title Dashboard Kiosk - Estacion 05
chcp 65001 >nul

:: ── 1. Crear carpeta de dashboards ───────────────────────────────────────────
if not exist "C:\Dashboards\" mkdir "C:\Dashboards\"

:: ── 2. Auto-instalar en Shell Startup (persiste entre reinicios) ─────────────
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
copy "%~f0" "%STARTUP%\DashboardKiosk.bat" /Y >nul 2>&1

:: ── 3. Copiar HTML del USB para cache offline ─────────────────────────────────
if exist "%~dp005_produccion.html" (
    copy "%~dp005_produccion.html" "C:\Dashboards\05_produccion.html" /Y >nul 2>&1
)

:: ── 4. Power settings -- nunca apagar pantalla ni suspender ──────────────────
powercfg /change standby-timeout-ac 0 >nul 2>&1
powercfg /change monitor-timeout-ac 0 >nul 2>&1
powercfg /change standby-timeout-dc 0 >nul 2>&1
powercfg /change monitor-timeout-dc 0 >nul 2>&1

:: ── 5. Deshabilitar protector de pantalla ────────────────────────────────────
reg add "HKCU\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 0 /f >nul 2>&1

:: ── 6. Detectar browser ───────────────────────────────────────────────────────
set "EDGE=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
set "CHROME=C:\Program Files\Google\Chrome\Application\chrome.exe"

:loop
:: ── 7. Verificar internet ────────────────────────────────────────────────────
ping -n 1 -w 3000 landersolano-pixel.github.io >nul 2>&1
if %errorlevel%==0 (
    set "URL=https://landersolano-pixel.github.io/showroom-displays/05_produccion.html"
) else (
    if exist "C:\Dashboards\05_produccion.html" (
        set "URL=file:///C:/Dashboards/05_produccion.html"
    ) else (
        timeout /t 10 /nobreak >nul
        goto loop
    )
)

:: ── 8. Abrir dashboard en pantalla completa ───────────────────────────────────
if exist "%EDGE%" (
    start /wait "" "%EDGE%" --app="%URL%" --start-fullscreen --no-first-run --disable-extensions --disable-session-crashed-bubble --noerrdialogs
) else if exist "%CHROME%" (
    start /wait "" "%CHROME%" --app="%URL%" --start-fullscreen --no-first-run --disable-extensions --noerrdialogs
) else (
    start "" "%URL%"
    timeout /t 60 /nobreak >nul
)

:: ── 9. Reiniciar si el browser se cierra ─────────────────────────────────────
timeout /t 3 /nobreak >nul
goto loop
