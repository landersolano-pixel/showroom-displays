# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```powershell
npm install          # install deps
npm start            # run via ts-node (src/index.ts)
npm run prepare      # run scripts/prepare-usb.ps1 (requires -DriveLetter and -ImagePath args)
```

Run CLI directly:
```powershell
npx ts-node src/cli.ts detect
npx ts-node src/cli.ts format E: --filesystem FAT32
npx ts-node src/cli.ts flash E: path\to\image.iso
```

Run PowerShell scripts (must be admin for format/flash):
```powershell
powershell -ExecutionPolicy Bypass -File scripts\prepare-usb.ps1 -DriveLetter E -ImagePath path\to\image.iso
```

No test suite exists.

## Architecture

Two entry points with different interfaces:
- **[src/index.ts](src/index.ts)** — programmatic flow: detect → format first device → flash image (hardcoded path, demo only)
- **[src/cli.ts](src/cli.ts)** — `commander`-based CLI with `detect`, `format <drive>`, `flash <drive> <image>` subcommands

USB operations in `src/usb/`:
- **[detect.ts](src/usb/detect.ts)** — calls `wmic logicaldisk where "drivetype=2"` (Windows-only, WMI)
- **[format.ts](src/usb/format.ts)** — stub: logs and resolves after 2s timeout, no real formatting
- **[flash.ts](src/usb/flash.ts)** — stub: empty Promise body, real `dd` command is commented out

PowerShell layer (actual system operations):
- **[scripts/prepare-usb.ps1](scripts/prepare-usb.ps1)** — takes `-DriveLetter` + `-ImagePath`; calls `format` (NTFS/Quick) then `dd` for flashing
- **[src/windows/autorun.ps1](src/windows/autorun.ps1)** — polls for USB drive presence every 5s, runs a script when found

**Known issues:**
- `src/index.ts` imports `formatUSBDrive`/`flashUSBDrive` but those modules export `formatUSB`/`flashUSB` — name mismatch causes runtime failure
- `commander` is used in `src/cli.ts` but not listed in `package.json` dependencies
- `flash.ts` and `format.ts` are unimplemented stubs; real operations go through the PowerShell scripts

## Dashboard Kiosk System

10 HTML dashboards (root-level `01_recepcion.html` … `10_dashboard_ejecutivo.html`) are deployed to GitHub Pages on every push to `main` via [.github/workflows/static.yml](.github/workflows/static.yml). Each is assigned to one PC Stick in the showroom.

**Service Worker** ([sw.js](sw.js)): stale-while-revalidate strategy registered in every HTML. First online visit caches all resources (including CDN fonts/Tailwind) for offline use.

**Offline fallback chain:**
1. Online → GitHub Pages URL (always current)
2. Offline + SW cache → full functionality from browser cache
3. Offline + no SW cache → local `C:\Dashboards\*.html` (degraded CDN styles)

### Workflow to update dashboards

Edit HTML → `git push` → GitHub Pages auto-deploys → each PC downloads latest on next restart (when online). No action needed on the display PCs.

### Scripts (run on main PC)

```powershell
# Prepare USB for a specific display (run as admin)
.\scripts\prepare-dashboard-usb.ps1 -DriveLetter E -DashboardNumber 3
```

### Per-PC-Stick setup (one time, run as admin from USB)

```powershell
powershell -ExecutionPolicy Bypass -File E:\dashboard-setup\setup-display.ps1
```

What this installs on `C:\Dashboards\`:
- `config.json` — dashboard assignment
- `launch-dashboard.ps1` — kiosk launcher (scheduled at every logon)
- `XX_name.html` — offline cache copy

The Task Scheduler task `DashboardKiosk` runs `launch-dashboard.ps1` at every logon with highest privileges. The launcher loops forever: checks internet → opens Edge/Chrome in `--kiosk --edge-kiosk-type=fullscreen` mode → restarts browser if it exits. Power sleep/screensaver are disabled permanently.
