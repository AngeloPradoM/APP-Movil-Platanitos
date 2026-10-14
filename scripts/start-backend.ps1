$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$backendRoot = Join-Path $projectRoot 'backend'
$npmCommand = (Get-Command npm.cmd -ErrorAction Stop).Source
Push-Location $backendRoot
try {
    if (-not (Test-Path 'node_modules')) { throw 'Faltan dependencias. Ejecuta scripts/setup.ps1 primero.' }
    if (Test-Path (Join-Path $projectRoot '.local\database.json')) { & (Join-Path $PSScriptRoot 'database.ps1') }
    node scripts/check-local.mjs --database
    if ($LASTEXITCODE -ne 0) { throw 'El backend no puede iniciar hasta resolver la configuración o la conexión indicadas.' }
    & $npmCommand run start:dev
    if ($LASTEXITCODE -ne 0) { throw 'El backend terminó con errores.' }
} finally { Pop-Location }

