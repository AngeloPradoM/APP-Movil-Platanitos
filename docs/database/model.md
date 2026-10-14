# Modelo y persistencia

El esquema esta en [schema.prisma](../../backend/prisma/schema.prisma). Las migraciones viven en backend/prisma/migrations. La entrada de npm.cmd run db:seed es prisma/seeds/seed.ts.

PostgreSQL almacena clientes, credenciales protegidas, sesiones, direcciones, catalogo, carrito, pedidos, pagos, favoritos y beneficios. La reorganizacion conserva el esquema, los datos y las cuentas existentes.

Las variables privadas permanecen en backend/.env; el cluster local reside en .local. Ambos estan excluidos de Git.
