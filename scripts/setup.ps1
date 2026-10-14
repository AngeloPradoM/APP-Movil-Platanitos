param([switch]$SkipDatabase, [switch]$IncludeCatalog, [switch]$IsolatedDatabase)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$backendRoot = Join-Path $projectRoot 'backend'
$npmCommand = (Get-Command npm.cmd -ErrorAction Stop).Source
$flutterCommand = Join-Path 'C:\dev\flutter' 'bin\flutter.bat'
if (-not (Test-Path $flutterCommand)) { $flutterCommand = (Get-Command flutter -ErrorAction Stop).Source }
function Assert-Success([string]$Step) { if ($LASTEXITCODE -ne 0) { throw "Falló: $Step. Revisa el mensaje anterior." } }
Push-Location $projectRoot
try {
    if (-not (Test-Path (Join-Path $backendRoot '.env'))) {
        node -e "const fs=require('fs'),crypto=require('crypto');let s=fs.readFileSync('backend/.env.example','utf8');s=s.replace(/^JWT_ACCESS_SECRET=.*$/m,'JWT_ACCESS_SECRET='+crypto.randomBytes(48).toString('base64url'));fs.writeFileSync('backend/.env',s);"
        Assert-Success 'crear .env'
    }
    Write-Host 'Preparando Flutter...'
    & $flutterCommand pub get
    Assert-Success 'flutter pub get'
    Push-Location $backendRoot
    try {
        Write-Host 'Instalando backend desde package-lock.json...'
        & $npmCommand ci
        Assert-Success 'npm ci'
        & (Join-Path $backendRoot 'node_modules\.bin\prisma.cmd') generate
        Assert-Success 'generar Prisma'
        if (-not $SkipDatabase) {
            if ($IsolatedDatabase) { & (Join-Path $PSScriptRoot 'database.ps1') -Initialize } elseif (Test-Path (Join-Path $projectRoot '.local\database.json')) { & (Join-Path $PSScriptRoot 'database.ps1') }
            node scripts/check-local.mjs
            Assert-Success 'configuración .env'
            & $npmCommand run db:setup
            Assert-Success 'preparar base de datos'
            if ($IncludeCatalog) {
                & $npmCommand run db:catalog
                Assert-Success 'cargar catálogo ampliado'
            }
            node scripts/check-local.mjs --database
            Assert-Success 'comprobar PostgreSQL'
        }
    } finally { Pop-Location }
    Write-Host 'Dependencias listas. Usa las tareas de VS Code o scripts/start-backend.ps1 y scripts/start-frontend.ps1.'
    if ($SkipDatabase) { Write-Host 'Base de datos pendiente: configura backend/.env y vuelve a ejecutar sin -SkipDatabase.' }
} finally { Pop-Location }

