# Platanitos — Aplicación móvil de comercio electrónico

**Proyecto académico universitario · Flutter + NestJS + PostgreSQL**

> ¿Quieres ejecutar el proyecto en tu computadora? Ve directamente a la
> [Guía de instalación paso a paso](#10-guía-de-instalación-paso-a-paso), al final de este documento.

## 1. Presentación del proyecto

Platanitos es un prototipo funcional de tienda de calzado desarrollado para estudiar diseño de interfaces, navegación, gestión de estado, consumo de APIs y persistencia en base de datos. La aplicación Flutter se conecta a una API REST propia (NestJS) que guarda usuarios, carritos, favoritos, direcciones y pedidos en PostgreSQL.

| Aspecto | Descripción |
| :--- | :--- |
| Categoría | Proyecto estudiantil universitario |
| Área de formación | Desarrollo de software, aplicaciones móviles e interacción hombre-máquina |
| Nombre del paquete | `platanitos_app` |
| Versión de la aplicación | `1.0.0+1` |
| Frontend | Flutter y Dart (web y Android) |
| Backend | NestJS 12 (Node.js) con Prisma 7 |
| Base de datos | PostgreSQL |
| Modalidad | Prototipo funcional: pagos, envíos y seguimiento son simulados |

## 2. Índice

**Descripción del proyecto**

1. [Presentación del proyecto](#1-presentación-del-proyecto)
2. [Índice](#2-índice)
3. [Componentes del sistema](#3-componentes-del-sistema)
4. [Herramientas y versiones verificadas](#4-herramientas-y-versiones-verificadas)
5. [Arquitectura y organización](#5-arquitectura-y-organización)
6. [API REST del backend](#6-api-rest-del-backend)
7. [Cobertura funcional](#7-cobertura-funcional)
8. [Guía de uso de la demostración](#8-guía-de-uso-de-la-demostración)
9. [Alcance y limitaciones](#9-alcance-y-limitaciones)

**Puesta en marcha**

10. [Guía de instalación paso a paso](#10-guía-de-instalación-paso-a-paso)
    - [Paso 1. Instalar las herramientas necesarias](#paso-1-instalar-las-herramientas-necesarias)
    - [Paso 2. Clonar el repositorio](#paso-2-clonar-el-repositorio)
    - [Paso 3. Instalar las dependencias](#paso-3-instalar-las-dependencias)
    - [Paso 4. Crear la base de datos con el script](#paso-4-crear-la-base-de-datos-con-el-script)
    - [Paso 5. Configurar `backend/.env`](#paso-5-configurar-backendenv)
    - [Paso 6. Preparar Prisma (cliente, migraciones y datos)](#paso-6-preparar-prisma-cliente-migraciones-y-datos)
    - [Paso 7. Levantar el backend](#paso-7-levantar-el-backend)
    - [Paso 8. Ejecutar la app Flutter (navegador y Android)](#paso-8-ejecutar-la-app-flutter-navegador-y-android)
    - [Paso 9. Verificar que todo funciona](#paso-9-verificar-que-todo-funciona)
    - [Paso 10. Solución de problemas](#paso-10-solución-de-problemas)

## 3. Componentes del sistema

```text
┌────────────────────┐   HTTP/JSON (JWT)   ┌────────────────────┐   Prisma   ┌──────────────┐
│  App Flutter       │ ──────────────────▶ │  API NestJS        │ ─────────▶ │  PostgreSQL  │
│  (Chrome/Android)  │ ◀────────────────── │  puerto 3000       │ ◀───────── │  "platanitos"│
└────────────────────┘                     └────────────────────┘            └──────────────┘
```

| Componente | Carpeta | Responsabilidad |
| :--- | :--- | :--- |
| App Flutter | raíz del repositorio (`lib/`, `test/`, `android/`, `web/`) | Interfaz, navegación, estado compartido y consumo de la API |
| API NestJS | `backend/src/` | Autenticación, catálogo, carrito, favoritos, direcciones, pedidos, puntos, eGift Cards y contenido |
| Esquema y migraciones | `backend/prisma/` | Modelo de datos (`schema.prisma`), migraciones versionadas y datos de demostración (`seed.ts`) |
| Script de base de datos | `backend/database/` | `platanitos.sql` crea toda la base con un solo archivo; `seed.sql` contiene los datos de demostración |

La app también funciona sin backend en **modo invitado**: el catálogo, las tiendas y el blog usan datos de respaldo locales. Crear cuenta, iniciar sesión y guardar datos en la nube requieren que la API esté levantada.

## 4. Herramientas y versiones verificadas

**Fecha de verificación: 8 de octubre de 2026.** Son las versiones del entorno donde se desarrolló y probó el proyecto. Versiones iguales o superiores dentro de la misma versión mayor deberían funcionar.

### 4.1. Entorno de desarrollo

| Categoría | Herramienta | Versión verificada | Uso en el proyecto |
| :--- | :--- | :--- | :--- |
| Editor | Visual Studio Code | `1.140.0` | Edición, ejecución y depuración |
| Framework móvil | Flutter SDK | `3.47.6`, canal `stable` | Interfaz y compilación web/Android |
| Lenguaje | Dart SDK | `3.13.5` | Incluido con Flutter |
| Entorno de ejecución | Node.js | `24.4.1` | Ejecuta la API (mínimo recomendado: 20 LTS) |
| Gestor de paquetes | npm | `11.4.2` | Dependencias del backend |
| Base de datos | PostgreSQL | 14 o superior | Requerido por `gen_random_uuid()` y Prisma 7 |
| Control de versiones | Git para Windows | `2.54.0.windows.1` | Clonar y gestionar el proyecto |
| Herramientas Android | Android Studio | `2026.2.1` | SDK Manager y emuladores |
| Herramientas Android | Android SDK Build-Tools / Platform-Tools | `36.0.0` / `37.0.1` | Compilación y comunicación ADB |

### 4.2. Dependencias principales del proyecto

| Parte | Paquete | Versión | Uso |
| :--- | :--- | :--- | :--- |
| Flutter | `http` | `1.6.0` | Llamadas a la API |
| Flutter | `flutter_secure_storage` | `11.2.0` | Guarda los tokens de sesión de forma segura |
| Flutter | `cupertino_icons` / `flutter_lints` | `1.0.9` / `6.0.0` | Íconos y análisis estático |
| Backend | `@nestjs/core` | `12.1.2` | Framework de la API |
| Backend | `prisma` / `@prisma/client` | `7.10.0` | Migraciones y acceso a datos |
| Backend | `pg` / `@prisma/adapter-pg` | `8.23.1` / `7.10.0` | Conexión con PostgreSQL |
| Backend | `argon2`, `@nestjs/jwt`, `passport-jwt` | `0.45.1`, `12.x`, `4.x` | Contraseñas cifradas y sesiones JWT |
| Backend | `helmet`, `@nestjs/throttler`, `class-validator` | `8.x`, `6.x`, `0.15.x` | Seguridad, límite de peticiones y validación |
| Backend (pruebas) | `vitest`, `supertest` | `4.x`, `7.x` | Pruebas unitarias y e2e |

### 4.3. Configuración Android del proyecto

| Componente | Valor | Observación |
| :--- | :--- | :--- |
| `compileSdk` / `targetSdk` | API `36` | Instalar **Android SDK Platform 36** en SDK Manager |
| `minSdk` | API `24` | Android 7.0 o superior |
| Android Gradle Plugin / Kotlin / Gradle | `9.1.0` / `2.4.0` / `9.3.1` | Declarados en `android/` |
| Java/Kotlin JVM | Nivel `17` | Lo provee Android Studio |

## 5. Arquitectura y organización

### 5.1. App Flutter (`lib/`)

| Carpeta | Contenido |
| :--- | :--- |
| `lib/app` | Contenedor principal con la barra de navegación inferior |
| `lib/core` | Tema y colores (`AppColors`), validaciones, navegación, cliente HTTP y `ApiConfig` (URL de la API) |
| `lib/features/<módulo>` | Un módulo por flujo: `auth`, `catalog`, `cart`, `checkout`, `orders`, `account`, `support`. Cada uno separa `data/` (repositorios que llaman a la API) y `presentation/` (pantallas) |
| `lib/models` y `lib/shared` | Modelos tipados (producto, carrito, pedido, dirección, usuario) |
| `lib/state` | `ShopState`: estado compartido con `ChangeNotifier`; trabaja en local y sincroniza con la API cuando hay sesión |
| `lib/data/mock_data.dart` | Datos de respaldo cuando el backend no responde |
| `lib/widgets` | Componentes reutilizables (tarjetas, botones, íconos de línea, línea de tiempo del pedido) |

Más detalle en [`docs/FRONTEND_ARCHITECTURE.md`](docs/FRONTEND_ARCHITECTURE.md).

### 5.2. Backend (`backend/`)

| Carpeta o archivo | Contenido |
| :--- | :--- |
| `src/auth` | Registro, login, refresh y logout con JWT; perfil en `/me` |
| `src/catalog`, `src/cart`, `src/favorites`, `src/addresses`, `src/orders` | Módulos de negocio (controlador + servicio + DTOs validados) |
| `src/loyalty`, `src/gift-cards`, `src/content` | Puntos, eGift Cards, tiendas y blog |
| `src/database` | `PrismaService` (conexión a PostgreSQL) |
| `prisma/schema.prisma` | Modelo de datos (23 tablas) |
| `prisma/migrations/` | Migraciones versionadas aplicadas con `prisma migrate deploy` |
| `prisma/seed.ts` | Datos de demostración (productos, tiendas y blog) |
| `database/platanitos.sql` | **Script completo** de la base (tablas + registro de migraciones + datos) |
| `scripts/setup-database.mjs` | Comando `npm run db:setup`: crea la base y la deja lista automáticamente |
| `.env.example` | Plantilla de configuración; se copia como `.env` |

Más detalle en [`backend/ARCHITECTURE.md`](backend/ARCHITECTURE.md) y [`backend/README.md`](backend/README.md).

### 5.3. Mantener el script de base de datos

`backend/database/platanitos.sql` se genera a partir de las migraciones y de `backend/database/seed.sql`. Cuando el equipo cambie el modelo de datos:

```powershell
cd backend
npx prisma migrate dev --name descripcion_del_cambio   # crea la nueva migración
npm run db:sql                                         # regenera database/platanitos.sql
```

Si se agregan datos de demostración, actualizar tanto `prisma/seed.ts` como `database/seed.sql`, y volver a ejecutar `npm run db:sql`.

## 6. API REST del backend

Base local: `http://localhost:3000`. Las rutas marcadas con 🔒 requieren el encabezado `Authorization: Bearer <token>` que la app obtiene al iniciar sesión.

| Módulo | Método y ruta | Descripción |
| :--- | :--- | :--- |
| Salud | `GET /health` | Comprueba que la API está activa |
| Autenticación | `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout` | Crear cuenta, iniciar sesión, renovar y cerrar sesión |
| Perfil 🔒 | `GET /me`, `PATCH /me` | Ver y editar nombre, correo y teléfono |
| Catálogo | `GET /catalog/categories`, `GET /catalog/brands`, `GET /catalog/products`, `GET /catalog/products/:slug` | Productos, filtros y detalle |
| Carrito 🔒 | `GET /cart`, `POST /cart/items`, `POST /cart/sync`, `PATCH /cart/items/:itemId`, `DELETE /cart/items/:itemId` | Bolsa persistente |
| Favoritos 🔒 | `GET /favorites`, `PUT /favorites/:productId`, `DELETE /favorites/:productId` | Lista de favoritos |
| Direcciones 🔒 | `GET /addresses`, `POST /addresses`, `PUT /addresses/:id`, `DELETE /addresses/:id` | Hasta 10 direcciones escritas por usuario, una principal |
| Pedidos 🔒 | `POST /orders`, `GET /orders`, `GET /orders/:publicNumber`, `PATCH /orders/:publicNumber/status` | Crear pedido (con `addressId` opcional), historial y estado simulado |
| Puntos 🔒 | `GET /loyalty`, `POST /loyalty/redeem`, `POST /loyalty/recycling` | Puntos, canje por saldo y bono Resikla |
| eGift Cards 🔒 | `GET /gift-cards`, `POST /gift-cards` | Emisión simulada |
| Contenido | `GET /content/stores`, `GET /content/blog`, `GET /content/blog/:slug` | Tiendas y artículos |

Los errores internos nunca se muestran al usuario: la app muestra "El sistema está fallando en este momento. Intenta más tarde."

## 7. Cobertura funcional

- **Cuenta:** crear cuenta, iniciar sesión, recuperar contraseña (simulado), modo invitado y cierre de sesión. La sesión se renueva sola con el *refresh token*.
- **Catálogo:** inicio con banners y categorías, búsqueda, filtros por talla, marca, color y precio, ordenamiento y detalle con tallas EUR/US/CM.
- **Bolsa y favoritos:** sincronizados con el backend cuando hay sesión; locales en modo invitado.
- **Direcciones:** formulario para **escribir** la dirección (tipo, quién recibe, teléfono, dirección, departamento, provincia, distrito y referencia), lista "Mis direcciones" y dirección principal.
- **Checkout en 3 pasos:** Envío (elegir o agregar dirección) → Entrega (fecha estimada y resumen) → Pago (Yape/Plin con QR decorativo, tarjeta con error simulado o efectivo en agentes).
- **Pedidos:** compra finalizada, seguimiento con línea de tiempo, detalle de entrega con la dirección real y pedido entregado; historial "En curso / Historial".
- **Mi Cuenta:** perfil editable, direcciones, monedero, puntos, membresía, Resikla, eGift Card, tiendas (Ubícanos), blog y centro de ayuda.
- **Accesibilidad y diseño:** fuente Inter, colores centralizados en `AppColors`, estados *hover/pressed*, pantallas adaptables de 320 a 900 px y texto ampliado al 140 %.

## 8. Guía de uso de la demostración

1. Abre la app y elige **Crear cuenta** (nombre, correo y contraseña de al menos 8 caracteres) o **Continuar como invitada/o**.
2. Busca productos desde el inicio o Categorías; filtra por talla, marca, color y precio.
3. En el detalle elige una talla y agrégala a la bolsa. En la bolsa cambia cantidades; el envío cuesta S/ 6.90.
4. Pulsa **Ir a Pagar** (como invitado se pedirá iniciar sesión). Escribe una dirección de envío, revisa la entrega y elige el método de pago.
5. La tarjeta usa datos ficticios y simula un error para probar el cambio de método; Yape/Plin y efectivo completan la compra.
6. Desde **Seguir mi pedido** puedes simular el siguiente estado y la entrega. Los pedidos entregados pasan a **Historial**.
7. En **Mi Cuenta → Perfil** edita tus datos; en **Mi Cuenta → Direcciones** administra tus direcciones.

## 9. Alcance y limitaciones

- Los pagos son **simulados**: no hay pasarela real y el QR de Yape/Plin es decorativo.
- Envíos, transportista y seguimiento son ilustrativos; el estado del pedido se avanza manualmente.
- La ubicación se **escribe** a mano; no se usa Google Maps ni geolocalización.
- Inicio de sesión con Google/Apple es simulado; no hay OAuth real.
- El modo invitado guarda bolsa y favoritos solo en memoria.
- Las imágenes del catálogo se cargan desde Unsplash y requieren Internet; si fallan se muestra un reemplazo.
- La app se validó en navegador (Chrome) y Android. iOS, macOS, Windows y Linux no se probaron.
- Las fechas estimadas se calculan desde la fecha del dispositivo.

---

## 10. Guía de instalación paso a paso

Sigue los pasos **en orden**. Los comandos son para **PowerShell en Windows**; cuando cambian en macOS/Linux se indica.

| Paso | Qué harás | Tiempo aproximado |
| :--- | :--- | :--- |
| 1 | Instalar Git, Node.js, PostgreSQL, Flutter y Android Studio | 30–60 min (solo la primera vez) |
| 2 | Clonar el repositorio | 1 min |
| 3 | Instalar dependencias (npm y Flutter) | 3–5 min |
| 4 | Crear la base de datos con el script | 2 min |
| 5 | Configurar `backend/.env` | 5 min |
| 6 | Preparar Prisma | 1 min |
| 7 | Levantar el backend | 1 min |
| 8 | Ejecutar la app en Chrome o Android | 2–5 min |
| 9 | Verificar que todo funciona | 5 min |
| 10 | Solución de problemas (si algo falla) | — |

### Paso 1. Instalar las herramientas necesarias

#### 1.1. Lista de herramientas

| Herramienta | ¿Obligatoria? | Para qué | Descarga |
| :--- | :--- | :--- | :--- |
| Git | Sí | Clonar el repositorio | [git-scm.com](https://git-scm.com/downloads/win) |
| Node.js 20 LTS o superior (incluye npm) | Sí | Ejecutar el backend | [nodejs.org](https://nodejs.org/) |
| PostgreSQL 14 o superior (incluye pgAdmin 4) | Sí | Base de datos | [postgresql.org/download](https://www.postgresql.org/download/windows/) |
| Flutter SDK 3.47 (canal stable) | Sí | Ejecutar la app | [docs.flutter.dev](https://docs.flutter.dev/install/quick) |
| Google Chrome | Para la versión web | Ejecutar la app en el navegador | [google.com/chrome](https://www.google.com/chrome/) |
| Android Studio + Android SDK API 36 | Para Android | Emulador y compilación Android | [developer.android.com/studio](https://developer.android.com/studio?hl=es-419) |
| Visual Studio Code + extensiones Flutter y Dart | Recomendado | Editor | [code.visualstudio.com](https://code.visualstudio.com/) |

#### 1.2. Instalar Node.js

1. Descarga el instalador **LTS** desde [nodejs.org](https://nodejs.org/) y ejecútalo con las opciones por defecto.
2. Abre una terminal **nueva** y comprueba:

```powershell
node --version   # v20 o superior
npm --version
```

#### 1.3. Instalar PostgreSQL

1. Descarga el instalador de [postgresql.org](https://www.postgresql.org/download/windows/) (versión 14 o superior).
2. En el asistente deja marcados **PostgreSQL Server**, **pgAdmin 4** y **Command Line Tools**.
3. Cuando pida la contraseña del superusuario `postgres`, escribe una y **anótala**: la usarás en el paso 5.
4. Deja el puerto en **5432** y termina la instalación.
5. (Opcional) Para usar `psql` desde la terminal, agrega `C:\Program Files\PostgreSQL\<versión>\bin` a la variable PATH.

#### 1.4. Instalar Flutter (desde VS Code)

1. Instala Git y VS Code. En VS Code abre **Extensiones** (`Ctrl + Shift + X`) e instala **Flutter** (de Dart Code); se instala también **Dart**.
2. Crea la carpeta `C:\dev`.
3. Abre la paleta (`Ctrl + Shift + P`) → **Flutter: New Project** → **Download SDK** → elige `C:\dev`. La raíz del SDK debe quedar en `C:\dev\flutter`.
4. Acepta **Add SDK to PATH**. Si no aparece, agrega manualmente `C:\dev\flutter\bin` en **Variables de entorno → Variables de usuario → Path**.
5. Cancela la creación del proyecto nuevo, cierra VS Code y abre una terminal nueva:

```powershell
flutter --version
flutter doctor
```

#### 1.5. Preparar Android (solo si usarás Android)

1. Instala [Android Studio](https://developer.android.com/studio?hl=es-419) con la instalación **Standard**.
2. Abre **More Actions → SDK Manager**:
   - En **SDK Platforms** marca **Android API 36**.
   - En **SDK Tools** marca **Android SDK Command-line Tools**, **Platform-Tools**, **Build-Tools** y **Android Emulator**.
3. Pulsa **Apply** y espera la descarga.
4. Crea un emulador en **More Actions → Virtual Device Manager** (por ejemplo, Pixel con API 36).
5. Registra el SDK y acepta las licencias:

```powershell
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
flutter doctor --android-licenses
flutter doctor
```

`flutter doctor` debe mostrar ✓ en **Flutter**, **Android toolchain** y **Chrome**. El aviso de **Visual Studio (C++)** solo importa para compilar una app de escritorio Windows y puede ignorarse.

### Paso 2. Clonar el repositorio

```powershell
cd $HOME\Desktop
git clone https://github.com/AngeloPradoM/APP-Movil-Platanitos.git
cd APP-Movil-Platanitos
```

Estructura que debes ver:

```text
APP-Movil-Platanitos/
├── backend/          ← API NestJS, Prisma y script de base de datos
│   ├── database/     ← platanitos.sql y seed.sql
│   ├── prisma/       ← schema.prisma, migraciones y seed.ts
│   └── .env.example  ← plantilla de configuración
├── lib/              ← código de la app Flutter
├── android/, web/    ← plataformas
└── README.md
```

### Paso 3. Instalar las dependencias

#### 3.1. Backend (Node.js)

```powershell
cd backend
npm install
cd ..
```

`npm install` respeta las versiones de `package-lock.json`. No uses `npm update` ni `npm audit fix --force`: cambiarían versiones probadas.

#### 3.2. App Flutter

Desde la raíz del repositorio:

```powershell
flutter pub get
```

### Paso 4. Crear la base de datos con el script

El archivo [`backend/database/platanitos.sql`](backend/database/platanitos.sql) crea **todo** en un solo paso:

- los tipos y las 23 tablas del sistema con sus índices y relaciones;
- la tabla `_prisma_migrations`, para que Prisma sepa que las migraciones ya están aplicadas;
- los datos de demostración: 2 productos con 4 variantes, 4 tiendas y 3 artículos del blog.

Debe ejecutarse sobre una base de datos **vacía** llamada `platanitos`. Si las tablas ya existen, el script se detiene sin modificar nada. Elige **una** de las tres opciones.

#### Opción A — pgAdmin (recomendada si no usas la terminal)

1. Abre **pgAdmin 4** y conéctate al servidor con la contraseña de `postgres`.
2. Clic derecho en **Databases → Create → Database…**
3. En **Database** escribe `platanitos` y pulsa **Save**.
4. Clic derecho sobre la base `platanitos` → **Query Tool**.
5. Pulsa el ícono **Open File** y elige `backend/database/platanitos.sql`.
6. Pulsa **Execute** (o `F5`). Debe terminar con el mensaje `COMMIT` / "Query returned successfully".
7. Comprueba en **platanitos → Schemas → public → Tables** que aparecen 24 tablas (23 del sistema + `_prisma_migrations`). Si no las ves, clic derecho → **Refresh**.

#### Opción B — Terminal con `psql`

```powershell
psql -U postgres -c "CREATE DATABASE platanitos;"
psql -U postgres -d platanitos -v ON_ERROR_STOP=1 -f backend/database/platanitos.sql
```

`psql` pedirá la contraseña de `postgres`. La última línea debe ser `COMMIT`.

#### Opción C — Automática con Node.js

Si prefieres no usar pgAdmin ni `psql`, salta este paso: en el paso 6 el comando `npm run db:setup` crea la base, las tablas y los datos por ti.

### Paso 5. Configurar `backend/.env`

El backend lee su configuración del archivo `backend/.env`. Ese archivo contiene contraseñas, **no se sube a GitHub** (está en `.gitignore`) y cada integrante crea el suyo.

#### 5.1. Crear el archivo

```powershell
cd backend
Copy-Item .env.example .env
```

En macOS/Linux: `cp .env.example .env`. Luego abre `backend/.env` con VS Code o el Bloc de notas.

#### 5.2. Qué significa cada variable

| Variable | ¿Cambiarla? | Valor por defecto | Explicación |
| :--- | :--- | :--- | :--- |
| `PORT` | No | `3000` | Puerto de la API. La app Flutter usa 3000 por defecto; si lo cambias, también debes pasar `API_BASE_URL` (paso 8). |
| `HOST` | Solo para celular físico | `127.0.0.1` | Interfaz de red donde escucha la API. `127.0.0.1` = solo tu PC (sirve para Chrome y el emulador). `0.0.0.0` = también otros dispositivos de tu Wi-Fi (necesario para un celular real). |
| `NODE_ENV` | No | `development` | `development` en tu PC. `production` solo al desplegar en un servidor (desactiva el CORS automático de localhost). |
| `CORS_ORIGINS` | No (en local) | `http://localhost:8080,http://127.0.0.1:8080` | Lista, separada por comas y sin espacios, de las páginas web que pueden llamar a la API. En un servidor real se pone el dominio de la app web. |
| `CORS_ALLOW_LOCALHOST` | No | `true` | `true` acepta cualquier puerto de `localhost`. Es necesario porque `flutter run -d chrome` usa un puerto distinto en cada ejecución. Usa `false` en producción. |
| `DATABASE_URL` | **Sí** | `postgresql://USUARIO:CONTRASENA@127.0.0.1:5432/platanitos` | Dirección de conexión a PostgreSQL (ver 5.3). |
| `JWT_ACCESS_SECRET` | **Sí** | `CAMBIAR_POR_…` | Clave secreta con la que se firman las sesiones (ver 5.4). Mínimo 32 caracteres aleatorios. |
| `JWT_ACCESS_TTL` | No | `15m` | Duración del token de acceso (`15m` = 15 minutos, `1h` = 1 hora). La app lo renueva sola. |
| `JWT_REFRESH_TTL_DAYS` | No | `30` | Días que dura la sesión antes de pedir iniciar sesión otra vez. |

Solo **dos variables son obligatorias de cambiar**: `DATABASE_URL` y `JWT_ACCESS_SECRET`.

#### 5.3. Cómo armar `DATABASE_URL`

```text
postgresql://USUARIO:CONTRASENA@HOST:PUERTO/NOMBRE_BASE
```

| Parte | Qué poner | Valor habitual |
| :--- | :--- | :--- |
| `USUARIO` | Usuario de PostgreSQL | `postgres` |
| `CONTRASENA` | La contraseña que elegiste al instalar PostgreSQL (paso 1.3) | — |
| `HOST` | Dónde corre PostgreSQL | `127.0.0.1` (tu misma PC) |
| `PUERTO` | Puerto de PostgreSQL | `5432` |
| `NOMBRE_BASE` | Base creada en el paso 4 | `platanitos` |

Ejemplo: si tu contraseña es `MiClave2026`, la línea queda:

```env
DATABASE_URL=postgresql://postgres:MiClave2026@127.0.0.1:5432/platanitos
```

**Si la contraseña tiene caracteres especiales**, hay que codificarlos o la conexión fallará:

| Carácter | Se escribe | Carácter | Se escribe |
| :---: | :---: | :---: | :---: |
| `@` | `%40` | `?` | `%3F` |
| `:` | `%3A` | `%` | `%25` |
| `/` | `%2F` | espacio | `%20` |
| `#` | `%23` | `&` | `%26` |

Por ejemplo, `Mi@Clave#1` se escribe `Mi%40Clave%231`. Para obtenerlo automáticamente:

```powershell
node -e "console.log(encodeURIComponent('Mi@Clave#1'))"
```

#### 5.4. Cómo generar `JWT_ACCESS_SECRET`

Ejecuta este comando y copia el resultado:

```powershell
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
```

Pégalo en el `.env`:

```env
JWT_ACCESS_SECRET=pega_aqui_el_texto_generado
```

No lo compartas. Si lo cambias, todas las sesiones abiertas se invalidan y hay que volver a iniciar sesión.

#### 5.5. `HOST` y CORS según dónde ejecutes la app

| Dónde corre la app | `HOST` | `CORS_ALLOW_LOCALHOST` | URL que usa la app |
| :--- | :--- | :--- | :--- |
| Chrome (web) en tu PC | `127.0.0.1` | `true` | `http://localhost:3000` (automático) |
| Emulador Android | `127.0.0.1` | no aplica | `http://10.0.2.2:3000` (automático; `10.0.2.2` es tu PC vista desde el emulador) |
| Celular Android físico por Wi-Fi | `0.0.0.0` | no aplica | `http://<IP-de-tu-PC>:3000` (se indica con `API_BASE_URL`, paso 8.3) |

CORS solo afecta al navegador; las apps Android no lo usan.

#### 5.6. Ejemplo completo

```env
PORT=3000
HOST=127.0.0.1
NODE_ENV=development
CORS_ORIGINS=http://localhost:8080,http://127.0.0.1:8080
CORS_ALLOW_LOCALHOST=true
DATABASE_URL=postgresql://postgres:MiClave2026@127.0.0.1:5432/platanitos
JWT_ACCESS_SECRET=q3Vb7m1x...texto_generado_en_el_paso_5.4...Zp9
JWT_ACCESS_TTL=15m
JWT_REFRESH_TTL_DAYS=30
```

#### 5.7. Comprobar que `.env` no se subirá

```powershell
git check-ignore -v backend/.env
```

Debe responder `backend/.gitignore:4:.env  backend/.env`. Nunca pongas contraseñas reales en `.env.example`.

### Paso 6. Preparar Prisma (cliente, migraciones y datos)

Todos los comandos se ejecutan dentro de `backend/`.

**Si creaste la base con el script (opción A o B del paso 4):**

```powershell
npx prisma generate
npx prisma migrate status
```

- `prisma generate` crea el cliente de Prisma que usa el backend (es obligatorio, aunque la base ya exista).
- `migrate status` debe terminar con **"Database schema is up to date!"**.

**Si elegiste la opción C (automática):**

```powershell
npm run db:setup
```

Este comando hace 4 cosas y muestra el avance:

1. Crea la base indicada en `DATABASE_URL` si no existe.
2. Aplica las migraciones (`prisma migrate deploy`).
3. Genera el cliente de Prisma (`prisma generate`).
4. Carga los datos de demostración (`npm run db:seed`).

Puede ejecutarse varias veces sin duplicar datos. Si el usuario de PostgreSQL no tiene permiso para crear bases, crea `platanitos` en pgAdmin y vuelve a ejecutarlo.

### Paso 7. Levantar el backend

```powershell
cd backend
npm run start:dev
```

Espera el mensaje **"Nest application successfully started"** y deja esa terminal abierta. Comprueba en el navegador:

- [http://localhost:3000/health](http://localhost:3000/health) → `{"status":"ok","service":"platanitos-backend",...}`
- [http://localhost:3000/catalog/products](http://localhost:3000/catalog/products) → lista de productos de demostración.

Para una ejecución sin recarga automática: `npm run build` y luego `npm run start:prod`.

### Paso 8. Ejecutar la app Flutter (navegador y Android)

Abre **otra terminal** en la raíz del repositorio (el backend sigue corriendo en la primera).

La app decide a qué URL llamar así:

| Plataforma | URL por defecto | Cómo cambiarla |
| :--- | :--- | :--- |
| Web (Chrome) | `http://localhost:3000` | `--dart-define=API_BASE_URL=...` |
| Android | `http://10.0.2.2:3000` | `--dart-define=API_BASE_URL=...` |

`API_BASE_URL` va sin `/` al final. Está definida en `lib/core/api_config.dart`.

#### 8.1. Navegador (Chrome)

```powershell
flutter run -d chrome
```

#### 8.2. Emulador Android

1. Inicia el emulador desde **Android Studio → Virtual Device Manager → ▶**.
2. Verifica que aparezca y ejecuta la app:

```powershell
flutter devices
flutter run -d emulator-5554
```

(usa el identificador que muestre `flutter devices`). No hace falta `API_BASE_URL`: el emulador llega a tu PC con `10.0.2.2`.

#### 8.3. Celular Android físico

1. En el celular activa **Opciones de desarrollador** (toca 7 veces **Número de compilación**) y luego **Depuración USB**. Conéctalo por USB y acepta el permiso.
2. PC y celular deben estar en la **misma red Wi-Fi**.
3. En `backend/.env` cambia `HOST=0.0.0.0` y reinicia el backend (`Ctrl + C` y `npm run start:dev`).
4. Averigua la IP de tu PC con `ipconfig` (línea **Dirección IPv4**, por ejemplo `192.168.1.50`).
5. Permite el puerto 3000 en el Firewall de Windows (PowerShell **como administrador**, una sola vez):

```powershell
New-NetFirewallRule -DisplayName "Platanitos API 3000" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

6. Prueba desde el navegador del celular `http://192.168.1.50:3000/health`. Si responde, ejecuta:

```powershell
flutter devices
flutter run -d <id-del-celular> --dart-define=API_BASE_URL=http://192.168.1.50:3000
```

Las compilaciones **debug** permiten HTTP hacia tu PC (`android/app/src/debug/AndroidManifest.xml`). Una versión **release** necesitará la API publicada con HTTPS.

### Paso 9. Verificar que todo funciona

#### 9.1. Prueba manual

1. `http://localhost:3000/health` responde `"status":"ok"`.
2. En la app, pulsa **Crear cuenta** (contraseña de al menos 8 caracteres). Debes entrar al inicio con tu nombre.
3. Agrega un producto a la bolsa, ve a **Ir a Pagar**, escribe una dirección y paga con Yape/Plin.
4. En pgAdmin, la tabla `Order` de la base `platanitos` debe tener tu pedido y `Address` tu dirección.
5. Cierra sesión y vuelve a entrar: pedidos, favoritos y direcciones siguen ahí.

#### 9.2. Pruebas automáticas

App Flutter (desde la raíz):

```powershell
flutter analyze
flutter test
```

Backend (desde `backend/`, con PostgreSQL encendido):

```powershell
npm run build
npm run test:e2e -- --run
```

Las pruebas e2e usan la base configurada en `.env`: crean usuarios temporales `e2e-…@example.com` y los eliminan al terminar.

#### 9.3. Comandos útiles del backend

| Comando | Para qué |
| :--- | :--- |
| `npm run start:dev` | Levantar la API con recarga automática |
| `npm run build` / `npm run start:prod` | Compilar y ejecutar la versión compilada |
| `npm run db:setup` | Crear la base, aplicar migraciones, generar el cliente y cargar datos |
| `npm run db:seed` | Volver a cargar solo los datos de demostración |
| `npm run db:sql` | Regenerar `database/platanitos.sql` tras una nueva migración |
| `npx prisma migrate status` | Ver si la base está al día |
| `npx prisma studio` | Explorar la base desde el navegador |
| `npm run test:e2e -- --run` | Pruebas de extremo a extremo |

### Paso 10. Solución de problemas

| Síntoma | Causa probable | Solución |
| :--- | :--- | :--- |
| La app dice "El sistema está fallando en este momento" al iniciar sesión o crear cuenta | El backend no está corriendo o la app apunta a otra URL | Repite el paso 7 y abre `/health`. En celular físico revisa `API_BASE_URL` (paso 8.3). |
| `db:setup` muestra "Usuario o contraseña de PostgreSQL incorrectos" | `DATABASE_URL` mal escrita | Revisa usuario y contraseña (paso 5.3); codifica los caracteres especiales. |
| "No se pudo conectar a PostgreSQL" o `ECONNREFUSED` | El servicio de PostgreSQL está detenido o el puerto no es 5432 | Abre `services.msc`, inicia **postgresql-x64-NN** y verifica el puerto en `DATABASE_URL`. |
| `Environment variable not found: DATABASE_URL` o "Falta DATABASE_URL" | No existe `backend/.env` o se ejecutó el comando fuera de `backend/` | Crea el archivo (paso 5.1) y ejecuta los comandos dentro de `backend/`. |
| El backend no arranca y menciona `JWT_ACCESS_SECRET` | Variable vacía o comentada | Genérala con el comando del paso 5.4. |
| El script SQL dice "La base de datos ya tiene las tablas de Platanitos" | Ya se ejecutó antes | No hace falta repetirlo. Para empezar de cero, borra la base `platanitos`, créala vacía y ejecuta el script otra vez. |
| `prisma migrate deploy` devuelve `P3005` (schema is not empty) | Las tablas se crearon sin registrar las migraciones | Borra y recrea la base con `platanitos.sql` o con `npm run db:setup`. |
| `@prisma/client did not initialize yet` o falta `.prisma/client` | No se generó el cliente | `npx prisma generate` dentro de `backend/`. |
| `EADDRINUSE: address already in use :::3000` | Otro programa usa el puerto 3000 | Cierra la otra terminal del backend o cambia `PORT` y pasa `API_BASE_URL` con el nuevo puerto. |
| En Chrome, la consola muestra un error de CORS | `CORS_ALLOW_LOCALHOST=false` o el origen no está permitido | Usa `CORS_ALLOW_LOCALHOST=true` en desarrollo o agrega el origen a `CORS_ORIGINS`. |
| El emulador Android no se conecta | Backend apagado o se usó `localhost` | El emulador usa `10.0.2.2` automáticamente; no pases `API_BASE_URL=http://localhost:3000`. |
| El celular físico no se conecta | `HOST` sigue en `127.0.0.1`, otra red Wi-Fi o firewall | `HOST=0.0.0.0`, misma Wi-Fi, regla de firewall y prueba `/health` desde el celular (paso 8.3). |
| `psql` no se reconoce como comando | La carpeta `bin` de PostgreSQL no está en PATH | Usa pgAdmin (opción A) o agrega `C:\Program Files\PostgreSQL\<versión>\bin` al PATH. |
| `flutter doctor` muestra "Android license status unknown" | Licencias sin aceptar | `flutter doctor --android-licenses`. |
| No aparecen imágenes de productos | Sin conexión a Internet | Las imágenes vienen de Unsplash; conéctate a Internet. |
