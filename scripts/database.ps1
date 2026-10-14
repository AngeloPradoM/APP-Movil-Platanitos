param([switch]$Initialize, [switch]$Stop)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$localRoot = Join-Path $projectRoot '.local'
$dataPath = Join-Path $localRoot 'postgres-data'
$metadataPath = Join-Path $localRoot 'database.json'
if ($Initialize -and $Stop) { throw 'Usa -Initialize o -Stop, no ambos.' }
Push-Location $projectRoot
try {
    if (-not (Test-Path $metadataPath)) {
        if (-not $Initialize) { throw 'No hay una base aislada configurada. Ejecuta setup.ps1 -IsolatedDatabase.' }
        $pgInstall = Get-ChildItem 'C:\Program Files\PostgreSQL' -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName 'bin\initdb.exe') } | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
        if (-not $pgInstall) { throw 'Instala PostgreSQL para disponer de initdb y pg_ctl, o utiliza tu servidor en backend/.env.' }
        $envPath = Join-Path $projectRoot 'backend\.env'
        if (-not (Test-Path $envPath)) { throw 'Falta backend/.env. Ejecuta setup.ps1 primero.' }
        $envText = Get-Content $envPath -Raw
        if ($envText -notmatch '(?m)^DATABASE_URL=.*(?:USUARIO|CONTRASENA)') { throw 'DATABASE_URL ya está configurada. Se conserva; para la base aislada utiliza una copia con los valores de ejemplo.' }
        if (Test-Path $dataPath) { throw 'Ya existe un directorio de datos sin metadatos. Se conserva; revisa .local antes de continuar.' }
        New-Item -ItemType Directory -Force -Path $localRoot | Out-Null
        node -e "const fs=require('fs'),crypto=require('crypto');const password=crypto.randomBytes(32).toString('base64url');fs.writeFileSync('.local/postgres-password.txt',password);let s=fs.readFileSync('backend/.env','utf8');s=s.replace(/^DATABASE_URL=.*$/m,'DATABASE_URL=postgresql://platanitos_local:'+password+'@127.0.0.1:5433/platanitos');fs.writeFileSync('backend/.env',s);"
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo generar la configuración local.' }
        @{ bin = (Join-Path $pgInstall.FullName 'bin'); port = 5433; user = 'platanitos_local' } | ConvertTo-Json | Set-Content $metadataPath -Encoding utf8
    }
    $metadata = Get-Content $metadataPath -Raw | ConvertFrom-Json
    $pgCtl = Join-Path $metadata.bin 'pg_ctl.exe'
    if (-not (Test-Path $pgCtl)) { throw 'No se encuentran los binarios PostgreSQL registrados en .local/database.json.' }
    if (-not (Test-Path (Join-Path $dataPath 'PG_VERSION'))) {
        if (-not $Initialize) { throw 'La base aislada no está inicializada. Ejecuta setup.ps1 -IsolatedDatabase.' }
        $passwordPath = Join-Path $localRoot 'postgres-password.txt'
        & (Join-Path $metadata.bin 'initdb.exe') -D $dataPath -U $metadata.user "--pwfile=$passwordPath" --auth=scram-sha-256 --encoding=UTF8 --locale=C
        if ($LASTEXITCODE -ne 0) { throw 'No fue posible inicializar la base aislada. Se conservan los archivos para revisar el error.' }
        Add-Content (Join-Path $dataPath 'postgresql.conf') -Value "`ntimezone = 'America/Lima'`nlog_timezone = 'America/Lima'" -Encoding ascii
        Remove-Item -LiteralPath $passwordPath
    }
    & $pgCtl -D $dataPath status
    $running = $LASTEXITCODE -eq 0
    if ($Stop) {
        if ($running) { & $pgCtl -D $dataPath -m fast -w stop; if ($LASTEXITCODE -ne 0) { throw 'No se pudo detener la base aislada.' } }
        return
    }
    if (-not $running) {
        & $pgCtl -D $dataPath -l (Join-Path $localRoot 'postgres.log') -o "-h 127.0.0.1 -p $($metadata.port)" -w start
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo iniciar PostgreSQL. Revisa .local/postgres.log y el puerto 5433.' }
    }
    Write-Host "PostgreSQL aislado disponible en 127.0.0.1:$($metadata.port)."
} finally { Pop-Location }
