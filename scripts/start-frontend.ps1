param(
    [string]$Device = 'chrome',
    [ValidateSet('demo', 'remote')][string]$AppMode = 'demo',
    [string]$ApiBaseUrl = '',
    [switch]$SkipApiCheck
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$flutterCommand = Join-Path 'C:\dev\flutter' 'bin\flutter.bat'
if (-not (Test-Path $flutterCommand)) { $flutterCommand = (Get-Command flutter -ErrorAction Stop).Source }

if ($AppMode -eq 'remote' -and -not $ApiBaseUrl) {
    $port = 3000
    $envFile = Join-Path $projectRoot 'backend\.env'
    if (Test-Path $envFile) {
        $portLine = Get-Content $envFile | Where-Object { $_ -match '^\s*PORT\s*=\s*\d+\s*$' } | Select-Object -First 1
        if ($portLine) { $port = [int](($portLine -split '=', 2)[1].Trim()) }
    }
    $ApiBaseUrl = if ($Device -in @('chrome', 'edge', 'windows', 'web-server')) { "http://127.0.0.1:$port" } else { "http://10.0.2.2:$port" }
}

if ($ApiBaseUrl) { $ApiBaseUrl = $ApiBaseUrl.TrimEnd('/') }
if ($AppMode -eq 'remote' -and $Device -in @('chrome', 'edge', 'windows', 'web-server') -and -not $SkipApiCheck) {
    Write-Host "Esperando API: $ApiBaseUrl/health"
    $ready = $false
    $deadline = (Get-Date).AddSeconds(60)
    while ((Get-Date) -lt $deadline) {
        try {
            $health = Invoke-RestMethod -Uri "$ApiBaseUrl/health" -TimeoutSec 2
            if ($health.status -eq 'ok') { $ready = $true; break }
        } catch { Start-Sleep -Seconds 1 }
    }
    if (-not $ready) { throw 'La API no responde. Inicia el backend en otra terminal y revisa DATABASE_URL.' }
}

Push-Location $projectRoot
try {
    $flutterArgs = @('run', '-d', $Device, "--dart-define=APP_MODE=$AppMode")
    if ($AppMode -eq 'remote') { $flutterArgs += "--dart-define=API_BASE_URL=$ApiBaseUrl" }
    if ($Device -in @('chrome', 'edge', 'web-server')) { $flutterArgs += @('--web-port', '8080', '--web-hostname', '127.0.0.1') }
    & $flutterCommand @flutterArgs
    if ($LASTEXITCODE -ne 0) { throw 'Flutter terminó con errores.' }
} finally { Pop-Location }
