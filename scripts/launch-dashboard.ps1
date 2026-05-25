# Kiosk launcher — installed at C:\Dashboards\launch-dashboard.ps1
# Runs at every logon via Task Scheduler. Keeps browser open; restarts on exit.

$installPath = 'C:\Dashboards'
$configFile  = "$installPath\config.json"

if (-not (Test-Path $configFile)) {
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    [System.Windows.Forms.MessageBox]::Show('Config missing. Run setup-display.ps1 first.', 'Dashboard Kiosk')
    exit 1
}

$config    = Get-Content $configFile -Raw | ConvertFrom-Json
$fileName  = $config.fileName
$onlineUrl = "$($config.baseUrl)/$fileName"
$localPath = "$installPath\$fileName"

$edgePath   = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$chromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$browser    = if (Test-Path $edgePath) { $edgePath } elseif (Test-Path $chromePath) { $chromePath } else { $null }

function Resolve-Url {
    try {
        $r = Invoke-WebRequest -Uri $onlineUrl -Method Head -TimeoutSec 8 -UseBasicParsing -ErrorAction Stop
        if ($r.StatusCode -eq 200) {
            # Update offline cache in background
            Start-Job { Invoke-WebRequest -Uri $using:onlineUrl -OutFile $using:localPath -UseBasicParsing } | Out-Null
            return $onlineUrl
        }
    } catch { }

    if (Test-Path $localPath) { return 'file:///' + $localPath.Replace('\', '/') }
    return $null
}

# Stale job cleanup
Get-Job -State Completed -ErrorAction SilentlyContinue | Remove-Job -ErrorAction SilentlyContinue

# Keep dashboard alive indefinitely
while ($true) {

    # ── ESCAPE HATCH ──────────────────────────────────────────────────────────
    # Crea el archivo C:\Dashboards\STOP (desde USB u otro PC via red) y el
    # kiosk se detendra en el proximo ciclo sin reiniciar el browser.
    # cleanup-kiosk.ps1 lo crea automaticamente.
    if (Test-Path "$installPath\STOP") {
        Remove-Item "$installPath\STOP" -Force -ErrorAction SilentlyContinue
        Write-Host "$(Get-Date -f 'HH:mm:ss') STOP detectado - kiosk desactivado." -ForegroundColor Yellow
        exit 0
    }
    # ─────────────────────────────────────────────────────────────────────────

    $url = Resolve-Url

    if ($null -eq $url) {
        Start-Sleep -Seconds 30   # No internet, no cache — retry
        continue
    }

    if ($browser) {
        $args = if ($browser -eq $edgePath) {
            "--kiosk `"$url`" --edge-kiosk-type=fullscreen --no-first-run --disable-extensions --disable-session-crashed-bubble"
        } else {
            "--kiosk `"$url`" --no-first-run --disable-extensions"
        }
        (Start-Process -FilePath $browser -ArgumentList $args -PassThru).WaitForExit()
    } else {
        Start-Process $url
        Start-Sleep -Seconds 60
    }

    Start-Sleep -Seconds 5   # Brief pause before relaunch
}
