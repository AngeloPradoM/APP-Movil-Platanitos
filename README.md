# Platanitos — Aplicación de comercio electrónico

**Proyecto académico universitario · Flutter (Android y web) · Versión `1.0.0+1`**

Aplicación multiservicio que simula una tienda en línea y sus operaciones de almacén, reparto, atención al cliente, administración y tienda física.

> **Inicio rápido:** la aplicación funciona de forma predeterminada en **modo demo**. No necesita backend, PostgreSQL ni archivo `.env` para ejecutarse.

## 1. Cómo levantar el proyecto

### Requisitos

- **Obligatorio:** [Flutter SDK](https://docs.flutter.dev/install/quick) (versión verificada: `3.47.6`, canal estable) y Git.
- **Para web:** Google Chrome.
- **Para Android:** Android Studio, SDK de Android y un emulador o dispositivo conectado.
- **Solo para el modo remoto:** Node.js `20+` y PostgreSQL `14+`.

Comprueba la instalación de Flutter con `flutter doctor`.

### Ejecutar en Chrome (recomendado)

Abre **PowerShell** o la terminal de VS Code y ejecuta:

```powershell
git clone https://github.com/AngeloPradoM/APP-Movil-Platanitos.git
cd APP-Movil-Platanitos
flutter pub get
flutter run -d chrome
```

Si ya tienes el repositorio descargado, abre su carpeta y ejecuta únicamente los dos últimos comandos.

### Ejecutar en Android

Desde la raíz del proyecto:

```powershell
flutter emulators                         # Lista los emuladores disponibles
flutter emulators --launch <id-emulador>  # Inicia uno de la lista
flutter devices                           # Muestra el identificador del dispositivo
flutter run -d <id-dispositivo>           # Ejecuta la app
```

También puedes iniciar el emulador desde **Android Studio → Device Manager**. Sustituye los identificadores entre `< >` por los que aparezcan en tu equipo (por ejemplo, `emulator-5554`).

### Ejecutar desde VS Code

Abre **Terminal → Ejecutar tarea → `Platanitos: frontend`** para iniciar la demostración local.

## 2. Credenciales de prueba

Al abrir la aplicación, selecciona uno de los perfiles de demostración:

| Perfil | Usuario | Contraseña | Acceso |
| --- | --- | --- | --- |
| **Cliente** | `cliente@demo.local` | `Cliente123` | Catálogo, carrito, compras simuladas, pedidos y posventa |
| **Almacén** | Acceso directo | No requiere | Stock, preparación y despacho |
| **Repartidor** | Acceso directo | No requiere | Recojo, ruta, entrega e incidencias |
| **Atención al cliente** | Acceso directo | No requiere | Cambios, devoluciones y reclamos |
| **Administrador** | Acceso directo | No requiere | Indicadores y reportes |
| **Trabajador de tienda** | Acceso directo | No requiere | Reservas y confirmación de recojo |

**Importante:** estas credenciales y accesos pertenecen **solo al modo demo**. No son cuentas reales ni sirven para autenticarse automáticamente en el backend remoto.

Para cambiar de perfil, cierra la sesión actual y selecciona otro desde la pantalla inicial.

## 3. Información del sistema

| Elemento | Descripción |
| --- | --- |
| Tipo | Prototipo académico de comercio electrónico multiservicio |
| Paquete | `platanitos_app` |
| Frontend | Flutter y Dart (Chrome y Android) |
| Modo predeterminado | `APP_MODE=demo` (sin API ni base de datos externa) |
| Datos en Android | SQLite local: `platanitos_demo.db` |
| Datos en Chrome | Adaptador en memoria; se pierden al cerrar la ejecución |
| Backend disponible | NestJS 12 + Prisma 7 + PostgreSQL; integración opcional con `APP_MODE=remote` |
| API local | `http://localhost:3000` en el modo remoto |
| Repositorio | [AngeloPradoM/APP-Movil-Platanitos](https://github.com/AngeloPradoM/APP-Movil-Platanitos) |
| Rama documentada | `develop` |

**Funciones principales:** catálogo y filtros, favoritos, bolsa, checkout simulado, pedidos, inventario y despacho, entregas, posventa, reservas en tienda, indicadores administrativos, puntos, monedero, membresía y tarjetas de regalo.

**Alcance actual:** los pagos, el reparto y el seguimiento son simulados. No se procesa dinero real; la geolocalización y la autenticación con Google/Apple no están integradas de forma real. La aplicación fue verificada en Chrome y Android.

## 4. Conectar el backend (opcional)

Esta sección es **solo para probar la integración HTTP**. Para usar la demo normal, puedes omitirla.

### Preparar NestJS y PostgreSQL

1. Asegúrate de que PostgreSQL esté instalado y en ejecución.
2. Desde la raíz del repositorio, configura el backend en PowerShell:

```powershell
cd backend
npm install
Copy-Item .env.example .env
```

3. En `backend/.env`, ajusta **al menos** `DATABASE_URL` y `JWT_ACCESS_SECRET`:

```dotenv
DATABASE_URL=postgresql://postgres:TU_CONTRASENA@127.0.0.1:5432/platanitos
JWT_ACCESS_SECRET=PEGA_AQUI_UN_SECRETO_ALEATORIO
```

Genera un secreto de forma local con:

```powershell
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
```

4. Prepara la base de datos e inicia la API (desde `backend/`):

```powershell
npm run db:setup
npm run start:dev
```

Comprueba el backend en [http://localhost:3000/health](http://localhost:3000/health).

### Ejecutar Flutter en modo remoto

Abre **una segunda terminal** en la raíz del repositorio:

```powershell
flutter run -d chrome --dart-define=APP_MODE=remote --dart-define=API_BASE_URL=http://localhost:3000
```

En un emulador Android, Flutter utiliza por defecto `http://10.0.2.2:3000` para acceder a la API del equipo anfitrión. Ejecuta la app con `--dart-define=APP_MODE=remote`.

**Acceso remoto:** no se publica una cuenta con contraseña de prueba. Registra un usuario desde la aplicación. Los roles internos `ADMINISTRATIVO` y `POSTULANTE` pertenecen a la API conservada y **no equivalen** a los seis accesos directos del modo demo.

---

## Información complementaria

### Estructura del proyecto

| Ruta | Contenido |
| --- | --- |
| `lib/` | Interfaz Flutter, navegación, funcionalidades y estado |
| `lib/core/` | Configuración, almacenamiento, red y utilidades |
| `lib/features/` | Módulos funcionales separados por responsabilidades |
| `android/` y `web/` | Configuración de plataformas |
| `backend/src/` | Módulos y controladores NestJS |
| `backend/prisma/` | Esquema, migraciones y datos iniciales |
| `backend/database/` | Archivos SQL y catálogo ampliado |
| `scripts/` | Automatización de instalación y arranque |
| `docs/` | Arquitectura, pruebas, base de datos y despliegue |

### Herramientas y ejecución avanzada

En Windows puedes utilizar los scripts incluidos para preparar un entorno de desarrollo aislado, si PostgreSQL ya está instalado:

```powershell
# Desde la raíz del proyecto
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1 -IsolatedDatabase -IncludeCatalog
```

Si `DATABASE_URL` ya apunta a otra base, el script conserva esa configuración. Para trabajar con PostgreSQL propio, configura `backend/.env` y ejecuta `setup.ps1` **sin** `-IsolatedDatabase`.

Para iniciar las partes en terminales separadas, están disponibles `scripts/start-backend.ps1` y `scripts/start-frontend.ps1`. También existen tareas de VS Code para el frontend y para frontend + backend.

Comandos adicionales:

```powershell
# Desde la raíz (Flutter)
flutter analyze
flutter test

# Desde backend/ (API y base de datos)
npm run build
npm run test:e2e -- --run
npm run db:catalog       # Carga el catálogo opcional ampliado
npx prisma studio        # Inspecciona la base de datos
npm.cmd run account:create # Crea una cuenta para el backend; solicita sus datos
```

### Problemas frecuentes

| Problema | Qué revisar |
| --- | --- |
| Flutter no detecta Chrome o Android | Ejecuta `flutter doctor` y `flutter devices` |
| El emulador figura `offline` | Reinícialo desde Android Studio → Device Manager; vuelve a ejecutar `flutter devices` |
| `DATABASE_URL` no está definida | Crea `backend/.env` a partir de `.env.example` |
| PostgreSQL rechaza la conexión | Comprueba que el servicio esté encendido, el puerto y las credenciales de `DATABASE_URL` |
| Falta `@prisma/client` | Dentro de `backend/`, ejecuta `npx prisma generate` |
| La API no inicia por `JWT_ACCESS_SECRET` | Genera y configura un secreto suficientemente largo |
| La API devuelve error o no conecta | Revisa [localhost:3000/health](http://localhost:3000/health) y asegúrate de usar `APP_MODE=remote` si quieres consumirla |
| Puerto `3000` ocupado | Detén el otro proceso o cambia `PORT` y `API_BASE_URL` |
| Android remoto no conecta a `localhost` | Desde un emulador usa `10.0.2.2`; en celular físico usa la IP local de la PC y configura `HOST=0.0.0.0` |

### Documentación y referencias

- [Arquitectura Flutter](docs/architecture/frontend.md)
- [Arquitectura backend](docs/architecture/backend.md)
- [Ejecución local](docs/setup/local.md)
- [Modelo de datos](docs/database/model.md)
- [Pruebas funcionales de la demo](docs/testing/demo_acceptance.md)
- [Compilación y despliegue](docs/deployment/README.md)
- [Documentación del backend](backend/README.md)

**Verificación documentada (13 de octubre de 2026):** frontend con 100 pruebas aprobadas, compilación web release y APK debug; backend con 2 pruebas unitarias y 8 de integración aprobadas. Estos resultados reflejan la verificación informada para esa fecha y no una ejecución de pruebas realizada al editar este README.

> **Seguridad:** nunca subas `backend/.env` al repositorio ni compartas contraseñas reales. Los datos de acceso públicos de esta guía son exclusivos de la demostración.
