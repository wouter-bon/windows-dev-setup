# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PowerShell-based automated deployment system for Windows development environments. Installs and configures WSL2, Docker Desktop, VS Code, AI assistants (GitHub Copilot CLI, Claude Code), and terminal theming.

## Commands

### Main Deployment
```powershell
.\Deploy.ps1                    # Run full deployment (requires Administrator)
.\Deploy.ps1 -Force             # Re-run already completed steps
.\Deploy.ps1 -SkipReboot        # Don't auto-reboot when features need activation
.\Deploy.ps1 -Phase2            # Resume from phase 2 after reboot
```

### Individual Scripts
Individual scripts require `$env:DEPLOY_CONFIG` to be set by Deploy.ps1 - they cannot run standalone. To test a single script, run the full deployment with `-Force`.

## Architecture

### Deployment Phases
`Deploy.ps1` orchestrates installation in 6 phases:
1. **Phase 1**: Windows features (WSL2, Hyper-V), WSL config, dev tools, terminal - may require reboot
2. **Phase 2**: WSL distributions (Ubuntu 24.04 LTS, Kali Linux)
3. **Phase 3**: Docker Desktop with WSL2 backend
4. **Phase 4**: VS Code + extensions, AI assistants
5. **Phase 5**: Git config, environment variables, shell profiles, Oh-My-Posh
6. **Phase 6**: Authentication guide display

### State Management
- `.state.json` tracks completed deployment steps for resumability after reboots
- Scripts are idempotent - safe to re-run
- State file is auto-created in the repo root during deployment

### Configuration Flow
- `config.json` is the central configuration file
- Main orchestrator serializes config to `$env:DEPLOY_CONFIG` for child scripts
- Child scripts deserialize with `$config = $env:DEPLOY_CONFIG | ConvertFrom-Json`

### Script Structure
All PowerShell scripts follow a consistent pattern:
- `.SYNOPSIS` comment block at top
- Read config from `$env:DEPLOY_CONFIG`
- Color-coded console output (Write-Host with -ForegroundColor)
- Return exit codes (0 = success, non-zero = failure)
- Log to both console and `logs/` directory

### Key Patterns
- **Package installation priority**: Winget > npm > direct download
- **Resource auto-detection**: WSL memory/CPU defaults to 60% of system resources (capped at 16GB/8 cores)
- **Path management**: Scripts prepend to PATH rather than replace

## Key Files

- `config.json` - User settings (edit before deployment)
- `Deploy.ps1` - Main orchestrator with phase management
- `.state.json` - Deployment progress (auto-generated)
- `docs/bash_profile_additions.sh` - Template copied to Ubuntu's .bashrc

## Coding Conventions

### Avoid Unicode Characters
Use ASCII only in PowerShell strings. Unicode symbols (`✓`, `→`, `○`, `✗`) cause parsing errors in some PowerShell environments. Use alternatives:
- `[OK]` instead of `✓`
- `[X]` instead of `✗`
- `->` or descriptive text instead of `→`

### Handle OneDrive-Redirected Paths
The `$PROFILE` variable may point to OneDrive (`OneDrive - Company\Documents\...`). Always wrap profile operations in try/catch with a fallback to `$env:USERPROFILE\Documents\...`.

### Firewall Port Arrays
`New-NetFirewallRule -LocalPort` expects a comma-separated string, not an array. Convert config arrays:
```powershell
$ports = if ($cfg.security.allowed_ports -is [array]) {
    $cfg.security.allowed_ports -join ','
} else {
    $cfg.security.allowed_ports
}
```

### Locked File Handling
When copying files that may be in use (fonts, configs), check if destination exists with same size before copying, and wrap in try/catch to skip gracefully.

### Config Property Access
Always validate `$cfg.resources.allocation_percent` and similar values are within valid ranges before using in calculations to avoid division by zero.

### GitHub Copilot CLI Authentication
The Copilot CLI requires the `copilot` OAuth scope. Default `gh auth login` doesn't include it. Users will see "Failed to get token" errors without it.
- Initial auth: `gh auth login -s copilot`
- Add scope later: `gh auth refresh -s copilot`
- Helper function: `copilot-refresh` (added to PowerShell profile)
