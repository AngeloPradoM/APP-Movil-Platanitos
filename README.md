# Platanitos — Aplicación móvil de comercio electrónico

**Proyecto académico universitario · Desarrollo de aplicaciones con Flutter y Dart**

## 1. Presentación del proyecto

Platanitos es una aplicación de comercio electrónico desarrollada como prototipo académico para estudiar diseño de interfaces, navegación, gestión de estado y validación de flujos de compra. Reconstruye en Flutter las 18 pantallas del prototipo de referencia, preservando el proyecto existente y separando sus responsabilidades en módulos.

| Aspecto | Descripción |
| :--- | :--- |
| Categoría | Proyecto estudiantil universitario |
| Área de formación | Desarrollo de software y aplicaciones móviles |
| Nombre del paquete | `platanitos_app` |
| Versión de la aplicación | `1.0.0+1` — versión 1.0.0, compilación 1 |
| Tecnologías principales | Flutter y Dart |
| Plataforma de desarrollo documentada | Windows; ejecución web y preparación del entorno Android |
| Objetivo académico | Implementar una experiencia de compra con arquitectura mantenible, estado compartido y pruebas automatizadas |
| Modalidad | Prototipo funcional con datos y operaciones simulados |

La implementación utiliza Flutter y Dart. El código React del prototipo se empleó únicamente como referencia visual y funcional.

## 2. Índice

