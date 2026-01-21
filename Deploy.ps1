<#
.SYNOPSIS
    Windows Development Environment - Automated Deployment
.DESCRIPTION
    Deploys: WSL2 (mirrored networking) + Docker + VS Code + GitHub Copilot CLI + Claude Code
    Edit config.json before running. Run as Administrator.
.EXAMPLE
    .\Deploy.ps1
    .\Deploy.ps1 -Force              # Re-run completed steps
    .\Deploy.ps1 -SkipReboot         # Don't auto-reboot
#>
#Requires -RunAsAdministrator
#Requires -Version 5.1

param(
    [string]$ConfigFile = "$PSScriptRoot\config.json",
    [switch]$Phase2,
    [switch]$Force,
    [switch]$SkipReboot
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ============================================================================
# PATHS
# ============================================================================
$Script:Root = $PSScriptRoot
$Script:InstallCore = Join-Path $Root "install\core"
$Script:InstallTools = Join-Path $Root "install\tools"
$Script:InstallAI = Join-Path $Root "install\ai-assistants"
$Script:ConfigureWSL = Join-Path $Root "configure\wsl"
$Script:ConfigureTerminal = Join-Path $Root "configure\terminal"
$Script:ConfigureEnv = Join-Path $Root "configure\environment"
$Script:LogDir = Join-Path $Root "logs"
$Script:LogFile = Join-Path $LogDir "deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$Script:StateFile = Join-Path $Root ".state.json"

if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

# ============================================================================
# LOGGING
# ============================================================================
function Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $line = "[$ts][$Level] $Message"
    Add-Content -Path $Script:LogFile -Value $line -ErrorAction SilentlyContinue
    switch ($Level) {
        "INFO"    { Write-Host $line -ForegroundColor Cyan }
        "WARN"    { Write-Host $line -ForegroundColor Yellow }
        "ERROR"   { Write-Host $line -ForegroundColor Red }
        "SUCCESS" { Write-Host $line -ForegroundColor Green }
        "STEP"    { Write-Host "`n$("="*65)`n  $Message`n$("="*65)" -ForegroundColor Magenta }
    }
}

# ============================================================================
# CONFIGURATION
# ============================================================================
function Get-Config {
    if (!(Test-Path $ConfigFile)) { 
        Log "Configuration file not found: $ConfigFile" "ERROR"
        exit 1 
    }
    $cfg = Get-Content $ConfigFile -Raw | ConvertFrom-Json
    
    # Auto-detect resources
    if ($cfg.resources.auto_detect) {
        $totalRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
        $cpuCores = (Get-CimInstance Win32_Processor).NumberOfCores

        # Validate allocation_percent is within valid range
        $allocPct = $cfg.resources.allocation_percent
        if ($null -eq $allocPct -or $allocPct -le 0 -or $allocPct -gt 100) {
            $allocPct = 50
        }
        $pct = $allocPct / 100
        
        if ($cfg.resources.wsl_memory_gb -eq "auto") {
            $cfg.resources.wsl_memory_gb = [math]::Min([math]::Floor($totalRAM * $pct), 16)
        }
        if ($cfg.resources.wsl_processors -eq "auto") {
            $cfg.resources.wsl_processors = [math]::Min([math]::Floor($cpuCores * $pct), 8)
        }
    }
    return $cfg
}

# ============================================================================
# STATE MANAGEMENT
# ============================================================================
function Get-State { 
    if (Test-Path $StateFile) { return Get-Content $StateFile -Raw | ConvertFrom-Json }
    return @{ completed = @(); phase = 1 } 
}

function Save-State($state) { 
    $state | ConvertTo-Json -Depth 5 | Set-Content $StateFile 
}

function Complete-Step($name) { 
    $state = Get-State
    if ($state.completed -notcontains $name) { 
        $state.completed += $name
        Save-State $state 
    }
    Log "$name" "SUCCESS"
}

function Test-StepDone($name) { 
    return (Get-State).completed -contains $name 
}

# ============================================================================
# SCRIPT RUNNER
# ============================================================================
function Invoke-Script {
    param(
        [string]$Path,
        [string]$Description,
        [object]$Config
    )
    
    $name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    
    if (!(Test-Path $Path)) {
        Log "Script not found: $Path" "ERROR"
        return $false
    }
    
    if ((Test-StepDone $name) -and !$Force) {
        Log "$Description - already completed, skipping"
        return $true
    }
    
    Log $Description "STEP"
    
    try {
        $env:DEPLOY_CONFIG = ($Config | ConvertTo-Json -Depth 10 -Compress)
        & $Path
        
        if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
            Complete-Step $name
            return $true
        }
        Log "$name failed with exit code $LASTEXITCODE" "ERROR"
        return $false
    }
    catch {
        Log "Error in $name : $_" "ERROR"
        return $false
    }
}

# ============================================================================
# BANNER
# ============================================================================
Clear-Host
Write-Host @"

  ╔═══════════════════════════════════════════════════════════════════╗
  ║       WINDOWS DEVELOPMENT ENVIRONMENT DEPLOYMENT                  ║
  ║                                                                   ║
  ║       WSL2 + Docker + GitHub Copilot CLI + Claude Code            ║
  ╚═══════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# ============================================================================
# PREREQUISITES
# ============================================================================
$cfg = Get-Config

Log "Configuration: $ConfigFile"
Log "User: $($cfg.user.name) <$($cfg.user.email)>"
Log "WSL2: $($cfg.resources.wsl_memory_gb)GB RAM, $($cfg.resources.wsl_processors) CPUs"

