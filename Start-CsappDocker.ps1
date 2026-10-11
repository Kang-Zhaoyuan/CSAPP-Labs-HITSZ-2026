# UTF-8
[CmdletBinding()]
param()

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  Starting CSAPP Architecture Lab Container...      " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

$dockerCli = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'

$env:APPDATA = 'C:\tmp\DockerAppData\Roaming'
$env:LOCALAPPDATA = 'C:\tmp\DockerAppData\Local'
$env:HOME = 'C:\tmp\DockerHome'
$env:USERPROFILE = 'C:\Users\kqdx'
$env:Path = 'C:\Program Files\Docker\Docker\resources\bin;' + $env:Path
$env:DOCKER_CONTEXT = 'desktop-linux'

$ready = $false
try {
    $ver = (& $dockerCli --context desktop-linux version --format '{{.Server.Version}}' 2>$null)
    if ($LASTEXITCODE -eq 0 -and $ver) { $ready = $true }
} catch { $ready = $false }

if (-not $ready) {
    Write-Host "[1/2] Starting Docker daemon..." -ForegroundColor Yellow
    if (-not (Get-Process -Name 'com.docker.backend' -ErrorAction SilentlyContinue)) {
        Start-Process "C:\Program Files\Docker\Docker\resources\com.docker.backend.exe" -WindowStyle Hidden
    }
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 1
        try {
            $ver = (& $dockerCli --context desktop-linux version --format '{{.Server.Version}}' 2>$null)
            if ($LASTEXITCODE -eq 0 -and $ver) { $ready = $true; break }
        } catch {}
    }
}

if (-not $ready) {
    Write-Host "[ERROR] Could not connect to Docker. Please ensure Docker Desktop is open." -ForegroundColor Red
    return
}

Write-Host "[2/2] Checking csapp-env container..." -ForegroundColor Yellow
$status = (& $dockerCli ps --filter "name=csapp-env" --format "{{.Status}}" 2>$null)
if (-not $status) {
    Write-Host "Starting csapp-env container on port 2224..." -ForegroundColor Yellow
    & $dockerCli rm -f csapp-env 2>$null | Out-Null
    & $dockerCli run -d --name csapp-env `
        -p 127.0.0.1:2224:22 `
        -v "D:\HIT\CSAPP:/workspace" `
        -v "C:\Users\kqdx\Documents\Codex\2026-09-06\qemu-docker-qemu\outputs\qemu-ubuntu-qemu\ssh:/ssh:ro" `
        -w /workspace `
        --entrypoint /bin/bash `
        local/qemu-ubuntu:24.04-codex `
        /workspace/start_csapp_container.sh | Out-Null
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  [SUCCESS] CSAPP Environment is Ready!             " -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host "Access via SSH from anywhere in terminal:" -ForegroundColor White
Write-Host "   ssh csapp-docker" -ForegroundColor Yellow
Write-Host ""
Write-Host "Entering container now..." -ForegroundColor Cyan
ssh csapp-docker
