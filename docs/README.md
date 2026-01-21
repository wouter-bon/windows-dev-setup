# Windows Development Environment Setup

Fully automated deployment of a modern Windows development environment.

## What's Included

| Category | Components |
|----------|------------|
| **Virtualization** | WSL2 (mirrored networking), Hyper-V |
| **Distributions** | Ubuntu 24.04 LTS, Kali Linux |
| **Containers** | Docker Desktop (WSL2 backend) |
| **AI Assistants** | GitHub Copilot CLI, Claude Code, VS Code Copilot |
| **Dev Tools** | Git, Node.js, Python, Rust, PowerShell 7 |
| **Terminal** | Windows Terminal, Oh-My-Posh, Nerd Fonts |

## Quick Start

### 1. Edit Configuration (Optional)
```powershell
notepad config.json   # Customize settings
```

### 2. Run as Administrator
```powershell
# Open PowerShell as Administrator
cd C:\path\to\windows-dev-setup
.\Deploy.ps1
```

### 3. Reboot When Prompted
The script automatically reboots if Windows features need activation.
**Run the script again after reboot** - it resumes automatically.

### 4. Authenticate Services (One-time)
```powershell
gh auth login           # GitHub CLI
copilot                 # Then type: /login
claude                  # Then type: /login
```

---

## Folder Structure

```
windows-dev-setup/
├── Deploy.ps1                              # Main entry point
├── config.json                             # Configuration file
│
├── install/
│   ├── core/
│   │   ├── Install-WindowsFeatures.ps1    # WSL2, Hyper-V
│   │   ├── Install-WSLDistros.ps1         # Ubuntu, Kali
│   │   └── Install-Docker.ps1             # Docker Desktop
│   │
│   ├── tools/
│   │   ├── Install-DevTools.ps1           # Git, Node, Python
│   │   ├── Install-Terminal.ps1           # Windows Terminal, Fonts
│   │   └── Install-VSCode.ps1             # VS Code + Extensions
│   │
│   └── ai-assistants/
│       ├── Install-GitHubCopilot.ps1      # gh CLI, Copilot CLI
│       └── Install-Claude.ps1             # Claude Desktop/Code
│
├── configure/
│   ├── wsl/
│   │   ├── Configure-WSL.ps1              # .wslconfig (mirrored)
│   │   └── Configure-Firewall.ps1         # Hyper-V firewall
│   │
│   ├── terminal/
│   │   ├── Configure-ShellProfiles.ps1    # PowerShell/Bash
│   │   └── Configure-OhMyPosh.ps1         # Terminal theming
│   │
│   └── environment/
│       ├── Configure-Git.ps1              # Git settings
│       ├── Configure-Environment.ps1      # Env variables
│       └── Setup-Authentication.ps1       # Auth guide
│
├── docs/
│   └── bash_profile_additions.sh          # WSL Bash config
│
└── logs/                                   # Deployment logs
```

---

## Configuration

### Key Settings in `config.json`

```json
{
    "user": {
        "name": "Your Name",
        "email": "your.email@example.com"
    },
    "resources": {
        "wsl_memory_gb": "auto",      // Auto-detects 60% of RAM
        "wsl_processors": "auto"       // Auto-detects 60% of cores
    },
    "install": {
        "wsl_kali": true,             // Include Kali Linux
        "oh_my_posh": true            // Terminal theming
    },
    "security": {
        "disable_telemetry": true,     // Privacy-focused
        "firewall_mode": "specific_ports"
    }
}
```

---

## AI Terminal Agents

### GitHub Copilot CLI
Works like Claude Code - a terminal AI agent that can read/write files:
```bash
copilot                    # Start session
> help me refactor this code
> write tests for auth module
/model                     # Switch AI model
/delegate                  # Cloud agent mode
```

### Claude Code
Anthropic's terminal AI agent:
```bash
claude                     # Start session
> create a REST API
> explain this codebase
/model                     # Select model (Sonnet, Opus, Haiku)
```

### VS Code Copilot (Agent Mode)
1. Press `Ctrl+Shift+I` → Open Copilot Chat
2. Select "Agent" mode
3. Ask it to build features, run tests, refactor code

---

## Quick Command Reference

```powershell
# AI Assistants
copilot              # GitHub Copilot CLI
claude               # Claude Code
gh copilot           # Copilot via GitHub CLI

# WSL
wsl                  # Enter Ubuntu
wsl -d kali-linux    # Enter Kali
wsl --shutdown       # Restart WSL

# Docker
docker ps            # Running containers
docker compose up    # Start stack

# Git (aliases)
gs                   # git status
glog                 # git log --graph
gp                   # git push
gl                   # git pull
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Script fails first run | Normal - reboot and run again |
| `copilot` not found | `npm install -g @github/copilot` |
| `claude` not found | Install from code.claude.ai |
| WSL networking issues | Check `~/.wslconfig`, run `wsl --shutdown` |
| Docker won't start | Verify WSL2: `wsl -l -v` |

---

## Running Individual Scripts

Each component can be installed separately:

```powershell
# Core
.\install\core\Install-WindowsFeatures.ps1
.\install\core\Install-WSLDistros.ps1
.\install\core\Install-Docker.ps1

# Tools
.\install\tools\Install-DevTools.ps1
.\install\tools\Install-VSCode.ps1

# AI
.\install\ai-assistants\Install-GitHubCopilot.ps1
.\install\ai-assistants\Install-Claude.ps1

# Configuration
.\configure\wsl\Configure-WSL.ps1
.\configure\environment\Configure-Git.ps1
```

---

## System Requirements

- Windows 11 (Build 22000+) for mirrored networking
- 30GB+ free disk space
- Hardware virtualization enabled in BIOS
- Internet connection

---

Generated: January 2026
