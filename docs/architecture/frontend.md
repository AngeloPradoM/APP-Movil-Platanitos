# Arquitectura del frontend

Flutter permanece en la raíz para abrir el proyecto directamente en VS Code y Android Studio. La ejecución predeterminada es una demo local; el backend conservado es una integración opcional.

## Modos de ejecución

| Modo | Activación | Persistencia |
| --- | --- | --- |
| `demo` | Valor predeterminado o `--dart-define=APP_MODE=demo` | SQLite en Android; repositorios en memoria para web y pruebas de interfaz |
| `remote` | `--dart-define=APP_MODE=remote` | Repositorios HTTP hacia NestJS |

`lib/app/dependencies.dart` es la única composición de dependencias. Las pantallas no eligen entre SQLite y HTTP.

## Flujo de dependencias

```text
Pantalla -> controlador -> contrato de repositorio -> SQLite / memoria / HTTP
```

Los contratos activos están definidos para autenticación, catálogo, inventario y operaciones. `DemoOperationsRepository` concentra carrito, pedidos, preparación, reparto, posventa, reportes y reservas de tienda. Una futura implementación HTTP puede reemplazar SQLite sin modificar las pantallas.

## Organización

| Carpeta | Responsabilidad |
| --- | --- |
| `lib/main.dart` | Punto de entrada |
| `lib/app/app.dart` | Inicialización asíncrona, restauración de sesión y `MaterialApp` |
| `lib/app/dependencies.dart` | Selección de modo y construcción de repositorios |
| `lib/app/navigation` | Navegación compartida |
| `lib/app/state` | Estado comercial existente y ciclo de vida |
| `lib/app/data` | Datos demostrativos y adaptadores temporales para web |
| `lib/core/config` | `APP_MODE`, URL remota y configuración transversal |
| `lib/core/database` | Apertura, versión y migraciones de SQLite |
| `lib/features/<modulo>/domain` | Entidades, reglas y contratos del módulo |
| `lib/features/<modulo>/data` | Implementaciones SQLite o HTTP |
| `lib/features/<modulo>/presentation/controllers` | Estado de presentación del módulo |
| `lib/features/<modulo>/presentation/screens` | Pantallas |
| `lib/shared/widgets` | Componentes reutilizables |

## Persistencia local

La base `platanitos_demo.db` utiliza migraciones incrementales. Su esquema contiene perfiles y sesión de demostración, productos, variantes, movimientos de stock, carrito, pedidos, pagos simulados, preparación, reparto, evidencia de entrega, incidencias, posventa y reservas de tienda. La evidencia guarda localmente el nombre del receptor, los trazos de la firma y una fotografía comprimida.

Las cantidades monetarias de las tablas nuevas se expresan en céntimos enteros. El inventario distingue stock físico, reservado y disponible. Cada movimiento se registra en una transacción para impedir stock negativo o menor que la cantidad reservada.

## Roles y navegación

`RoleHome` resuelve la pantalla inicial según `UserRole`: cliente, almacén, repartidor, atención al cliente, administrador y trabajador de tienda. Los seis perfiles están habilitados en la demo.

El cliente reutiliza `ShopShell`. Almacén combina inventario y preparación. Repartidor gestiona entregas; atención procesa casos posventa; administración muestra indicadores; tienda administra reservas y retiros.

## Estado y controladores

Los flujos comerciales existentes continúan en `ShopState` y sus extensiones para evitar una migración riesgosa. Inventario ya usa un `InventoryController` independiente con un contrato de repositorio. Los siguientes módulos deben seguir este patrón y reducir gradualmente la responsabilidad de `ShopState`.

No se incorpora otro framework de estado. `ChangeNotifier` es suficiente para el alcance académico y mantiene bajo el número de dependencias.

## Pruebas

Las pruebas se agrupan en `test/core`, `test/features`, `test/integration` y `test/responsive`. SQLite se prueba con una base aislada en memoria mediante `sqflite_common_ffi`. Las pruebas verifican migraciones, sesión local, transacciones de inventario y pedidos, reversión ante falta de stock, navegación por roles y adaptación de los paneles a 320 px con texto ampliado.

Ejecutar desde la raíz:

```powershell
flutter analyze
flutter test
```
