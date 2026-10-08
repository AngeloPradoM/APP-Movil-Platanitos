import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module.js';
import { PrismaService } from './../src/database/prisma.service.js';

describe('AppController (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let temporaryEmail: string | undefined;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
    prisma = app.get(PrismaService);
  });

  it('/ (GET)', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect('Hello World!');
  });

  it('/me (GET) rejects unauthenticated requests', () => {
    return request(app.getHttpServer()).get('/me').expect(401);
  });

  it('protects the persistent cart for authenticated users', () => {
    return Promise.all([
      request(app.getHttpServer()).get('/cart').expect(401),
      request(app.getHttpServer()).post('/cart/sync').send({ items: [] }).expect(401),
    ]);
  });

  it('exposes the public catalog without authentication', async () => {
    const catalog = await request(app.getHttpServer())
      .get('/catalog/products?page=1&limit=10')
      .expect(200);
    expect(catalog.body.data).toEqual(expect.any(Array));
    expect(catalog.body.pagination).toMatchObject({ page: 1, limit: 10 });

    await request(app.getHttpServer())
      .get('/catalog/products/slug-inexistente-e2e')
      .expect(404);

    const categories = await request(app.getHttpServer()).get('/catalog/categories').expect(200);
    expect(categories.body).toEqual(expect.any(Array));

    const brands = await request(app.getHttpServer()).get('/catalog/brands').expect(200);
    expect(brands.body).toEqual(expect.any(Array));
  });

  it('registers, authenticates, refreshes and logs out a user', async () => {
    temporaryEmail = `e2e-${Date.now()}@example.com`;
    const credentials = {
      email: temporaryEmail,
      name: 'Usuario E2E',
      password: 'UnaClaveE2E-Segura-123',
      phone: '987654321',
    };

    const registration = await request(app.getHttpServer())
      .post('/auth/register')
      .send(credentials)
      .expect(201);
    expect(registration.body.user.email).toBe(temporaryEmail);
    expect(registration.body.accessToken).toEqual(expect.any(String));
    expect(registration.body.refreshToken).toEqual(expect.any(String));

    const me = await request(app.getHttpServer())
      .get('/me')
      .set('Authorization', `Bearer ${registration.body.accessToken}`)
      .expect(200);
    expect(me.body.email).toBe(temporaryEmail);

    const refreshed = await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: registration.body.refreshToken })
      .expect(201);
    expect(refreshed.body.accessToken).toEqual(expect.any(String));
    expect(refreshed.body.refreshToken).not.toBe(registration.body.refreshToken);

    await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: registration.body.refreshToken })
      .expect(401);

    await request(app.getHttpServer())
      .post('/auth/logout')
      .send({ refreshToken: refreshed.body.refreshToken })
      .expect(204);
  });

  afterEach(async () => {
    if (temporaryEmail) {
      await prisma.user.delete({ where: { email: temporaryEmail } });
      temporaryEmail = undefined;
    }
    await app.close();
  });
});
