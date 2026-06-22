#Requires -Version 5.0

$targetDir = Join-Path $env:LOCALAPPDATA "NetSpeed"

Write-Host "NetSpeed Uninstaller" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "Remove NetSpeed and all its files? (y/N) "
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit
}

Write-Host "  Removing desktop shortcut..." -ForegroundColor Gray
$desktopLnk = Join-Path ([Environment]::GetFolderPath("Desktop")) "NetSpeed.lnk"
if (Test-Path $desktopLnk) { Remove-Item -Path $desktopLnk -Force }

Write-Host "  Removing Start Menu shortcuts..." -ForegroundColor Gray
$startMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\NetSpeed"
if (Test-Path $startMenuDir) { Remove-Item -Path $startMenuDir -Recurse -Force }

Write-Host "  Removing Run at Startup registry entry..." -ForegroundColor Gray
try {
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Run", $true)
    if ($key) { if ($key.GetValue("NetSpeed") -ne $null) { $key.DeleteValue("NetSpeed") }; $key.Close() }
} catch {}

Write-Host "  Removing installed files..." -ForegroundColor Gray
if (Test-Path $targetDir) {
    $keepConfig = Read-Host "Keep config file (netspeed.config.json) for future use? (y/N) "
    if ($keepConfig -eq "y" -or $keepConfig -eq "Y") {
        $cfgPath = Join-Path $targetDir "netspeed.config.json"
        if (Test-Path $cfgPath) { Copy-Item -Path $cfgPath -Destination $env:USERPROFILE -Force }
    }
    Remove-Item -Path $targetDir -Recurse -Force
}

Write-Host ""
Write-Host "NetSpeed has been removed." -ForegroundColor Green
Write-Host ""

Start-Sleep -Seconds 2
