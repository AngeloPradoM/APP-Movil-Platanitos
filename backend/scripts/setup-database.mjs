// Prepara la base de datos con un solo comando (`npm run db:setup`):
// crea la base indicada en DATABASE_URL si no existe, aplica las migraciones,
// genera el cliente de Prisma y carga los datos de demostración.
// Nunca imprime DATABASE_URL ni la contraseña.
import 'dotenv/config';
import { spawnSync } from 'node:child_process';
import pg from 'pg';

function fail(message) {
  console.error(`\n✖ ${message}\n`);
  process.exit(1);
}

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  fail('Falta DATABASE_URL. Copia .env.example como .env dentro de backend/ y complétalo (ver README, paso 5).');
}

let target;
try {
  target = new URL(databaseUrl);
} catch {
  fail('DATABASE_URL no tiene un formato válido. Debe verse así: postgresql://USUARIO:CONTRASENA@127.0.0.1:5432/platanitos');
}

const databaseName = decodeURIComponent(target.pathname.replace(/^\//, ''));
if (!/^[A-Za-z0-9_]+$/.test(databaseName)) {
  fail('El nombre de la base de datos en DATABASE_URL solo puede tener letras, números y guiones bajos (por ejemplo, platanitos).');
}

function explain(error) {
  switch (error?.code) {
    case '28P01':
      return 'Usuario o contraseña de PostgreSQL incorrectos. Revisa DATABASE_URL en backend/.env.';
    case 'ECONNREFUSED':
      return 'No se pudo conectar a PostgreSQL. Verifica que el servicio esté iniciado y que el host y puerto de DATABASE_URL sean correctos.';
    case 'ENOTFOUND':
      return 'No se encontró el host indicado en DATABASE_URL.';
    case '42501':
      return `El usuario no tiene permiso para crear bases de datos. Crea "${databaseName}" manualmente en pgAdmin y vuelve a ejecutar el comando.`;
    case '3D000':
      return 'No existe la base de mantenimiento "postgres". Crea la base manualmente y vuelve a ejecutar el comando.';
    default:
      return `No se pudo preparar la base de datos (${error?.code ?? 'error desconocido'}).`;
  }
}

const maintenanceUrl = new URL(databaseUrl);
maintenanceUrl.pathname = '/postgres';
const client = new pg.Client({ connectionString: maintenanceUrl.toString() });

console.log(`\n▶ Paso 1/4: comprobando la base de datos "${databaseName}"…`);
try {
  await client.connect();
  const { rowCount } = await client.query('SELECT 1 FROM pg_database WHERE datname = $1', [databaseName]);
  if (rowCount === 0) {
    await client.query(`CREATE DATABASE "${databaseName}"`);
    console.log(`  Base de datos "${databaseName}" creada.`);
  } else {
    console.log(`  La base de datos "${databaseName}" ya existe; se conserva su contenido.`);
  }
} catch (error) {
  fail(explain(error));
} finally {
  await client.end().catch(() => {});
}

const steps = [
  ['Paso 2/4: aplicando migraciones', 'npx prisma migrate deploy'],
  ['Paso 3/4: generando el cliente de Prisma', 'npx prisma generate'],
  ['Paso 4/4: cargando datos de demostración', 'npm run db:seed'],
];

for (const [title, command] of steps) {
  console.log(`\n▶ ${title}…`);
  const result = spawnSync(command, { stdio: 'inherit', shell: true });
  if (result.status !== 0) fail(`Falló "${command}". Revisa el mensaje anterior.`);
}

console.log('\n✔ Base de datos lista. Ahora ejecuta: npm run start:dev\n');
