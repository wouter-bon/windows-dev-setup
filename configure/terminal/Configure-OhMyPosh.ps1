<#
.SYNOPSIS
    Configure-OhMyPosh.ps1 - Install and configure Oh-My-Posh terminal theming
#>
$ErrorActionPreference = "Stop"
$cfg = $env:DEPLOY_CONFIG | ConvertFrom-Json

if (!$cfg.install.oh_my_posh) {
    Write-Host "  Oh-My-Posh installation skipped (disabled in config)" -ForegroundColor Yellow
    exit 0
}

Write-Host "  Installing Oh-My-Posh..." -ForegroundColor Gray

$ompCmd = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if (!$ompCmd) {
    winget install --id JanDeDobbeleer.OhMyPosh --silent --accept-package-agreements --accept-source-agreements 2>$null
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "    Oh-My-Posh installed" -ForegroundColor Green
} else {
    Write-Host "    Oh-My-Posh already installed" -ForegroundColor DarkGray
}

# Create custom theme
Write-Host "  Creating custom theme..." -ForegroundColor Gray

$customTheme = @'
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [
    {
      "alignment": "left",
      "segments": [
        {
          "type": "session",
          "style": "diamond",
          "foreground": "#ffffff",
          "background": "#6272a4",
          "leading_diamond": "\ue0b6",
          "template": " {{ .UserName }} "
        },
        {
          "type": "path",
          "style": "powerline",
          "foreground": "#ffffff",
          "background": "#bd93f9",
          "powerline_symbol": "\ue0b0",
          "properties": { "style": "folder" },
          "template": " {{ .Path }} "
        },
        {
          "type": "git",
          "style": "powerline",
          "foreground": "#ffffff",
          "background": "#50fa7b",
          "powerline_symbol": "\ue0b0",
          "background_templates": ["{{ if or (.Working.Changed) (.Staging.Changed) }}#ffb86c{{ end }}"],
          "properties": { "branch_icon": "\ue725 ", "fetch_status": true },
          "template": " {{ .HEAD }}{{ if .Working.Changed }} \uf044{{ end }}{{ if .Staging.Changed }} \uf046{{ end }} "
        },
        {
          "type": "docker",
          "style": "powerline",
          "foreground": "#ffffff",
          "background": "#0db7ed",
          "powerline_symbol": "\ue0b0",
          "template": " \uf308 {{ .Context }} "
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "right",
      "segments": [
        {
          "type": "node",
          "style": "plain",
          "foreground": "#6ca35e",
          "template": "\ue718 {{ .Full }} "
        },
        {
          "type": "python",
          "style": "plain",
          "foreground": "#3776ab",
          "template": "\ue235 {{ .Full }} "
        },
        {
          "type": "executiontime",
          "style": "plain",
          "foreground": "#ffb86c",
          "properties": { "threshold": 500 },
          "template": " \uf252 {{ .FormattedMs }} "
        },
        {
          "type": "time",
          "style": "plain",
          "foreground": "#8be9fd",
          "template": " {{ .CurrentDate | date .Format }} ",
          "properties": { "time_format": "15:04" }
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "left",
      "newline": true,
      "segments": [
        {
          "type": "text",
          "style": "plain",
          "foreground_templates": ["{{ if gt .Code 0 }}#ff5555{{ else }}#50fa7b{{ end }}"],
          "template": "❯ "
        }
      ],
      "type": "prompt"
    }
  ],
  "version": 2
}
'@

$themesDir = Join-Path $env:USERPROFILE ".config\oh-my-posh\themes"
if (!(Test-Path $themesDir)) {
    New-Item -ItemType Directory -Path $themesDir -Force | Out-Null
}

$customThemePath = Join-Path $themesDir "devenv.omp.json"
$customTheme | Set-Content -Path $customThemePath -Encoding UTF8
Write-Host "    Theme created: $customThemePath" -ForegroundColor DarkGray

Write-Host "  Oh-My-Posh configured" -ForegroundColor Green
Write-Host "    Restart terminal to see new prompt" -ForegroundColor Yellow
exit 0
