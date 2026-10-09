import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module.js';
import { PrismaService } from './../src/database/prisma.service.js';

describe('AppController (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let temporaryEmail: string | undefined;
  let consumedStock: { variantId: string; quantity: number } | undefined;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
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
    for (const category of categories.body) {
      expect(category).toEqual({
        id: expect.any(String),
        name: expect.any(String),
        slug: expect.any(String),
        productCount: expect.any(Number),
        image: category.image === null ? null : expect.stringMatching(/^https?:\/\//),
      });
      expect(category.productCount).toBeGreaterThan(0);
    }
    if (categories.body.length > 0) {
      const [first] = categories.body;
      const inCategory = await request(app.getHttpServer())
        .get(`/catalog/products?category=${first.slug}&limit=1`)
        .expect(200);
      expect(inCategory.body.pagination.total).toBe(first.productCount);
    }

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

  it('protects account features and exposes public content', async () => {
    const server = app.getHttpServer();
    await Promise.all([
      request(server).get('/favorites').expect(401),
      request(server).get('/orders').expect(401),
      request(server).get('/addresses').expect(401),
      request(server).post('/addresses').send({}).expect(401),
      request(server).post('/orders').send({ paymentMethod: 'WALLET' }).expect(401),
      request(server).get('/loyalty').expect(401),
      request(server).post('/gift-cards').send({}).expect(401),
      request(server).patch('/me').send({ name: 'Sin Token' }).expect(401),
    ]);

    const stores = await request(server).get('/content/stores').expect(200);
    expect(stores.body).toEqual(expect.any(Array));
    const posts = await request(server).get('/content/blog').expect(200);
    expect(posts.body).toEqual(expect.any(Array));
    if (posts.body.length > 0) {
      await request(server).get(`/content/blog/${posts.body[0].slug}`).expect(200);
    }
    await request(server).get('/content/blog/articulo-inexistente-e2e').expect(404);
  });

  it('runs favorites, profile, checkout, tracking, loyalty and gift cards for a user', async () => {
    const server = app.getHttpServer();
    temporaryEmail = `e2e-flow-${Date.now()}@example.com`;
    const registration = await request(server)
      .post('/auth/register')
      .send({ email: temporaryEmail, name: 'Flujo E2E', password: 'UnaClaveE2E-Segura-123' })
      .expect(201);
    const auth = { Authorization: `Bearer ${registration.body.accessToken}` };

    const catalog = await request(server).get('/catalog/products?limit=50').expect(200);
    const product = catalog.body.data.find((item: { variants: Array<{ stock: number }> }) =>
      item.variants.some((variant) => variant.stock > 0),
    );
    expect(product).toBeDefined();
    const variant = product.variants.find((item: { stock: number }) => item.stock > 0);

    const favorites = await request(server).put(`/favorites/${product.id}`).set(auth).expect(200);
    expect(favorites.body.map((item: { id: string }) => item.id)).toEqual([product.id]);
    await request(server).put(`/favorites/${product.id}`).set(auth).expect(200);
    const removed = await request(server).delete(`/favorites/${product.id}`).set(auth).expect(200);
    expect(removed.body).toEqual([]);

    const profile = await request(server)
      .patch('/me')
      .set(auth)
      .send({ name: 'Flujo Editado', phone: '912345678' })
      .expect(200);
    expect(profile.body).toMatchObject({ name: 'Flujo Editado', phone: '912345678', email: temporaryEmail });
    await request(server).patch('/me').set(auth).send({ phone: '123' }).expect(400);

    const home = {
      label: 'Casa',
      recipient: 'Flujo Editado',
      line1: 'Av. Arequipa 1234, dpto 501',
      district: 'Miraflores',
      province: 'Lima',
      department: 'Lima',
      reference: 'Frente al parque',
      phone: '912345678',
    };
    await request(server).post('/addresses').set(auth).send({ ...home, line1: 'Av' }).expect(400);
    await request(server).post('/addresses').set(auth).send({ ...home, phone: '123' }).expect(400);
    const firstList = await request(server).post('/addresses').set(auth).send(home).expect(201);
    expect(firstList.body).toHaveLength(1);
    expect(firstList.body[0]).toMatchObject({ ...home, isDefault: true });
    const homeId = firstList.body[0].id;
    const secondList = await request(server)
      .post('/addresses')
      .set(auth)
      .send({ ...home, label: 'Trabajo', line1: 'Calle Las Begonias 415', district: 'San Isidro', isDefault: true })
      .expect(201);
    expect(secondList.body.map((item: { label: string; isDefault: boolean }) => [item.label, item.isDefault])).toEqual([
      ['Trabajo', true],
      ['Casa', false],
    ]);
    const workId = secondList.body[0].id;
    const updated = await request(server)
      .put(`/addresses/${homeId}`)
      .set(auth)
      .send({ ...home, reference: 'Puerta verde', isDefault: true })
      .expect(200);
    expect(updated.body[0]).toMatchObject({ id: homeId, reference: 'Puerta verde', isDefault: true });

    await request(server).post('/orders').set(auth).send({ paymentMethod: 'WALLET' }).expect(400);
    await request(server).post('/cart/items').set(auth).send({ variantId: variant.id, quantity: 1 }).expect(201);
    await request(server).post('/orders').set(auth).send({ paymentMethod: 'CARD' }).expect(422);
    await request(server)
      .post('/orders')
      .set(auth)
      .send({ paymentMethod: 'WALLET', addressId: '00000000-0000-4000-8000-000000000000' })
      .expect(404);

    const order = await request(server)
      .post('/orders')
      .set(auth)
      .send({ paymentMethod: 'WALLET', addressId: workId })
      .expect(201);
    consumedStock = { variantId: variant.id, quantity: 1 };
    expect(order.body).toMatchObject({ status: 'PREPARATION', paymentMethod: 'WALLET', shipping: '6.9' });
    expect(order.body.address).toMatchObject({ line1: 'Calle Las Begonias 415', district: 'San Isidro' });

    const afterDelete = await request(server).delete(`/addresses/${homeId}`).set(auth).expect(200);
    expect(afterDelete.body).toEqual([expect.objectContaining({ id: workId, isDefault: true })]);
    await request(server).delete(`/addresses/${homeId}`).set(auth).expect(404);
    expect(order.body.items).toHaveLength(1);
    expect(order.body.items[0]).toMatchObject({ variantId: variant.id, quantity: 1, productSlug: product.slug });
    const emptyCart = await request(server).get('/cart').set(auth).expect(200);
    expect(emptyCart.body.items).toEqual([]);

    const orders = await request(server).get('/orders').set(auth).expect(200);
    expect(orders.body.map((item: { publicNumber: string }) => item.publicNumber)).toEqual([order.body.publicNumber]);
    const delivered = await request(server)
      .patch(`/orders/${order.body.publicNumber}/status`)
      .set(auth)
      .send({ status: 'DELIVERED' })
      .expect(200);
    expect(delivered.body.status).toBe('DELIVERED');
    expect(delivered.body.statusHistory.map((entry: { status: string }) => entry.status)).toEqual([
      'PREPARATION',
      'DISPATCH',
      'TRANSIT',
      'DELIVERED',
    ]);
    await request(server)
      .patch(`/orders/${order.body.publicNumber}/status`)
      .set(auth)
      .send({ status: 'TRANSIT' })
      .expect(400);

    const purchasePoints = Math.floor(Number(order.body.total));
    const loyalty = await request(server).get('/loyalty').set(auth).expect(200);
    expect(loyalty.body).toMatchObject({ points: purchasePoints, lifetimePoints: purchasePoints, walletBalance: '0.00' });

    const recycling = await request(server).post('/loyalty/recycling').set(auth).expect(201);
    expect(recycling.body.code).toMatch(/^RSK-\d{6}$/);
    expect(recycling.body.summary.points).toBe(purchasePoints + 50);
    await request(server).post('/loyalty/recycling').set(auth).expect(400);

    const redeemed = await request(server).post('/loyalty/redeem').set(auth).expect(201);
    const blocks = Math.floor((purchasePoints + 50) / 100);
    expect(redeemed.body.points).toBe(purchasePoints + 50 - blocks * 100);
    expect(redeemed.body.lifetimePoints).toBe(purchasePoints + 50);
    expect(redeemed.body.walletBalance).toBe((blocks * 5).toFixed(2));
    await request(server).post('/loyalty/redeem').set(auth).expect(400);

    await request(server)
      .post('/gift-cards')
      .set(auth)
      .send({ amount: 75, recipientName: 'Ana Pérez', recipientEmail: 'ana@example.com' })
      .expect(400);
    const giftCard = await request(server)
      .post('/gift-cards')
      .set(auth)
      .send({ amount: 100, recipientName: 'Ana Pérez', recipientEmail: 'ana@example.com', message: '¡Feliz día!' })
      .expect(201);
    expect(giftCard.body).toMatchObject({ amount: '100.00', recipientEmail: 'ana@example.com' });
    expect(giftCard.body.code).toMatch(/^GC-[0-9A-F]{4}-[0-9A-F]{4}$/);
    const giftCards = await request(server).get('/gift-cards').set(auth).expect(200);
    expect(giftCards.body).toHaveLength(1);
  });

  afterEach(async () => {
    if (consumedStock) {
      await prisma.productVariant.update({
        where: { id: consumedStock.variantId },
        data: { stock: { increment: consumedStock.quantity } },
      });
      consumedStock = undefined;
    }
    if (temporaryEmail) {
      await prisma.order.deleteMany({ where: { user: { email: temporaryEmail } } });
      await prisma.user.delete({ where: { email: temporaryEmail } });
      temporaryEmail = undefined;
    }
    await app.close();
  });
});
