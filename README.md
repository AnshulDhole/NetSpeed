# NetSpeed

A minimal, borderless, semi-transparent desktop speedometer for Windows — built entirely with native **PowerShell + WPF**. Monitors real-time network download (↓) and upload (↑) bandwidth directly on your desktop.

![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-lightgrey)
![Size](https://img.shields.io/badge/Size-%3E30KB-brightgreen)

---

## Features

- **Real-time speeds** — updates every 1 second using .NET `NetworkInterface` counters
- **Always on top** — floats over games, editors, browsers, or the desktop
- **Borderless + transparent** — clean acrylic-style overlay with drop shadow
- **Draggable** — click and drag anywhere to reposition; position is saved
- **Right‑click menu** — change units, theme, opacity, interface, toggle always‑on‑top, or exit
- **Settings button** — lightning bolt (⚡) on the bar opens the full menu with a single left‑click
- **4 display modes** — KB/s, MB/s, Kbps, Mbps
- **5 themes** — Transparent Glass, Dark Glass, Midnight Blue, Pure White, Onyx Black
- **Interface selector** — monitor all adapters or pick a specific one
- **Opacity presets** — 30% to 100% in 10% steps
- **Reset position** — one-click snap back to default top-right corner
- **Auto-start** — toggle "Run at Startup" from the menu (registers in `HKCU\...\Run`)
- **Config persistence** — remembers your unit, theme, opacity, window position, interface, and topmost state across sessions
- **No dependencies** — pure PowerShell 5.1+ and .NET Framework (included with Windows)

---

## Preview

```
⚡ ▼ 1.23 MB/s    ▲ 0.45 MB/s
```

A small floating HUD, typically placed in the top‑right corner of the screen.

---

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or later (comes with Windows — no extra install needed)

---

## Quick Start

1. Download the [latest release](https://github.com/AnshulDhole/NetSpeed/releases) and extract the ZIP
2. Double-click **`NetSpeed.exe`**
3. The HUD appears on your desktop — that's it

On first run, `NetSpeed.exe` installs to `%LocalAppData%\NetSpeed`, creates a **desktop shortcut** and a **Start Menu entry**. From then on, launch NetSpeed like any other app — double-click the desktop shortcut, find it in Start Menu, or pin it to the taskbar.

---

## Pin to Taskbar

1. Double-click `NetSpeed.exe` (creates a desktop shortcut)
2. Right-click the **NetSpeed** desktop shortcut → **Pin to taskbar**

The HUD will always be one click away.

---

## Usage

| Action | Result |
|---|---|
| **Left‑click + drag** | Move the HUD anywhere on screen |
| **Left‑click the ⚡ icon** | Open the settings menu |
| **Right‑click anywhere** | Open the settings menu |
| **Menu → KB/s / MB/s / Kbps / Mbps** | Toggle speed display unit |
| **Menu → Theme** | Switch between 5 visual themes |
| **Menu → Interface** | Monitor all adapters or a specific one |
| **Menu → Opacity** | Adjust transparency from 30% to 100% |
| **Menu → Reset Position** | Snap back to default top-right corner |
| **Menu → Always on Top** | Pin / unpin the HUD above other windows |
| **Menu → Run at Startup** | Auto-launch HUD when you log in |
| **Menu → Exit** | Close the application |

All preferences are automatically saved when you close the HUD.

---

## Project Structure

```
netspeed/
├── NetSpeed.exe               # Compiled launcher — double-click to run
├── netspeed.ps1               # Main PowerShell entry point
├── netspeed.xaml               # WPF window layout (borderless, transparent)
├── start.vbs                   # Hidden launcher (no console window)
├── uninstall.ps1               # Clean removal utility
├── README.md                   # This file
├── LICENSE                     # MIT License
├── src/
│   ├── NetworkMonitor.ps1     # Network speed calculation engine
│   ├── ConfigManager.ps1      # JSON config read / write
│   └── ThemeManager.ps1       # Theme definitions and apply logic
└── .gitignore                  # Excludes user config from version control
```

### File roles

| File | Role |
|---|---|
| `NetSpeed.exe` | Double-click to install and run. No console, no dependencies. First run copies files to `%LocalAppData%\NetSpeed` and creates shortcuts. |
| `netspeed.ps1` | Core engine — loads WPF, parses XAML, builds context menu, runs 1 s timer, handles drag, manages window lifecycle. |
| `netspeed.xaml` | WPF window layout — borderless, transparent, lightning bolt icon, speed TextBlocks. |
| `start.vbs` | Hidden launcher (zero windows). Used internally by `NetSpeed.exe`. |
| `uninstall.ps1` | Removes all installed files, shortcuts, and registry entries. |
| `NetworkMonitor.ps1` | Reads network adapter byte counters, computes 1 s delta, returns download/upload speeds. Supports per‑interface monitoring. |
| `ConfigManager.ps1` | Saves and loads `netspeed.config.json` (unit, theme, opacity, position, interface, topmost, auto-start). |
| `ThemeManager.ps1` | Five theme presets with `Apply-Theme` that sets all WPF brushes in one call. |

---

## Network Monitoring Algorithm

```
1. Enumerate all non‑loopback, operational network interfaces
2. Sum BytesReceived and BytesSent across all active interfaces (or use selected interface)
3. Wait 1 second (DispatcherTimer)
4. Poll again, compute delta from previous values
5. Divide by elapsed time → bytes / second
6. Convert to KB/s, MB/s, Kbps, or Mbps based on user preference
7. Update UI TextBlocks
```

The counters are 64‑bit integers, so overflow is not a practical concern. Negative deltas (from adapter resets or sleep/wake cycles) are clamped to zero.

---

## Themes

| Name | Background | Foreground | Download Arrow | Upload Arrow |
|---|---|---|---|---|
| Transparent Glass | Near‑transparent dark slate | Bright grey | Cyan | Pink |
| Dark Glass | Subtle dark navy | White | Cyan | Amber |
| Midnight Blue | Near‑transparent dark blue | Blue accent | Green | Yellow |
| Pure White | Opaque white | Dark navy | Blue | Red |
| Onyx Black | Opaque black | Light grey | Blue | Red |

Semi‑transparent themes use low alpha values so the HUD blends into the desktop. Opaque themes (Pure White, Onyx Black) are fully solid for users who prefer a crisp, non‑translucent overlay.

---

## Security & Privacy

### Design

NetSpeed is a **read‑only observer** of local network interface counters. It performs **no network I/O**, **no data collection**, and **no process introspection** beyond reading adapter byte counts.

### Attack surface

| Vector | Status |
|---|---|
| Network connections | **None** — no HTTP, DNS, sockets, or any outbound / inbound traffic |
| Data collection | **None** — no telemetry, analytics, or crash reporting |
| File system | **Only its own config file** — `netspeed.config.json` (unit, theme, position — no secrets) |
| Registry | **Only if "Run at Startup" is enabled** — writes/removes one `HKCU\...\Run` value |
| Clipboard | **None** |
| Keyboard / input hooks | **None** |
| Process execution | **None** — no `Invoke-Expression`, no `Start-Process` of user‑supplied strings |
| Runtime code gen | `Add-Type` compiles static C# — `GetConsoleWindow` / `ShowWindow` only |
| Privileges | **Standard user** — no admin rights are required or requested |

### Permissions

- The script runs at the user's current integrity level.
- It reads `[System.Net.NetworkInformation.NetworkInterface]` statistics — a read‑only API available to all users.
- The only file write is `netspeed.config.json` in the project directory.
- PowerShell execution policy bypass (`-ExecutionPolicy Bypass`) is a user‑initiated flag — the script does not alter system policy.

### Summary

**No data leaves your machine. No ports are opened. No services are installed. No system settings are modified.** The application is safe to run, audit (it's ~30 KB of PowerShell), and include in any open‑source portfolio.

---

## License

MIT — see [LICENSE](LICENSE) for details.

If you use NetSpeed in a commercial product, attribution is appreciated but not required.


