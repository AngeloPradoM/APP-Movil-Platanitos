import '../shared/models/shop_models.dart';

const products = [
  Product(
    id: 1,
    brand: 'PLATANITOS',
    name: 'Zapatilla Plataforma',
    category: 'Zapatillas',
    price: 89.9,
    oldPrice: 129.9,
    image: 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?fit=crop&q=85&w=800',
    color: 'Blanco',
    lowStock: true,
  ),
  Product(
    id: 2,
    brand: 'VIZZANO',
    name: 'Botines Chelsea Abril',
    category: 'Botines',
    price: 159.9,
    oldPrice: 219.9,
    image: 'https://images.unsplash.com/photo-1605732440685-d0654d81aa30?fit=crop&q=85&w=800',
    color: 'Negro',
  ),
  Product(
    id: 3,
    brand: 'BEIRA RIO',
    name: 'Tacos Amelia',
    category: 'Tacos',
    price: 119.9,
    oldPrice: 169.9,
    image: 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?fit=crop&q=85&w=800',
    color: 'Floral',
    lowStock: true,
  ),
  Product(
    id: 4,
    brand: 'PLATANITOS',
    name: 'Sandalias Taco Cuadrado',
    category: 'Sandalias',
    price: 79.9,
    oldPrice: 119.9,
    image: 'https://images.unsplash.com/photo-1591884807537-0bce39888fe0?fit=crop&q=85&w=800',
    color: 'Camel',
  ),
];
const demoUser = AppUser(
  name: 'Daniela Fernanda Rojas Salazar',
  document: 'DNI 74281639',
  email: 'daniela.rojas@gmail.com',
  phone: '987654321',
);
const demoAddress = ShippingAddress(
  id: 'local-demo',
  label: 'Casa',
  recipient: 'Daniela Rojas',
  line1: 'Av. Arequipa 1234, dpto 501',
  district: 'Miraflores',
  province: 'Lima',
  department: 'Lima',
  reference: 'Frente al parque Kennedy',
  phone: '987654321',
  isDefault: true,
);
const bannerImage =
    'https://images.unsplash.com/photo-1697086317645-11bd9e74e2cf?fit=crop&q=85&w=1000';
const galleryImages = [
  'https://images.unsplash.com/photo-1678784973551-f38208de2529?fit=crop&q=85&w=900',
  'https://images.unsplash.com/photo-1519415943484-9fa1873496d4?fit=crop&q=85&w=900',
];
const giftCardAmounts = [50.0, 100.0, 150.0, 200.0];
const stores = [
  StoreLocation(
    name: 'Platanitos Jockey Plaza',
    district: 'Santiago de Surco',
    address: 'Av. Javier Prado Este 4200, tienda 1-12',
    hours: 'Lun a Dom · 10:00 a 22:00',
  ),
  StoreLocation(
    name: 'Platanitos Mega Plaza',
    district: 'Independencia',
    address: 'Av. Alfredo Mendiola 3698, tienda 214',
    hours: 'Lun a Dom · 10:00 a 22:00',
  ),
  StoreLocation(
    name: 'Platanitos Plaza San Miguel',
    district: 'San Miguel',
    address: 'Av. La Marina 2000, tienda A-35',
    hours: 'Lun a Dom · 10:00 a 22:00',
  ),
  StoreLocation(
    name: 'Platanitos Real Plaza Salaverry',
    district: 'Jesús María',
    address: 'Av. Gral. Felipe Salaverry 2370, tienda 108',
    hours: 'Lun a Dom · 10:00 a 22:00',
  ),
];
const blogArticles = [
  BlogArticle(
    title: 'Cómo elegir la talla perfecta sin probarte el calzado',
    category: 'Guías',
    summary: 'Mide tu pie en casa y compara con nuestra tabla EUR, US y CM.',
    body: 'Coloca una hoja en el piso, apoya el talón contra la pared y marca la punta del dedo más largo. Mide la distancia en centímetros y busca ese valor en la tabla CM de la ficha del producto. Si estás entre dos tallas, elige la mayor para zapatillas y la menor para sandalias con correas ajustables.',
    image: 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?fit=crop&q=85&w=800',
    readMinutes: 3,
  ),
  BlogArticle(
    title: 'Tendencias de temporada: plataformas y tonos tierra',
    category: 'Tendencias',
    summary: 'Las suelas altas y los colores camel dominan esta temporada.',
    body: 'Las plataformas siguen siendo protagonistas por su comodidad y estilo. Combínalas con prendas en tonos tierra, beige y verde oliva. Para la noche, los tacos cuadrados ofrecen estabilidad sin perder elegancia.',
    image: 'https://images.unsplash.com/photo-1591884807537-0bce39888fe0?fit=crop&q=85&w=800',
    readMinutes: 4,
  ),
  BlogArticle(
    title: 'Cuida tus botines de cuero en temporada de lluvia',
    category: 'Cuidado',
    summary: 'Tres pasos sencillos para que tu calzado dure más.',
    body: 'Limpia el barro con un paño húmedo apenas llegues a casa. Deja secar a temperatura ambiente, nunca cerca de una fuente de calor. Aplica una crema hidratante incolora una vez por semana y usa un spray impermeabilizante antes de salir.',
    image: 'https://images.unsplash.com/photo-1605732440685-d0654d81aa30?fit=crop&q=85&w=800',
    readMinutes: 2,
  ),
];
