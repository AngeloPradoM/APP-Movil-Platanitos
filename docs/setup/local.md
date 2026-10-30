# Ejecucion local

Desde la raiz, usa dos terminales:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-backend.ps1
```

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-frontend.ps1
```

Frontend: http://127.0.0.1:8080. API: http://127.0.0.1:3000/health.

Para Android, inicia el emulador y reemplaza el segundo comando por:

```powershell
flutter devices
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Consulta el [README principal](../../README.md) para instalacion y credenciales.
