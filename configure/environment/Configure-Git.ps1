<#
.SYNOPSIS
    Configure-Git.ps1 - Configure Git globally with best practices
#>
$ErrorActionPreference = "Stop"
$cfg = $env:DEPLOY_CONFIG | ConvertFrom-Json

Write-Host "  Configuring Git..." -ForegroundColor Gray

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (!$gitCmd) {
    Write-Host "    Git not found - skipping configuration" -ForegroundColor Yellow
    exit 0
}

# User configuration
Write-Host "    Setting user identity..." -ForegroundColor DarkGray
git config --global user.name "$($cfg.user.name)"
git config --global user.email "$($cfg.user.email)"

# Core settings
Write-Host "    Setting core options..." -ForegroundColor DarkGray
git config --global core.editor "code --wait"
git config --global core.autocrlf input
git config --global core.safecrlf warn
git config --global core.longpaths true
git config --global core.pager "less -FRX"

# Init
git config --global init.defaultBranch main

# Pull/Push
git config --global pull.rebase true
git config --global push.default current
git config --global push.autoSetupRemote true

# Fetch
git config --global fetch.prune true
git config --global fetch.pruneTags true

# Merge/Diff
git config --global merge.conflictStyle diff3
git config --global diff.colorMoved default

# Credential manager
git config --global credential.helper manager

# Aliases
Write-Host "    Setting aliases..." -ForegroundColor DarkGray
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.cm "commit -m"
git config --global alias.lg "log --oneline --graph --decorate -20"
git config --global alias.last "log -1 HEAD --stat"
git config --global alias.unstage "reset HEAD --"
git config --global alias.amend "commit --amend --no-edit"
git config --global alias.wip "!git add -A && git commit -m 'WIP'"

# Color
git config --global color.ui auto

# Help
git config --global help.autocorrect prompt

# Display configuration summary
Write-Host "`n    Git configuration:" -ForegroundColor Cyan
Write-Host "      user.name  = $($cfg.user.name)" -ForegroundColor DarkGray
Write-Host "      user.email = $($cfg.user.email)" -ForegroundColor DarkGray
Write-Host "      default branch = main" -ForegroundColor DarkGray
Write-Host "      pull.rebase = true" -ForegroundColor DarkGray

Write-Host "  Git configured" -ForegroundColor Green
exit 0
