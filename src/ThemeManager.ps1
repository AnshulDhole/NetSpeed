$script:themes = [ordered]@{
    "transparent-glass" = @{ Name = "Transparent Glass"; Background = "#122C3E50"; Foreground = "#FFECEFF1"; DownloadColor = "#FF00BCD4"; UploadColor = "#FFE91E63" }
    "dark-glass"        = @{ Name = "Dark Glass";        Background = "#2E1A1A2E"; Foreground = "#FFF0F0F0"; DownloadColor = "#FF00E5FF"; UploadColor = "#FFFFAB00" }
    "midnight-blue"     = @{ Name = "Midnight Blue";     Background = "#1A0D1117"; Foreground = "#FF58A6FF"; DownloadColor = "#FF3FB950"; UploadColor = "#FFD2991D" }
    "pure-white"        = @{ Name = "Pure White";        Background = "#FFFFFFFF"; Foreground = "#FF2C3E50"; DownloadColor = "#FF1565C0"; UploadColor = "#FFE53935" }
    "onyx-black"        = @{ Name = "Onyx Black";        Background = "#FF000000"; Foreground = "#FFE0E0E0"; DownloadColor = "#FF42A5F5"; UploadColor = "#FFEF5350" }
}

function Get-ThemeList {
    $script:themes.Keys
}

function Get-Theme {
    param([string]$Name)
    if ($script:themes.Contains($Name)) {
        return $script:themes[$Name]
    }
    return $script:themes["transparent-glass"]
}

function Apply-Theme {
    param(
        [System.Windows.Controls.Border]$Border,
        [System.Windows.Controls.TextBlock]$DownloadIcon,
        [System.Windows.Controls.TextBlock]$DownloadSpeed,
        [System.Windows.Controls.TextBlock]$UploadIcon,
        [System.Windows.Controls.TextBlock]$UploadSpeed,
        [System.Windows.Controls.TextBlock]$SettingsIcon,
        [System.Windows.Controls.Border]$SettingsBtn,
        [string]$ThemeName
    )
    $theme = Get-Theme $ThemeName
    $toColor = { [System.Windows.Media.Color]([System.Windows.Media.ColorConverter]::ConvertFromString($args[0])) }
    $Border.Background = New-Object Windows.Media.SolidColorBrush (& $toColor $theme.Background)
    $DownloadIcon.Foreground = New-Object Windows.Media.SolidColorBrush (& $toColor $theme.DownloadColor)
    $UploadIcon.Foreground = New-Object Windows.Media.SolidColorBrush (& $toColor $theme.UploadColor)
    $fg = New-Object Windows.Media.SolidColorBrush (& $toColor $theme.Foreground)
    $DownloadSpeed.Foreground = $fg
    $UploadSpeed.Foreground = $fg
    $SettingsIcon.Foreground = $fg
    $accent = (& $toColor $theme.DownloadColor)
    $accent.A = 48
    $SettingsBtn.Background = New-Object Windows.Media.SolidColorBrush $accent
}
