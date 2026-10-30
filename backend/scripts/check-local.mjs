import { existsSync, readFileSync } from 'node:fs';
import { parseEnv } from 'node:util';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

const envPath = fileURLToPath(new URL('../.env', import.meta.url));
function fail(message) { console.error(message); process.exitCode = 1; }
async function check() {
  if (!existsSync(envPath)) throw new Error('Falta backend/.env. Ejecuta scripts/setup.ps1 para crear la configuración local.');
  const config = { ...parseEnv(readFileSync(envPath, 'utf8')), ...process.env };
  const port = Number(config.PORT ?? 3000);
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('PORT debe ser un puerto válido.');
  const value = config.DATABASE_URL ?? '';
  if (!value || /USUARIO|CONTRASENA|CAMBIAR/.test(value)) throw new Error('Completa DATABASE_URL en backend/.env con tus credenciales de PostgreSQL. No es necesario compartirlas en el chat.');
  let database;
  try { database = new URL(value); } catch { throw new Error('DATABASE_URL no tiene un formato válido.'); }
  if (!['postgres:', 'postgresql:'].includes(database.protocol) || !database.hostname || !database.pathname.slice(1)) throw new Error('DATABASE_URL debe indicar una base PostgreSQL válida.');
  const secret = config.JWT_ACCESS_SECRET ?? '';
  if (secret.length < 32 || secret.includes('CAMBIAR')) throw new Error('JWT_ACCESS_SECRET debe contener un secreto aleatorio de al menos 32 caracteres.');
  console.log(`Configuración válida. API local: http://${config.HOST === '0.0.0.0' ? '127.0.0.1' : config.HOST ?? '127.0.0.1'}:${port}`);
  if (process.argv.includes('--database')) {
    const client = new pg.Client({ connectionString: value, connectionTimeoutMillis: 5000 });
    try {
      await client.connect();
      await client.query('SELECT 1');
      const result = await client.query("SELECT to_regclass('public.\"Product\"') AS products");
      if (!result.rows[0]?.products) throw new Error('La conexión funciona, pero faltan las tablas. Ejecuta npm.cmd run db:setup desde backend/.');
      console.log('PostgreSQL accesible y tablas del catálogo presentes.');
    } catch (error) {
      if (error.code === '28P01') throw new Error('PostgreSQL rechazó el usuario o contraseña. Revisa DATABASE_URL.');
      if (error.code === '3D000') throw new Error('La base no existe todavía. Ejecuta npm.cmd run db:setup desde backend/.');
      if (error.code === 'ECONNREFUSED') throw new Error('PostgreSQL no responde. Comprueba el servicio, host y puerto.');
      if (error.message?.startsWith('La conexión funciona')) throw error;
      throw new Error('No fue posible comprobar PostgreSQL. Revisa la conexión de backend/.env.');
    } finally { await client.end().catch(() => {}); }
  }
}
check().catch((error) => fail(error.message));
