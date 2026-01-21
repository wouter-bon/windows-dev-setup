# Windows Dev Environment Setup

**Automated deployment: WSL2 + Docker + GitHub Copilot CLI + Claude Code**

## Quick Start (3 Steps)

```powershell
# 1. Edit config (optional)
notepad config.json

# 2. Run as Administrator  
.\Deploy.ps1

# 3. After reboot, run again
.\Deploy.ps1
```

## What Gets Installed

- **WSL2** with mirrored networking (Ubuntu + Kali Linux)
- **Docker Desktop** with WSL2 backend
- **VS Code** + GitHub Copilot (Agent Mode enabled)
- **GitHub Copilot CLI** - Terminal AI agent (like Claude Code!)
- **Claude Code** - Anthropic's terminal AI agent
- **Oh-My-Posh** - Beautiful terminal theming

## First-time Authentication

After deployment, run these once:
```powershell
gh auth login           # GitHub CLI
copilot → /login        # Copilot CLI  
claude → /login         # Claude Code
```

## Documentation

See `docs/README.md` for full documentation.

---
*Edit `config.json` before running to customize installation.*
