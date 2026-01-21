<#
.SYNOPSIS
    Configure-Firewall.ps1 - Configure Hyper-V firewall rules for WSL2 development
#>
$ErrorActionPreference = "Stop"
$cfg = $env:DEPLOY_CONFIG | ConvertFrom-Json

Write-Host "  Configuring Firewall Rules for WSL2..." -ForegroundColor Gray

# WSL2 VM Creator ID (standard GUID)
$wslVmCreatorId = "{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}"
$portsArray = $cfg.security.allowed_ports
# Convert array to comma-separated string for firewall cmdlets
$ports = if ($portsArray -is [array]) { $portsArray -join ',' } else { $portsArray }

if ($cfg.security.firewall_mode -eq "allow_all") {
    # Less secure but more convenient
    Write-Host "    Setting default inbound action to Allow (all ports)..." -ForegroundColor Yellow
    try {
        Set-NetFirewallHyperVVMSetting -Name $wslVmCreatorId -DefaultInboundAction Allow -ErrorAction SilentlyContinue
        Write-Host "    All inbound connections allowed for WSL2" -ForegroundColor Green
    } catch {
        Write-Host "    Hyper-V firewall not available on this system" -ForegroundColor Yellow
    }
} else {
    # Specific ports - more secure
    Write-Host "    Creating rules for specific development ports..." -ForegroundColor Gray
    Write-Host "    Ports: $($ports -join ', ')" -ForegroundColor DarkGray
    
    # Remove existing WSL2 rules
    try {
        Get-NetFirewallHyperVRule -ErrorAction SilentlyContinue | 
            Where-Object { $_.DisplayName -like "WSL2-*" } | 
            Remove-NetFirewallHyperVRule -ErrorAction SilentlyContinue
    } catch {}
    
    # Create Hyper-V rule
    try {
        New-NetFirewallHyperVRule -Name "WSL2-Dev-Ports" `
            -DisplayName "WSL2 Development Ports" `
            -Description "Allow inbound connections to WSL2 development ports" `
            -Direction Inbound `
            -VMCreatorId $wslVmCreatorId `
            -Protocol TCP `
            -LocalPorts $ports `
            -Action Allow `
            -ErrorAction SilentlyContinue | Out-Null
        
        Write-Host "    Hyper-V firewall rule created" -ForegroundColor Green
    } catch {
        Write-Host "    Hyper-V firewall not available" -ForegroundColor Yellow
    }
    
    # Also create standard Windows Firewall rules as backup
    Write-Host "    Creating Windows Firewall rules..." -ForegroundColor Gray
    
    # Remove existing rule
    Remove-NetFirewallRule -DisplayName "WSL2 Development" -ErrorAction SilentlyContinue
    
    # Create new rule
    New-NetFirewallRule -DisplayName "WSL2 Development" `
        -Description "Allow WSL2 development traffic" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort $ports `
        -Action Allow `
        -Profile Private,Domain `
        -ErrorAction SilentlyContinue | Out-Null
    
    Write-Host "    Windows Firewall rule created" -ForegroundColor Green
}

Write-Host "  Firewall configuration complete" -ForegroundColor Green
exit 0
