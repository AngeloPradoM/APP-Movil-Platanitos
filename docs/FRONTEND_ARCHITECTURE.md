# Arquitectura del frontend

## Criterio de organización

El frontend se migrará gradualmente desde una organización global por tipo de archivo hacia una organización por funcionalidad. Cada funcionalidad agrupa sus contratos remotos, modelos de respuesta, estado y pantallas relacionadas.

```text
lib/
├── app/
│   ├── app.dart                 # MaterialApp y composición raíz
│   └── dependencies.dart        # Inyección de dependencias
├── core/
│   ├── config/                  # URLs y configuración por entorno
│   ├── errors/                  # Errores y mensajes presentables
│   ├── network/                 # ApiClient y configuración HTTP
│   └── theme/                   # Tema visual
├── features/
│   ├── auth/
│   │   ├── data/                # AuthRepository, SessionStorage
│   │   ├── domain/              # Entidades y contratos de auth
│   │   ├── presentation/        # Login, registro, recuperación
│   │   └── state/               # Sesión autenticada
│   ├── catalog/
│   │   ├── data/                # CatalogRepository y DTOs
│   │   ├── domain/              # Producto y variante remotos
│   │   └── presentation/        # Catálogo y detalle
│   ├── cart/
│   ├── checkout/
│   ├── orders/
│   └── account/
├── shared/
│   ├── models/                  # Modelos compartidos entre features
│   └── widgets/                 # Componentes visuales reutilizables
└── main.dart
```

## Reglas

1. Las pantallas no realizan llamadas HTTP directamente.
2. Los repositorios no dependen de widgets ni de `BuildContext`.
3. Las entidades de dominio no dependen de Prisma, JSON ni Flutter UI.
4. Los DTOs remotos se convierten en entidades mediante mappers.
5. Los errores técnicos se convierten en mensajes seguros en la capa de presentación.
6. Las dependencias se inyectan desde la composición raíz.
7. Cada migración de carpetas debe conservar `flutter analyze` y todas las pruebas.

## Migración incremental

La primera etapa mantiene los archivos existentes para no romper el prototipo. Las nuevas integraciones ya respetan estas reglas mediante `ApiClient`, repositorios y `AppDependencies`. La siguiente migración moverá autenticación a `features/auth` y actualizará imports en una sola etapa verificable.
