# Arquitectura del backend

NestJS agrupa las funcionalidades en src/modules. Cada modulo mantiene controllers, services, DTOs y mappers cuando corresponda.

- src/config: configuracion HTTP, CORS y puerto.
- src/common/decorators: decoradores compartidos.
- src/database: modulo y servicio Prisma.
- src/modules/auth: registro, login, renovacion, cierre de sesion y perfil.
- src/modules/administration: consulta de usuarios con autorizacion por rol.
- src/modules/health: disponibilidad.
- src/modules/catalog, cart, favorites, orders, addresses, loyalty, gift-cards y content: funcionalidades comerciales.
- prisma/schema.prisma y prisma/migrations: esquema e historial de migraciones.
- prisma/seeds: datos iniciales.
- database: SQL de instalacion y catalogo.
- scripts: preparacion y creacion de cuentas.
- test: integracion contra PostgreSQL.

Los endpoints y los datos se conservan; esta reorganizacion no requiere migraciones de datos.

Desde backend: npm.cmd run build, npm.cmd run lint, npm.cmd run test y npm.cmd run test:e2e. Para e2e, PostgreSQL debe estar activo.

## Integraciones demostrativas

Google, Apple, recuperacion de contrasena, cobros y tracking externo requieren integraciones adicionales. La API raiz devuelve informacion del servicio y la ruta /health. PostgreSQL y la autenticacion con correo y contrasena estan implementados.