# Check Windows version
$build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
if ([int]$build -lt 22000) {
    Log "Windows 11 (Build 22000+) required for mirrored networking. Current: $build" "ERROR"
    exit 1
}

# Check disk space
$freeGB = [math]::Round((Get-PSDrive C).Free / 1GB)
if ($freeGB -lt 30) {
    Log "Need 30GB free disk space. Available: ${freeGB}GB" "ERROR"
    exit 1
}

Log "Prerequisites OK: Windows Build $build, ${freeGB}GB free" "SUCCESS"

# ============================================================================
# DEPLOYMENT
# ============================================================================
$state = Get-State
$startPhase = if ($Phase2 -or $state.phase -ge 2) { 2 } else { 1 }

try {
    # ========== PHASE 1: Core Installation ==========
    if ($startPhase -eq 1) {
        Invoke-Script "$InstallCore\Install-WindowsFeatures.ps1" "Enabling Windows Features (WSL2, Hyper-V)" $cfg | Out-Null
        Invoke-Script "$ConfigureWSL\Configure-WSL.ps1" "Configuring WSL2 (Mirrored Networking)" $cfg | Out-Null
        Invoke-Script "$InstallTools\Install-DevTools.ps1" "Installing Dev Tools (Git, Node, Python)" $cfg | Out-Null
        Invoke-Script "$InstallTools\Install-Terminal.ps1" "Installing Windows Terminal & Fonts" $cfg | Out-Null
        
        # Check if reboot needed
        $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
        if ($wslFeature -and $wslFeature.RestartNeeded -and !$SkipReboot) {
            $state = Get-State
            $state.phase = 2
            Save-State $state
            Log "REBOOT REQUIRED - Windows features need restart" "WARN"
            Log "Run this script again after reboot to continue" "WARN"
            Start-Sleep 3
            Restart-Computer -Force
            exit 0
        }
    }
    
    # ========== PHASE 2: WSL & Docker ==========
    Invoke-Script "$InstallCore\Install-WSLDistros.ps1" "Installing WSL Distributions (Ubuntu, Kali)" $cfg | Out-Null
    Invoke-Script "$InstallCore\Install-Docker.ps1" "Installing Docker Desktop" $cfg | Out-Null
    Invoke-Script "$ConfigureWSL\Configure-Firewall.ps1" "Configuring Firewall Rules" $cfg | Out-Null
    
    # ========== PHASE 3: Development Tools ==========
    Invoke-Script "$InstallTools\Install-VSCode.ps1" "Installing VS Code & Extensions" $cfg | Out-Null
    Invoke-Script "$InstallAI\Install-GitHubCopilot.ps1" "Installing GitHub CLI & Copilot CLI" $cfg | Out-Null
    Invoke-Script "$InstallAI\Install-Claude.ps1" "Installing Claude Desktop & Claude Code" $cfg | Out-Null
    
    # ========== PHASE 4: Configuration ==========
    Invoke-Script "$ConfigureEnv\Configure-Git.ps1" "Configuring Git" $cfg | Out-Null
    Invoke-Script "$ConfigureEnv\Configure-Environment.ps1" "Setting Environment Variables" $cfg | Out-Null
    Invoke-Script "$ConfigureTerminal\Configure-ShellProfiles.ps1" "Creating Shell Profiles" $cfg | Out-Null
    
    if ($cfg.install.oh_my_posh) {
        Invoke-Script "$ConfigureTerminal\Configure-OhMyPosh.ps1" "Installing Oh-My-Posh Theming" $cfg | Out-Null
    }
    
    # ========== PHASE 5: Authentication Guide ==========
    Invoke-Script "$ConfigureEnv\Setup-Authentication.ps1" "Authentication Setup" $cfg | Out-Null
    
    # Cleanup state file
    Remove-Item $StateFile -ErrorAction SilentlyContinue
    
    # ========== SUCCESS ==========
    Write-Host @"

  ╔═══════════════════════════════════════════════════════════════════╗
  ║                    ✓ DEPLOYMENT COMPLETE                          ║
  ╠═══════════════════════════════════════════════════════════════════╣
  ║                                                                   ║
  ║  Installed:                                                       ║
  ║    • WSL2 with Ubuntu & Kali Linux (mirrored networking)          ║
  ║    • Docker Desktop (WSL2 backend)                                ║
  ║    • VS Code + GitHub Copilot (Agent Mode enabled)                ║
  ║    • GitHub CLI + Copilot CLI (terminal AI agent)                 ║
  ║    • Claude Desktop + Claude Code                                 ║
  ║    • Oh-My-Posh terminal theming                                  ║
  ║                                                                   ║
  ║  Quick Commands:                                                  ║
  ║    copilot    - GitHub Copilot CLI (terminal AI)                  ║
  ║    claude     - Claude Code (terminal AI)                         ║
  ║    gh         - GitHub CLI                                        ║
  ║    wsl        - Enter Ubuntu                                      ║
  ║                                                                   ║
  ║  First-time Authentication:                                       ║
  ║    gh auth login     - GitHub CLI                                 ║
  ║    copilot → /login  - Copilot CLI                                ║
  ║    claude → /login   - Claude Code                                ║
  ║                                                                   ║
  ║  Log: $($Script:LogFile)
  ╚═══════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

}
catch {
    Log "Deployment failed: $_" "ERROR"
    Log "Check log file: $LogFile" "ERROR"
    exit 1
}
