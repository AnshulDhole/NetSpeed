#Requires -Version 5.0

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
$script:ScriptRoot = $PSScriptRoot

. (Join-Path $script:ScriptRoot "src\ConfigManager.ps1")
. (Join-Path $script:ScriptRoot "src\ThemeManager.ps1")
. (Join-Path $script:ScriptRoot "src\NetworkMonitor.ps1")

Set-ConfigRoot -Path $script:ScriptRoot

try {
    $xamlPath = Join-Path $script:ScriptRoot "netspeed.xaml"
    $reader = [System.Xml.XmlReader]::Create($xamlPath)
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $reader.Close()

    $mainBorder = $window.FindName("MainBorder")
    $settingsBtn = $window.FindName("SettingsBtn")
    $settingsIcon = $window.FindName("SettingsIcon")
    $downloadIcon = $window.FindName("DownloadIcon")
    $downloadSpeed = $window.FindName("DownloadSpeed")
    $uploadIcon = $window.FindName("UploadIcon")
    $uploadSpeed = $window.FindName("UploadSpeed")

    $script:currentUnit = "MB"
    $script:currentTheme = "transparent-glass"
    $script:currentOpacity = 0.8
    $script:currentTopmost = $true
    $script:currentInterface = ""
    $script:currentAutoStart = $false

    $config = Read-Config
    if ($config) {
        if ($config.Unit -in @("KB", "MB", "Kbps", "Mbps")) { $script:currentUnit = $config.Unit }
        if ($config.Theme -in (Get-ThemeList)) { $script:currentTheme = $config.Theme }
        if ($config.Opacity -ge 0.1 -and $config.Opacity -le 1.0) { $script:currentOpacity = $config.Opacity }
        if ($config.X -ne $null) { $window.Left = $config.X }
        if ($config.Y -ne $null) { $window.Top = $config.Y }
        $script:currentTopmost = if ($config.Topmost -ne $null) { $config.Topmost } else { $true }
        $script:currentInterface = if ($config.Interface -ne $null) { $config.Interface } else { "" }
        $script:currentAutoStart = if ($config.AutoStart -ne $null) { $config.AutoStart } else { $false }
    } else {
        $window.Left = [System.Windows.SystemParameters]::PrimaryScreenWidth - $window.Width - 20
        $window.Top = 50
    }

    $window.Topmost = $script:currentTopmost

    Apply-Theme -Border $mainBorder -DownloadIcon $downloadIcon -DownloadSpeed $downloadSpeed -UploadIcon $uploadIcon -UploadSpeed $uploadSpeed -SettingsIcon $settingsIcon -SettingsBtn $settingsBtn -ThemeName $script:currentTheme
    $window.Opacity = $script:currentOpacity

    if ($script:currentInterface -ne "") {
        $avail = Get-InterfaceNames
        if ($script:currentInterface -in $avail) { Set-SelectedInterface -Name $script:currentInterface }
    }
    Initialize-NetworkMonitor

    $contextMenu = New-Object System.Windows.Controls.ContextMenu

    $unitKB = New-Object System.Windows.Controls.MenuItem
    $unitKB.Header = "KB/s"; $unitKB.IsCheckable = $true; $unitKB.IsChecked = ($script:currentUnit -eq "KB")
    $unitKB.add_Click({ $script:currentUnit = "KB"; Update-MenuChecks })

    $unitMB = New-Object System.Windows.Controls.MenuItem
    $unitMB.Header = "MB/s"; $unitMB.IsCheckable = $true; $unitMB.IsChecked = ($script:currentUnit -eq "MB")
    $unitMB.add_Click({ $script:currentUnit = "MB"; Update-MenuChecks })

    $unitkbps = New-Object System.Windows.Controls.MenuItem
    $unitkbps.Header = "Kbps"; $unitkbps.IsCheckable = $true; $unitkbps.IsChecked = ($script:currentUnit -eq "Kbps")
    $unitkbps.add_Click({ $script:currentUnit = "Kbps"; Update-MenuChecks })

    $unitMbps = New-Object System.Windows.Controls.MenuItem
    $unitMbps.Header = "Mbps"; $unitMbps.IsCheckable = $true; $unitMbps.IsChecked = ($script:currentUnit -eq "Mbps")
    $unitMbps.add_Click({ $script:currentUnit = "Mbps"; Update-MenuChecks })

    $contextMenu.Items.Add($unitKB) | Out-Null
    $contextMenu.Items.Add($unitMB) | Out-Null
    $contextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null
    $contextMenu.Items.Add($unitkbps) | Out-Null
    $contextMenu.Items.Add($unitMbps) | Out-Null
    $contextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

    $themeHeader = New-Object System.Windows.Controls.MenuItem
    $themeHeader.Header = "Theme"
    foreach ($t in (Get-ThemeList)) {
        $info = Get-Theme $t
        $item = New-Object System.Windows.Controls.MenuItem
        $item.Header = $info.Name; $item.IsCheckable = $true; $item.IsChecked = ($t -eq $script:currentTheme)
        $item.Tag = $t
        $item.add_Click({
            $script:currentTheme = $this.Tag
            Apply-Theme -Border $mainBorder -DownloadIcon $downloadIcon -DownloadSpeed $downloadSpeed -UploadIcon $uploadIcon -UploadSpeed $uploadSpeed -SettingsIcon $settingsIcon -SettingsBtn $settingsBtn -ThemeName $script:currentTheme
            Update-MenuChecks
        })
        $themeHeader.Items.Add($item) | Out-Null
    }
    $contextMenu.Items.Add($themeHeader) | Out-Null
    $contextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

    $opacityHeader = New-Object System.Windows.Controls.MenuItem
    $opacityHeader.Header = "Opacity"
    $opts = @{ "100%" = 1.0; "90%" = 0.9; "80%" = 0.8; "70%" = 0.7; "60%" = 0.6; "50%" = 0.5; "40%" = 0.4; "30%" = 0.3 }
    foreach ($label in "100%", "90%", "80%", "70%", "60%", "50%", "40%", "30%") {
        $val = $opts[$label]
        $item = New-Object System.Windows.Controls.MenuItem
        $item.Header = $label; $item.IsCheckable = $true; $item.IsChecked = ([Math]::Abs($script:currentOpacity - $val) -lt 0.01)
        $item.Tag = $val
        $item.add_Click({ $script:currentOpacity = [double]$this.Tag; $window.Opacity = $script:currentOpacity; Update-MenuChecks })
        $opacityHeader.Items.Add($item) | Out-Null
    }
    $contextMenu.Items.Add($opacityHeader) | Out-Null
    $contextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

    $interfaceHeader = New-Object System.Windows.Controls.MenuItem
    $interfaceHeader.Header = "Interface"
    $allItem = New-Object System.Windows.Controls.MenuItem
    $allItem.Header = "(All)"; $allItem.IsCheckable = $true; $allItem.IsChecked = ($script:currentInterface -eq "")
    $allItem.add_Click({ $script:currentInterface = ""; Set-SelectedInterface -Name ""; Update-MenuChecks })
    $interfaceHeader.Items.Add($allItem) | Out-Null
    foreach ($ifName in (Get-InterfaceNames)) {
        $item = New-Object System.Windows.Controls.MenuItem
        $item.Header = $ifName; $item.IsCheckable = $true; $item.IsChecked = ($script:currentInterface -eq $ifName)
        $item.Tag = $ifName
        $item.add_Click({ $script:currentInterface = $this.Tag; Set-SelectedInterface -Name $script:currentInterface; Update-MenuChecks })
        $interfaceHeader.Items.Add($item) | Out-Null
    }
    $contextMenu.Items.Add($interfaceHeader) | Out-Null
    $contextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

    $resetPosItem = New-Object System.Windows.Controls.MenuItem
    $resetPosItem.Header = "Reset Position"
    $resetPosItem.add_Click({
        $window.Left = [System.Windows.SystemParameters]::PrimaryScreenWidth - $window.Width - 20
        $window.Top = 50
    })
    $contextMenu.Items.Add($resetPosItem) | Out-Null
    $contextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

    $topmostItem = New-Object System.Windows.Controls.MenuItem
    $topmostItem.Header = "Always on Top"; $topmostItem.IsCheckable = $true; $topmostItem.IsChecked = $script:currentTopmost
    $topmostItem.add_Click({ $script:currentTopmost = $this.IsChecked; $window.Topmost = $script:currentTopmost; Update-MenuChecks })
    $contextMenu.Items.Add($topmostItem) | Out-Null

    $autoStartItem = New-Object System.Windows.Controls.MenuItem
    $autoStartItem.Header = "Run at Startup"; $autoStartItem.IsCheckable = $true; $autoStartItem.IsChecked = $script:currentAutoStart
    $autoStartItem.add_Click({
        $script:currentAutoStart = $this.IsChecked
        if ($script:currentAutoStart) {
            $vbsPath = Join-Path $script:ScriptRoot "start.vbs"
            $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Run", $true)
            if ($key) { $key.SetValue("NetSpeed", "wscript.exe `"$vbsPath`"", [Microsoft.Win32.RegistryValueKind]::String); $key.Close() }
        } else {
            $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Run", $true)
            if ($key) { if ($key.GetValue("NetSpeed") -ne $null) { $key.DeleteValue("NetSpeed") }; $key.Close() }
        }
        Update-MenuChecks
    })
    $contextMenu.Items.Add($autoStartItem) | Out-Null
    $contextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

    $exitItem = New-Object System.Windows.Controls.MenuItem
    $exitItem.Header = "Exit"
    $exitItem.add_Click({ $window.Close() })
    $contextMenu.Items.Add($exitItem) | Out-Null

    $mainBorder.ContextMenu = $contextMenu

    $settingsBtn.Add_MouseLeftButtonDown({
        param($s, $e)
        $mainBorder.ContextMenu.IsOpen = $true
        $e.Handled = $true
    })

    function Update-MenuChecks {
        $unitKB.IsChecked = ($script:currentUnit -eq "KB")
        $unitMB.IsChecked = ($script:currentUnit -eq "MB")
        $unitkbps.IsChecked = ($script:currentUnit -eq "Kbps")
        $unitMbps.IsChecked = ($script:currentUnit -eq "Mbps")
        foreach ($themeItem in $themeHeader.Items) { $themeItem.IsChecked = ($themeItem.Tag -eq $script:currentTheme) }
        foreach ($opacityItem in $opacityHeader.Items) { $opacityItem.IsChecked = ([Math]::Abs($script:currentOpacity - [double]$opacityItem.Tag) -lt 0.01) }
        $allItem.IsChecked = ($script:currentInterface -eq "")
        foreach ($ifItem in $interfaceHeader.Items) { if ($ifItem -ne $allItem) { $ifItem.IsChecked = ($ifItem.Tag -eq $script:currentInterface) } }
        $topmostItem.IsChecked = $script:currentTopmost
        $autoStartItem.IsChecked = $script:currentAutoStart
    }

    function Format-Speed {
        param([double]$BytesPerSec, [string]$Unit)
        if ($Unit -eq "KB")   { return "{0:F2} KB/s"  -f ($BytesPerSec / 1KB) }
        if ($Unit -eq "Kbps") { return "{0:F2} Kbps"  -f ($BytesPerSec * 8 / 1e3) }
        if ($Unit -eq "Mbps") { return "{0:F2} Mbps"  -f ($BytesPerSec * 8 / 1e6) }
        return "{0:F2} MB/s" -f ($BytesPerSec / 1MB)
    }

    $window.Add_MouseLeftButtonDown({ $window.DragMove() })

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    $timer.Add_Tick({
        $speed = Get-NetworkSpeed
        $downloadSpeed.Text = Format-Speed -BytesPerSec $speed.Download -Unit $script:currentUnit
        $uploadSpeed.Text = Format-Speed -BytesPerSec $speed.Upload -Unit $script:currentUnit
    })
    $timer.Start()

    $window.Add_Closing({
        try {
            Write-Config -Unit $script:currentUnit -Theme $script:currentTheme -Opacity $script:currentOpacity -X ([int][Math]::Round($window.Left)) -Y ([int][Math]::Round($window.Top)) -Topmost $script:currentTopmost -Interface $script:currentInterface -AutoStart $script:currentAutoStart
        } catch {}
    })

    try {
        if (-not ([System.Management.Automation.PSTypeName]'NetSpeed.ConsoleHelper').Type) {
            Add-Type @'
using System;
using System.Runtime.InteropServices;
namespace NetSpeed {
    public class ConsoleHelper {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
}
'@
        }
        $hwnd = [NetSpeed.ConsoleHelper]::GetConsoleWindow()
        if ($hwnd -ne [IntPtr]::Zero) { [NetSpeed.ConsoleHelper]::ShowWindow($hwnd, 0) | Out-Null }
    } catch {}

    $window.ShowDialog() | Out-Null

} catch {
    $null = [System.Windows.MessageBox]::Show("NetSpeed error: $($_.Exception.Message)", "NetSpeed", "OK", "Error")
}
