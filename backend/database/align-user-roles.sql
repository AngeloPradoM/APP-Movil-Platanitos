-- Roles que usa la app Flutter.
-- Ejecutar a mano en el SQL editor del Supabase de Platanitos.
-- El esquema actual de "User" no tiene columna role.
-- No ejecutar si "UserRole" ya existe: en ese caso avisar antes de seguir.

CREATE TYPE "UserRole" AS ENUM (
  'CLIENTE',
  'ALMACEN',
  'REPARTIDOR',
  'ATENCION_CLIENTE',
  'ADMINISTRADOR',
  'TRABAJADOR_TIENDA'
);

ALTER TABLE "User"
  ADD COLUMN "role" "UserRole" NOT NULL DEFAULT 'CLIENTE';

-- Las cuentas nuevas quedan como CLIENTE.
-- Para un panel de staff, asigna el rol después del registro, por ejemplo:
-- UPDATE "User" SET "role" = 'ADMINISTRADOR' WHERE email = 'correo@ejemplo.com';
