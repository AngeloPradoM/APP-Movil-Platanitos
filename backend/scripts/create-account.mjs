import 'dotenv/config';
import { PrismaClient, UserRole } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import * as argon2 from 'argon2';
import { createInterface } from 'node:readline/promises';
import { stdin, stdout } from 'node:process';
import { Writable } from 'node:stream';
let muted = false;
const output = new Writable({ write(chunk, encoding, callback) { if (!muted) stdout.write(chunk); callback(); } });
const rl = createInterface({ input: stdin, output, terminal: true });
let prisma;
try {
  const email = (await rl.question('Correo: ')).trim().toLowerCase();
  const name = (await rl.question('Nombre: ')).trim();
  const role = (await rl.question('Rol (ADMINISTRATIVO / POSTULANTE): ')).trim().toUpperCase();
  // Use a hidden prompt so credentials do not appear in terminal output.
  stdout.write('Contrasena (minimo 8 caracteres): ');
  muted = true;
  const password = await rl.question('');
  muted = false;
  stdout.write('\n');
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || !name || !Object.values(UserRole).includes(role) || password.length < 8 || password.length > 128) throw new Error('Datos de cuenta invalidos.');
  prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }) });
  if (await prisma.user.findUnique({ where: { email } })) throw new Error('El correo ya existe; no se modifico la cuenta.');
  const passwordHash = await argon2.hash(password, { type: argon2.argon2id, memoryCost: 19456, timeCost: 2, parallelism: 1 });
  await prisma.user.create({ data: { email, name, role, passwordCredential: { create: { passwordHash } } } });
  console.log('Cuenta creada: ' + email + ' (' + role + ')');
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally { rl.close(); await prisma?.$disconnect(); }