1. [Presentación del proyecto](#1-presentación-del-proyecto)
2. [Índice](#2-índice)
3. [Herramientas y versiones](#3-herramientas-y-versiones)
4. [Instalación y configuración en Windows](#4-instalación-y-configuración-en-windows)
5. [Ejecución del proyecto](#5-ejecución-del-proyecto)
6. [Guía de uso de la demostración](#6-guía-de-uso-de-la-demostración)
7. [Arquitectura y organización](#7-arquitectura-y-organización)
8. [Cobertura funcional](#8-cobertura-funcional)
9. [Alcance y limitaciones](#9-alcance-y-limitaciones)
10. [Validación y pruebas](#10-validación-y-pruebas)

## 3. Herramientas y versiones

**Fecha de verificación: 6 de octubre de 2026.** Las versiones corresponden al entorno local y a los archivos del proyecto; no representan una lista de versiones más recientes. Los paquetes resueltos se verificaron en `pubspec.lock`.

### 3.1. Entorno de desarrollo

| Categoría | Herramienta | Versión verificada | Uso en el proyecto | Fuente de verificación |
| :--- | :--- | :--- | :--- | :--- |
| Editor | Visual Studio Code | `1.140.0` | Edición, ejecución y depuración | Metadatos de `Code.exe` |
| Framework | Flutter SDK | `3.47.6`, canal `stable` | Interfaces y compilación multiplataforma | `flutter.version.json` del SDK local |
| Lenguaje | Dart SDK | `3.13.5` | Lógica, modelos y pruebas | SDK incluido con Flutter |
| Depuración | Dart DevTools | `2.60.0` | Inspección y diagnóstico | `flutter.version.json` |
| Control de versiones | Git para Windows | `2.54.0.windows.1` | Historial y trabajo por ramas | `git --version` |
| Extensión de VS Code | Flutter | `3.144.0` | Integración del editor con Flutter | Directorio local `dart-code.flutter-3.144.0` |
| Extensión de VS Code | Dart | `3.144.0` | Análisis y soporte del lenguaje | Directorio local `dart-code.dart-code-3.144.0` |
| Herramientas Android | Android Studio | Directorio de versión `2026.2.1`; build `262.9437.185.2621.16467767` | Administración del SDK y emuladores | `product-info.json` |
| Herramientas Android | Android SDK Build-Tools | `36.0.0` | Herramientas de construcción Android | `source.properties` |
| Herramientas Android | Android SDK Platform-Tools | `37.0.1` | Comunicación con dispositivos mediante ADB | `source.properties` |
| Herramientas Android | Android SDK Command-line Tools | `23.0`, carpeta `latest` | Gestión del SDK y sus licencias | `source.properties` |
| Plataforma Android instalada | Android SDK Platform | API `37.0`, revisión `2` | Plataforma presente en el entorno local | `platforms/android-37.0/source.properties` |

### 3.2. Configuración y dependencias del proyecto

| Categoría | Componente | Versión o configuración | Observación |
| :--- | :--- | :--- | :--- |
| Aplicación | Platanitos | `1.0.0+1` | Declarada en `pubspec.yaml` |
| Compatibilidad del lenguaje | Restricción de Dart | `^3.13.5` | Rango declarado; no es una segunda instalación de Dart |
| Interfaz | `cupertino_icons` | `1.0.9` | Versión resuelta; restricción declarada `^1.0.8` |
| Análisis estático | `flutter_lints` | `6.0.0` | Dependencia de desarrollo |
| Pruebas | `flutter_test` | Incluido en Flutter `3.47.6` | Paquete del SDK, sin versión independiente que instalar |
| Compilación Android | Android Gradle Plugin | `9.1.0` | Declarado en `android/settings.gradle.kts` |
| Compilación Android | Kotlin Gradle Plugin | `2.4.0` | Declarado en `android/settings.gradle.kts` |
| Compilación Android | Gradle Wrapper | `9.3.1` | Declarado en `gradle-wrapper.properties` |
| Compatibilidad Android | Java y Kotlin JVM | Nivel `17` | Objetivo de compilación; no identifica el JDK instalado |
| Plataforma de compilación | `compileSdk` / `targetSdk` | API `36` / API `36` | Valores heredados del SDK Flutter instalado |
| Compatibilidad de dispositivos | `minSdk` | API `24` | Valor heredado de Flutter |
| Herramientas nativas | NDK configurado | `28.2.13676358` | Valor heredado de Flutter; instalación no verificada |

**Preparación de Android:** la plataforma instalada verificada es API 37.0, mientras que el proyecto utiliza API 36 para compilar. Antes de una compilación Android, comprobar e instalar API 36 en **SDK Platforms**. Disponer de una API superior no sustituye automáticamente la plataforma solicitada por `compileSdk`.

Las versiones de compilación son las configuradas en el proyecto. La validación realizada hasta esta etapa corresponde a web y pruebas Flutter; no confirma una compilación Android completa.

## 4. Instalación y configuración en Windows

### 4.1. Herramientas necesarias

| Herramienta | Requisito para esta guía | Finalidad | Descarga o referencia oficial |
| :--- | :--- | :--- | :--- |
| Visual Studio Code | Obligatorio para seguir el flujo de esta guía | Editor de desarrollo | [Descargar VS Code](https://code.visualstudio.com/) |
| Flutter SDK | Obligatorio | Framework y herramientas de ejecución | [Instalación de Flutter con VS Code](https://docs.flutter.dev/install/quick) |
| Git | Obligatorio | Descargar Flutter y gestionar el proyecto | [Git para Windows](https://git-scm.com/downloads/win) |
| Extensiones Flutter y Dart | Obligatorias para la integración descrita con VS Code | Soporte del framework y del lenguaje | [Flutter](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter) · [Dart](https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code) |
| Android Studio | Requerido en esta guía para preparar Android | SDK Manager y Device Manager | [Descargar Android Studio](https://developer.android.com/studio?hl=es-419) |
| Android SDK | Obligatorio para ejecutar o compilar en Android | Plataformas y herramientas Android | Administrado desde Android Studio |
| Chrome | Necesario para `flutter run -d chrome` | Ejecución web de la demostración | Navegador instalado en el equipo |
| Visual Studio con C++ | Solo para una aplicación nativa de Windows | Compilación de escritorio Windows | Instalador de Visual Studio |

Android Studio y Android SDK son requisitos del flujo Android de esta guía. Para probar únicamente la versión web, basta con el entorno Flutter y un navegador compatible.

### 4.2. Instalar Flutter desde Visual Studio Code

1. Instalar Git y Visual Studio Code en Windows.
2. Abrir VS Code y acceder a **Extensiones** con `Ctrl + Shift + X`.
3. Buscar **Flutter**, publicado por **Dart Code**, e instalarlo. Esta extensión incorpora el soporte de Dart; comprobar que ambas extensiones estén habilitadas.
4. Crear la carpeta `C:\dev` desde el Explorador de archivos.
5. Abrir la paleta de comandos con `Ctrl + Shift + P` y seleccionar **Flutter: New Project**.
6. Si el SDK no está instalado, elegir **Download SDK** y seleccionar `C:\dev` como carpeta de destino. Al terminar la descarga, comprobar que la raíz efectiva del SDK sea `C:\dev\flutter`, sin carpetas `flutter` anidadas.
7. Pulsar **Clone Flutter** y esperar a que concluya la descarga.
8. Seleccionar **Add SDK to PATH** cuando VS Code muestre esa opción.
9. Reiniciar VS Code y abrir una terminal nueva.

El comando **Flutter: New Project** se utiliza aquí para acceder al instalador del SDK. Una vez instalado Flutter, cancelar la creación de una nueva aplicación y abrir la carpeta del proyecto existente `APP-Movil-Platanitos`.

Si Flutter ya está instalado en `C:\dev\flutter`, utilizar esa instalación y configurar **Flutter: Change SDK** cuando sea necesario. El proyecto ya define `dart.flutterSdkPath` en `.vscode/settings.json`.

### 4.3. Configurar la variable PATH

| Concepto | Ruta del entorno documentado |
| :--- | :--- |
| Raíz del SDK Flutter | `C:\dev\flutter` |
| Carpeta de ejecutables que se agrega a PATH | `C:\dev\flutter\bin` |
| Android SDK habitual en Windows | `%LOCALAPPDATA%\Android\Sdk` |

Para agregar Flutter al PATH del usuario:

1. Buscar **Ver la configuración avanzada del sistema** en el menú Inicio.
2. Abrir **Propiedades del sistema → Opciones avanzadas → Variables de entorno**.
3. En **Variables de usuario**, seleccionar **Path** y pulsar **Editar**.
4. Pulsar **Nuevo** e introducir `C:\dev\flutter\bin`.
5. Conservar las entradas existentes, evitar duplicados y confirmar los cambios con **Aceptar**.
6. Cerrar las terminales abiertas y reiniciar VS Code.

Comprobar la configuración en una terminal nueva:

```powershell
flutter --version
flutter doctor
```

Para consultar qué ejecutable se está utilizando:

```powershell
Get-Command flutter
```

La configuración del SDK apunta a la raíz `C:\dev\flutter`; el PATH apunta a su subcarpeta `bin`.

### 4.4. Instalar Android Studio y preparar el SDK

1. Descargar Android Studio desde su [página oficial](https://developer.android.com/studio?hl=es-419).
2. Completar el asistente con la instalación **Standard** y los componentes del SDK que indique.
3. En la pantalla de bienvenida, abrir **More Actions → SDK Manager**. Con un proyecto abierto, utilizar **Tools → SDK Manager**.
4. En **SDK Platforms**, instalar la plataforma **API 36** que utiliza la configuración actual del proyecto.
5. En **SDK Tools**, comprobar los componentes siguientes:

| Componente | Utilidad |
| :--- | :--- |
| Android SDK Command-line Tools | Administración del SDK y de las licencias |
| Android SDK Platform-Tools | Detección y comunicación con dispositivos |
| Android SDK Build-Tools | Construcción de la aplicación Android |
| Android Emulator | Ejecución en un dispositivo virtual, cuando se utilice emulador |
| NDK (Side by side) y CMake | Herramientas de compilación nativa cuando el proyecto las requiera |

Pulsar **Apply → OK** y esperar a que finalice la instalación. Para ejecutar en un dispositivo virtual, crear uno desde **Device Manager** e instalar su imagen de sistema. Como alternativa, conectar un teléfono con depuración USB habilitada.

Registrar la ruta del SDK y revisar el entorno desde PowerShell:

```powershell
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
flutter doctor
flutter devices
```

Si se utiliza **CMD**, la sintaxis equivalente para configurar la ruta es:

```cmd
flutter config --android-sdk "%LOCALAPPDATA%\Android\Sdk"
```

### 4.5. Resolver avisos de flutter doctor

Los avisos aportados como ejemplo describen una instalación que carecía de Command-line Tools y de licencias aceptadas. En la revisión local de este README, Command-line Tools ya está presente; usar la salida actual de `flutter doctor` para determinar qué tareas siguen pendientes.

| Aviso | Causa habitual | Acción | Plataforma afectada |
| :--- | :--- | :--- | :--- |
| `cmdline-tools component is missing` | Falta Android SDK Command-line Tools | Instalarlo desde SDK Manager → SDK Tools | Android |
| `Android license status unknown` | Licencias pendientes o herramientas incompletas | Instalar Command-line Tools y ejecutar el comando de licencias | Android |
| No se encuentra Android SDK | Ruta ausente o incorrecta | Configurar la ruta con `flutter config --android-sdk` | Android |
| Falta la plataforma de compilación | API requerida por `compileSdk` no instalada | Instalar API 36 desde SDK Platforms | Android |
| No aparece un dispositivo Android | Emulador apagado o teléfono sin depuración | Iniciar el emulador o habilitar depuración USB; ejecutar `flutter devices` | Android |
| Faltan componentes de Visual Studio | Herramientas de C++ incompletas | Instalar **Desktop development with C++**, MSVC, CMake y Windows SDK según el diagnóstico | Windows nativo |

Para revisar y aceptar las licencias de Android, ejecutar el siguiente comando y responder a las solicitudes después de leer sus términos:

```powershell
flutter doctor --android-licenses
```

Después, verificar nuevamente:

```powershell
flutter doctor -v
flutter devices
```

**Visual Studio Code y Visual Studio son herramientas diferentes.** El aviso de Visual Studio/C++ no impide desarrollar esta aplicación para Android o web; debe resolverse si se desea compilar una versión nativa de Windows.

La instalación guiada y los procedimientos de Android se basan en la [documentación de instalación de Flutter](https://docs.flutter.dev/install/quick) y la [configuración oficial para Android](https://docs.flutter.dev/platform-integration/android/setup).

## 5. Ejecución del proyecto

SDK: `C:\dev\flutter` (ejecutables en `C:\dev\flutter\bin`).

```powershell
flutter pub get
flutter run -d chrome
```

También puede ejecutarse en un dispositivo Android/iOS configurado. Android requiere Internet para descargar las imágenes HTTPS del catálogo.

## 6. Guía de uso de la demostración

- Inicia sesión con un correo válido y cualquier contraseña de al menos ocho caracteres, o con Google/Apple simulados.
- Busca productos por nombre, categoría o marca. Combina talla EUR, marca, color y precio; ordena por precio.
- Selecciona una talla EUR/US/CM y agrega productos a la bolsa. Las tallas equivalentes se agrupan por producto.
- Cambia cantidades, elimina productos y comprueba subtotal y envío S/ 6.90.
- Yape/Plin y agentes generan pedidos simulados. Tarjeta usa campos ficticios de solo lectura y simula un error para comprobar reintento y cambio de método.
- Los pedidos nuevos conservan productos, tallas, cantidades, precio, método y total aunque cambie la bolsa. Seguimiento permite simular estados y entrega; los entregados aparecen en Historial.
- Cuenta → Perfil permite editar nombre, correo y teléfono; los cambios permanecen al navegar. Cuenta → Configuración muestra el estado offline simulado.

## 7. Arquitectura y organización

- `lib/models`: entidades tipadas de producto, usuario, carrito y pedido.
- `lib/data/mock_data.dart`: catálogo, usuario y URLs de referencia.
- `lib/state/shop_state.dart`: única fuente del estado compartido mediante ChangeNotifier/InheritedNotifier, sin paquetes adicionales.
- `lib/core`: tema, validaciones y navegación al inicio.
- `lib/screens`: pantallas agrupadas por flujo.
- `lib/widgets`: imágenes con loading/fallback, tarjetas, grid, resumen, búsqueda y timeline.
- `assets/fonts`: Inter local y licencia SIL Open Font License.

Los mocks y operaciones de ShopState pueden sustituirse por un repositorio/servicio sin alterar los modelos usados por las pantallas. Los estados temporales de formularios y checkout permanecen locales.

## 8. Cobertura funcional

Implementadas: login, recovery, signup, home, catalog, detail, cart, favorites, checkout, success, orders, tracking, delivery, delivered, profile (Mi Cuenta), accountProfile (Perfil), support y offline.

Colores del CSS centralizados en AppColors. Se conserva Inter, tarjetas redondeadas, banner Cyber Days, etiquetas de oferta, galería, barra inferior y timeline. Los grids adaptan sus columnas al ancho y escala de texto; no se fuerza un ancho móvil de 430 px.

Se corrigieron inconsistencias del prototipo: precio único de S/ 89.90 para Zapatilla Plataforma, carrito por producto/talla, filtros sobre datos reales mock, identificador único por compra, resumen inmutable del pedido y perfil compartido. El botón de volver al inicio restablece la pestaña Inicio.

Monedero, Puntos, Membresía, Resikla, eGift Card, Ubícanos y Blog son opciones sin servicio en el prototipo; muestran un mensaje explicativo y no integran sistemas externos.

## 9. Alcance y limitaciones

Sesión, favoritos, bolsa, perfil y pedidos se guardan únicamente en memoria y se reinician al cerrar la app. Existe un pedido histórico de demostración. No hay backend, OAuth, cobros, geolocalización, notificaciones ni tracking real. QR decorativo, no válido para pagos. Las imágenes Unsplash necesitan red; los errores muestran un fallback. Las fechas nuevas se calculan desde la fecha del dispositivo.

## 10. Validación y pruebas

```powershell
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
```

Pruebas de estado: cantidades, tallas equivalentes, totales, snapshots de pedidos, estados, favoritos, filtros y validaciones. Pruebas de widgets: login, talla obligatoria, checkout, error de tarjeta, edición de perfil y búsqueda. Pruebas responsive: las 18 pantallas a 320, 430 y 900 px con texto ampliado al 140 %.

Comprobaciones realizadas: pub get correcto, analyze sin incidencias, 14 pruebas aprobadas, compilación web completada y arranque con flutter run -d web-server. Se revisaron capturas de login, Home, catálogo y detalle en Chrome; las imágenes de red se mostraron correctamente. No se ejecutó una compilación Android/iOS ni una comparación pixel a pixel contra un render React.
