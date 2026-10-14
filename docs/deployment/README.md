# Compilacion y despliegue

La ejecucion local se explica en [setup/local.md](../setup/local.md).

Desde la raiz, genera Flutter Web con la URL de tu API:

```powershell
flutter build web --dart-define=API_BASE_URL=https://api.example.com
```

Los archivos se generan en build/web. Para Android usa flutter build apk o flutter build appbundle con el mismo parametro API_BASE_URL.

Desde backend, npm.cmd run build genera dist y npm.cmd run start:prod ejecuta el servidor compilado. Configura las variables de entorno, aplica las migraciones y permite el origen publico en CORS_ORIGINS.

Esta reorganizacion no publica servicios en la nube.
