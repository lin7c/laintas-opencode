# Laintas for OpenCode — one-command install (Windows, PowerShell).
#
# 1. If OpenCode is not installed, installs the official OpenCode binary
#    (pinned version, downloaded from the OpenCode project's own GitHub
#    releases — OpenCode is MIT-licensed, see https://github.com/sst/opencode).
# 2. Installs the Laintas plugin into OpenCode's local plugin directory.
# 3. Merges the Laintas provider entry into the global OpenCode config.
#
# Safe to re-run: existing config keys are never touched.
# Run:  irm https://raw.githubusercontent.com/lin7c/opencode-laintas/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'
$OpenCodeVersion = '1.19.5'
$PluginUrl = 'https://raw.githubusercontent.com/lin7c/opencode-laintas/main/index.ts'
$InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\opencode'
$ConfigDir = Join-Path $env:USERPROFILE '.config\opencode'
$ConfigFile = Join-Path $ConfigDir 'opencode.json'
$PluginFile = Join-Path $ConfigDir 'plugin\laintas.ts'

# ---------- 1. OpenCode itself ----------
if (Get-Command opencode -ErrorAction SilentlyContinue) {
    Write-Host "OpenCode found: $(opencode --version)"
} else {
    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
    Write-Host "Installing OpenCode $OpenCodeVersion (windows-$arch)..."
    $zip = Join-Path $env:TEMP "opencode-windows-$arch.zip"
    Invoke-WebRequest -Uri "https://github.com/sst/opencode/releases/download/v$OpenCodeVersion/opencode-windows-$arch.zip" -OutFile $zip
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    Expand-Archive -Path $zip -DestinationPath $InstallDir -Force
    Remove-Item $zip -Force
    $exe = Join-Path $InstallDir 'opencode.exe'
    # Very old x86_64 CPUs need the baseline build; swap automatically.
    $runs = $false
    try { & $exe --version | Out-Null; $runs = $true } catch { $runs = $false }
    if (-not $runs -and $arch -eq 'x64') {
        Write-Host 'Standard build does not run on this CPU; fetching the baseline build...'
        $zip = Join-Path $env:TEMP 'opencode-windows-x64-baseline.zip'
        Invoke-WebRequest -Uri "https://github.com/sst/opencode/releases/download/v$OpenCodeVersion/opencode-windows-x64-baseline.zip" -OutFile $zip
        Expand-Archive -Path $zip -DestinationPath $InstallDir -Force
        Remove-Item $zip -Force
    }
    Write-Host "OpenCode installed: $(& $exe --version)"
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (($userPath -split ';') -notcontains $InstallDir) {
        [Environment]::SetEnvironmentVariable('Path', "$userPath;$InstallDir", 'User')
        Write-Host "Added $InstallDir to your PATH — open a new terminal before running opencode."
    }
}

# ---------- 2. Laintas plugin ----------
New-Item -ItemType Directory -Force -Path (Split-Path $PluginFile) | Out-Null
Write-Host 'Installing the Laintas plugin...'
Invoke-WebRequest -Uri $PluginUrl -OutFile $PluginFile

# ---------- 3. Provider config (merge, never overwrite other keys) ----------
if (Test-Path $ConfigFile) {
    $cfg = Get-Content $ConfigFile -Raw | ConvertFrom-Json
} else {
    $cfg = [pscustomobject]@{}
}
if (-not $cfg.PSObject.Properties['$schema']) {
    $cfg | Add-Member -NotePropertyName '$schema' -NotePropertyValue 'https://opencode.ai/config.json'
}
if (-not $cfg.PSObject.Properties['provider']) {
    $cfg | Add-Member -NotePropertyName 'provider' -NotePropertyValue ([pscustomobject]@{})
}
$laintas = [pscustomobject]@{
    npm     = '@ai-sdk/openai-compatible'
    name    = 'Laintas'
    options = [pscustomobject]@{ baseURL = 'https://laintas.com/v1' }
    models  = [pscustomobject]@{}
}
if ($cfg.provider.PSObject.Properties['laintas']) {
    $cfg.provider.laintas = $laintas
} else {
    $cfg.provider | Add-Member -NotePropertyName 'laintas' -NotePropertyValue $laintas
}
$cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigFile -Encoding UTF8
Write-Host "Laintas provider configured in $ConfigFile"

Write-Host ''
Write-Host 'Done. Now sign in and pick a model:'
Write-Host ''
Write-Host '  opencode auth login     # choose "Laintas" -> "Sign in with Laintas"'
Write-Host '  opencode                # then /models to pick a Laintas model'
Write-Host ''
Write-Host 'Your Laintas account balance is what gets billed — there is no API key.'
