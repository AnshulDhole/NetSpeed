$script:prevRx = 0
$script:prevTx = 0
$script:lastTick = $null
$script:selectedInterface = ""

function Get-ActiveInterfaces {
    param([string]$InterfaceName = "")
    $nics = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | Where-Object {
        $_.OperationalStatus -eq 'Up' -and
        $_.NetworkInterfaceType -ne 'Loopback' -and
        $_.NetworkInterfaceType -ne 'Tunnel'
    }
    if ($InterfaceName -ne "") {
        $nics = $nics | Where-Object { $_.Name -eq $InterfaceName }
    }
    return $nics
}

function Get-InterfaceNames {
    (Get-ActiveInterfaces) | ForEach-Object { $_.Name }
}

function Set-SelectedInterface {
    param([string]$Name)
    $script:selectedInterface = $Name
    $script:prevRx = 0
    $script:prevTx = 0
    $script:lastTick = $null
    Initialize-NetworkMonitor
}

function Initialize-NetworkMonitor {
    $nics = Get-ActiveInterfaces -InterfaceName $script:selectedInterface
    if ($nics) {
        $script:prevRx = ($nics | ForEach-Object { $_.GetIPv4Statistics().BytesReceived }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        $script:prevTx = ($nics | ForEach-Object { $_.GetIPv4Statistics().BytesSent }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    }
    $script:lastTick = [DateTime]::Now
}

function Get-NetworkSpeed {
    $nics = Get-ActiveInterfaces -InterfaceName $script:selectedInterface
    $curRx = 0; $curTx = 0
    if ($nics) {
        $curRx = ($nics | ForEach-Object { $_.GetIPv4Statistics().BytesReceived }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        $curTx = ($nics | ForEach-Object { $_.GetIPv4Statistics().BytesSent }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    }
    $now = [DateTime]::Now
    $elapsed = if ($script:lastTick) { ($now - $script:lastTick).TotalSeconds } else { 1 }
    $elapsed = [Math]::Max($elapsed, 0.1)
    $dl = [Math]::Max(0, ($curRx - $script:prevRx)) / $elapsed
    $ul = [Math]::Max(0, ($curTx - $script:prevTx)) / $elapsed
    $script:prevRx = $curRx
    $script:prevTx = $curTx
    $script:lastTick = $now
    return @{ Download = $dl; Upload = $ul }
}
