$script:ConfigRoot = $null

function Set-ConfigRoot {
    param([string]$Path)
    $script:ConfigRoot = $Path
}

function Get-ConfigPath {
    Join-Path $script:ConfigRoot "netspeed.config.json"
}

function Read-Config {
    $path = Get-ConfigPath
    if (Test-Path $path) {
        try {
            $json = Get-Content $path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            return @{
                Unit       = $json.unit
                Theme      = $json.theme
                Opacity    = [double]$json.opacity
                X          = if ($json.windowX -ne $null) { [int]$json.windowX } else { $null }
                Y          = if ($json.windowY -ne $null) { [int]$json.windowY } else { $null }
                Topmost    = if ($json.topmost -ne $null) { [bool]$json.topmost } else { $true }
                Interface  = if ($json.interface -ne $null) { [string]$json.interface } else { "" }
                AutoStart  = if ($json.autoStart -ne $null) { [bool]$json.autoStart } else { $false }
            }
        } catch {
            return $null
        }
    }
    return $null
}

function Write-Config {
    param(
        [string]$Unit,
        [string]$Theme,
        [double]$Opacity,
        $X,
        $Y,
        [bool]$Topmost,
        [string]$Interface,
        [bool]$AutoStart
    )
    $path = Get-ConfigPath
    $config = @{
        unit      = $Unit
        theme     = $Theme
        opacity   = $Opacity
        windowX   = $X
        windowY   = $Y
        topmost   = $Topmost
        interface = $Interface
        autoStart = $AutoStart
    } | ConvertTo-Json -Compress
    try {
        $config | Out-File -FilePath $path -Encoding UTF8 -Force -ErrorAction Stop
    } catch {}
}
