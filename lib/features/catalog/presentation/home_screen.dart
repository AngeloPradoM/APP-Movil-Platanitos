import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../shared/models/shop_models.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/shop_widgets.dart';
import '../../account/presentation/account_services_screens.dart';
import '../../auth/presentation/auth_screens.dart';
import '../../support/presentation/support_screens.dart';
import 'catalog_screens.dart';

String _photo(String id) =>
    'https://images.unsplash.com/$id?fit=crop&q=85&w=800';

bool Function(Product) _named(List<String> words) => (product) {
  final name = product.name.toLowerCase();
  return words.any(name.contains);
};

/// Colecciones de la portada; cada una abre el catálogo filtrado.
abstract final class _Collections {
  static final shoes = ProductCollection(
    'Calzado',
    (product) => product.sizeSystem == SizeSystem.eur,
  );
  static final bags = ProductCollection.categories('Carteras y bolsos', [
    'cartera',
    'bolso',
    'mochila',
  ]);
  static final offers = ProductCollection(
    'Ofertas',
    (product) => product.onSale,
  );
  static final accessories = ProductCollection.categories('Accesorios', [
    'accesorio',
    'reloj',
    'correa',
    'billetera',
    'joyer',
  ]);
  static final sneakers = ProductCollection.categories('Zapatillas', [
    'zapatilla',
  ]);
  static final running = ProductCollection.categories('Running', ['running']);
  static final football = ProductCollection.categories('Fútbol', ['futbol']);
  static final sandals = ProductCollection.categories('Sandalias', [
    'sandalia',
  ]);
  static final boots = ProductCollection.categories('Botines', [
    'bota',
    'botin',
  ]);
  static final dress = ProductCollection.categories('Vestir', [
    'vestir',
    'mocasin',
    'taco',
    'ballerina',
  ]);
  static final handbags = ProductCollection.categories('Carteras', [
    'cartera',
  ]);
  static final backpacks = ProductCollection.categories('Mochilas', [
    'mochila',
  ]);
  static final clothing = ProductCollection.categories(
    'Ropa',
    [
      'polo',
      'polera',
      'pantal',
      'jean',
      'vestido',
      'blusa',
      'casaca',
      'short',
      'legging',
      'falda',
      'pijama',
      'ropa',
      'conjunto',
    ],
  );
  static final women = ProductCollection('Mujer', _named(['mujer', 'dama']));
  static final men = ProductCollection('Hombre', _named(['hombre']));
  static final kids = ProductCollection(
    'Niños',
    _named(['niño', 'niña', 'kids', 'juvenil', 'escolar']),
  );
}

typedef _Showcase = ({String image, ProductCollection collection});
typedef _Slide = ({
  String image,
  String title,
  String subtitle,
  ProductCollection collection,
});

/// Secciones de la portada calculadas una sola vez por versión del catálogo.
class _HomeContent {
  _HomeContent._({
    required this.slides,
    required this.categories,
    required this.recommended,
    required this.deals,
    required this.brands,
    required this.audiences,
    required this.trending,
    required this.latest,
  });

  factory _HomeContent.from(
    List<Product> source,
    ProductCollection tab,
    bool hasMore,
  ) {
    bool available(ProductCollection collection) =>
        hasMore || source.any(collection.matches);
    final deals = source.where((product) => product.onSale).toList()
      ..sort(
        (a, b) => b.discount != a.discount
            ? b.discount.compareTo(a.discount)
            : a.id.compareTo(b.id),
      );
    final sneakers = source.where(_Collections.sneakers.matches).toList();
    int rank(Product product) {
      final category = product.category.toLowerCase();
      if (category.contains('urbana')) return 0;
      return category.contains('running') ? 1 : 2;
    }

    final present = <String, String>{};
    final frequency = <String, int>{};
    for (final product in source) {
      if (product.brand.isEmpty) continue;
      present.putIfAbsent(product.brand.toLowerCase(), () => product.brand);
      frequency.update(product.brand, (count) => count + 1, ifAbsent: () => 1);
    }
    final brands = <String>[
      for (final brand in _HomeScreenState.topBrands)
        if (present[brand.toLowerCase()] case final name?)
          name
        else if (hasMore)
          brand,
    ];
    final others =
        frequency.keys.where((brand) => !brands.contains(brand)).toList()
          ..sort((a, b) => frequency[b]!.compareTo(frequency[a]!));
    if (brands.length < 10) brands.addAll(others.take(10 - brands.length));

    return _HomeContent._(
      slides: [
        for (final slide in _HomeScreenState.slides)
          if (available(slide.collection)) slide,
      ],
      categories: [
        for (final category in _HomeScreenState.categories)
          if (available(category.collection)) category,
      ],
      recommended: source.where(tab.matches).take(16).toList(growable: false),
      deals: deals.take(12).toList(growable: false),
      brands: brands,
      audiences: [
        for (final audience in _HomeScreenState.audiences)
          if (available(audience.collection)) audience,
      ],
      trending: [
        for (var level = 0; level < 3; level++)
          ...sneakers.where((product) => rank(product) == level),
      ].take(12).toList(growable: false),
      latest: source.reversed.take(8).toList(growable: false),
    );
  }

  final List<_Slide> slides;
  final List<_Showcase> categories, audiences;
  final List<Product> recommended, deals, trending, latest;
  final List<String> brands;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onCatalog});
  final VoidCallback onCatalog;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final tabs = [
    _Collections.shoes,
    _Collections.bags,
    _Collections.offers,
    _Collections.accessories,
  ];
  static const _tabLabels = ['Calzado', 'Carteras', 'Ofertas', 'Accesorios'];
  static const topBrands = [
    'Nike',
    'Adidas',
    'Puma',
    'Vans',
    'Converse',
    'Skechers',
    'New Balance',
    'Platanitos',
    'Reebok',
    'Under Armour',
    'Crocs',
    'CAT',
  ];
  static final List<_Slide> slides = [
    (
      image: _photo('photo-1549298916-b41d501d3772'),
      title: 'Cyber Platanitos',
      subtitle: 'Hasta 50% de descuento en zapatillas y carteras',
      collection: _Collections.offers,
    ),
    (
      image: _photo('photo-1600185365483-26d7a4cc7519'),
      title: 'Zapatillas para todo',
      subtitle: 'Urbanas, running y training de tus marcas favoritas',
      collection: _Collections.sneakers,
    ),
    (
      image: _photo('photo-1591884807537-0bce39888fe0'),
      title: 'Nueva temporada',
      subtitle: 'Tacos, mocasines y sandalias para cada ocasión',
      collection: _Collections.dress,
    ),
    (
      image: _photo('photo-1605732440685-d0654d81aa30'),
      title: 'Botines y botas',
      subtitle: 'Abrígate con estilo esta temporada',
      collection: _Collections.boots,
    ),
  ];
  static final List<_Showcase> categories = [
    (
      image: _photo('photo-1525966222134-fcfa99b8ae77'),
      collection: _Collections.sneakers,
    ),
    (
      image: _photo('photo-1542291026-7eec264c27ff'),
      collection: _Collections.running,
    ),
    (
      image: _photo('photo-1579952363873-27f3bade9f55'),
      collection: _Collections.football,
    ),
    (
      image: _photo('photo-1562273138-f46be4ebdf33'),
      collection: _Collections.sandals,
    ),
    (
      image: _photo('photo-1605732440685-d0654d81aa30'),
      collection: _Collections.boots,
    ),
    (
      image: _photo('photo-1614252235316-8c857d38b5f4'),
      collection: _Collections.dress,
    ),
    (
      image: _photo('photo-1584917865442-de89df76afd3'),
      collection: _Collections.handbags,
    ),
    (
      image: _photo('photo-1553062407-98eeb64c6a62'),
      collection: _Collections.backpacks,
    ),
    (
      image: _photo('photo-1490481651871-ab68de25d43d'),
      collection: _Collections.clothing,
    ),
    (
      image: _photo('photo-1524592094714-0f0654e20314'),
      collection: _Collections.accessories,
    ),
  ];
  static final List<_Showcase> audiences = [
    (
      image: _photo('photo-1543163521-1bf539c55dd2'),
      collection: _Collections.women,
    ),
    (
      image: _photo('photo-1520639888713-7851133b1ed0'),
      collection: _Collections.men,
    ),
    (
      image: _photo('photo-1503919545889-aef636e10ad4'),
      collection: _Collections.kids,
    ),
  ];

  int section = 0;
  Object? _contentKey;
  _HomeContent? _content;

  _HomeContent _contentFor(ShopState state) {
    final source = state.catalogProducts;
    final key = (
      source.length,
      source.firstOrNull,
      source.lastOrNull,
      section,
      state.catalogHasMore,
    );
    if (key != _contentKey || _content == null) {
      _contentKey = key;
      _content = _HomeContent.from(source, tabs[section], state.catalogHasMore);
    }
    return _content!;
  }

  void _openCatalog([void Function(CatalogFilter filter)? select]) {
    final state = ShopScope.of(context);
    state.catalog
      ..clear()
      ..sort = ProductSort.recommended;
    select?.call(state.catalog);
    state.updateCatalog();
    widget.onCatalog();
  }

  /// Las colecciones por categoría abren directamente sus categorías; las
  /// demás (ofertas, público…) filtran el listado de la pestaña Categorías.
  void _openCollection(ProductCollection collection) {
    final words = collection.categoryWords?.map(normalizeText).toList();
    final categories = words == null
        ? const <ShopCategory>[]
        : [
            for (final category in ShopScope.of(context).categories)
              if (words.any(
                normalizeText('${category.name} ${category.slug}').contains,
              ))
                category,
          ];
    if (categories.isEmpty) {
      return _openCatalog((filter) => filter.collection = collection);
    }
    openCategory(context, title: collection.label, categories: categories);
  }

  void _openBrand(String brand) =>
      _openCatalog((filter) => filter.brands.add(brand));

  void _open(Product product) => openProduct(context, product);

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    final content = _contentFor(state);
    final deals = content.deals;
    return ColoredBox(
      color: AppColors.background,
      child: RefreshIndicator(
        color: AppColors.darkGreen,
        onRefresh: state.loadRemoteCatalog,
        child: CustomScrollView(
          key: const PageStorageKey('home'),
          slivers: [
            PinnedHeaderSliver(
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: SearchField(
                    value: state.catalog.query,
                    onChanged: (value) {
                      state.catalog.query = value;
                      state.updateCatalog();
                    },
                    onSubmit: widget.onCatalog,
                    trailing: [
                      IconButton(
                        tooltip: 'Buscar por voz',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => feedback(
                          context,
                          'La búsqueda por voz estará disponible pronto.',
                        ),
                        icon: const Icon(Icons.mic_none),
                      ),
                      IconButton(
                        tooltip: 'Escanear producto',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => feedback(
                          context,
                          'El escáner de productos estará disponible pronto.',
                        ),
                        icon: const Icon(Icons.crop_free),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionTabs(
                        labels: _tabLabels,
                        selected: section,
                        onSelected: (index) => setState(() => section = index),
                      ),
                      if (state.catalogLoading)
                        const LinearProgressIndicator(minHeight: 2),
                    ],
                  ),
                ),
              ),
            ),
            if (content.slides.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _HeroCarousel(
                    slides: content.slides,
                    onOpen: _openCollection,
                  ),
                ),
              ),
            if (content.categories.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeader('Compra por categoría'),
                    _CategoryRow(
                      categories: content.categories,
                      onOpen: _openCollection,
                    ),
                  ],
                ),
              ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(
                    'Recomendados para ti',
                    onMore: () => _openCollection(tabs[section]),
                  ),
                  if (content.recommended.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Pronto tendremos novedades en ${_tabLabels[section]}.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    )
                  else
                    RecommendedCarousel(
                      key: PageStorageKey('recommended-$section'),
                      products: content.recommended,
                      onOpen: _open,
                    ),
                ],
              ),
            ),
            if (deals.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 28),
                  padding: const EdgeInsets.only(bottom: 18),
                  color: AppColors.darkGreen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionHeader(
                        'Ofertas Cyber',
                        subtitle:
                            'Hasta -${deals.first.discount}% en productos seleccionados',
                        light: true,
                        badge: const _Countdown(),
                        onMore: () => _openCollection(_Collections.offers),
                      ),
                      RecommendedCarousel(
                        key: const PageStorageKey('deals'),
                        products: deals,
                        onOpen: _open,
                      ),
                    ],
                  ),
                ),
              ),
            if (content.brands.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeader(
                      'Compra por marca',
                      subtitle: 'Las marcas que más buscan en Platanitos',
                    ),
                    _BrandRow(brands: content.brands, onOpen: _openBrand),
                  ],
                ),
              ),
            if (content.audiences.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeader('Para toda la familia'),
                    _AudienceTiles(
                      audiences: content.audiences,
                      onOpen: _openCollection,
                    ),
                  ],
                ),
              ),
            if (content.trending.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionHeader(
                      'Zapatillas más buscadas',
                      subtitle: 'Urbanas y running que todos quieren',
                      onMore: () => _openCollection(_Collections.sneakers),
                    ),
                    RecommendedCarousel(
                      key: const PageStorageKey('trending'),
                      products: content.trending,
                      onOpen: _open,
                    ),
                  ],
                ),
              ),
            SliverToBoxAdapter(child: _ClubBanner(points: state.points)),
            if (content.latest.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: _SectionHeader(
                  'Novedades',
                  subtitle: 'Lo último que llegó a la tienda',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: ProductGrid.sliver(
                  products: content.latest,
                  onOpen: _open,
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: OutlinedButton.icon(
                  style: outlineGreenButtonStyle,
                  onPressed: () =>
                      openProductList(context, title: 'Todos los productos'),
                  icon: const Icon(Icons.grid_view_rounded, size: 20),
                  label: const Text('Ver todo el catálogo'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _Benefits()),
            const SliverPadding(
              padding: EdgeInsets.only(top: 28),
              sliver: SliverToBoxAdapter(child: _HomeFooter()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
    this.title, {
    this.subtitle,
    this.onMore,
    this.badge,
    this.light = false,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onMore;
  final Widget? badge;
  final bool light;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      light ? 18 : 28,
      onMore == null ? 16 : 4,
      10,
    ),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: light ? Colors.white : AppColors.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: light ? Colors.white70 : AppColors.muted,
                    ),
                  ),
                ],
                if (badge != null) ...[const SizedBox(height: 8), badge!],
              ],
            ),
          ),
        ),
        if (onMore != null)
          TextButton(
            onPressed: onMore,
            style: TextButton.styleFrom(
              foregroundColor: light ? AppColors.yellow : AppColors.darkGreen,
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Ver todo'),
          ),
      ],
    ),
  );
}

class SectionTabs extends StatelessWidget {
  const SectionTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final (index, label) in labels.indexed)
          Semantics(
            selected: index == selected,
            button: true,
            child: InkWell(
              onTap: () => onSelected(index),
              child: Padding(
                padding: const EdgeInsets.only(right: 18),
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: index == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: index == selected
                                ? AppColors.darkGreen
                                : AppColors.ink,
                          ),
                        ),
                      ),
                      Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: index == selected
                              ? AppColors.darkGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Banner principal: avanza solo cada 5 s salvo que el usuario lo toque o
/// haya pedido reducir las animaciones.
class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({required this.slides, required this.onOpen});
  final List<_Slide> slides;
  final ValueChanged<ProductCollection> onOpen;
  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  static const _interval = Duration(seconds: 5);
  static const _firstPage = 1200;
  final controller = PageController(initialPage: _firstPage);
  Timer? _timer;
  int page = _firstPage;
  bool _autoPlay = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) {
      if (_autoPlay && controller.hasClients) {
        controller.nextPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    _autoPlay =
        slides.length > 1 &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final current = page % slides.length;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height:
                (constraints.maxWidth / 2).clamp(180.0, 320.0) +
                (scale - 1) * 90,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: slides.length == 1
                  ? _slide(slides.single)
                  : Listener(
                      onPointerDown: (_) => _timer?.cancel(),
                      onPointerUp: (_) => _restart(),
                      onPointerCancel: (_) => _restart(),
                      child: PageView.builder(
                        controller: controller,
                        onPageChanged: (value) => setState(() => page = value),
                        itemBuilder: (context, index) =>
                            _slide(slides[index % slides.length]),
                      ),
                    ),
            ),
          ),
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: 10),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < slides.length; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == current ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: index == current
                          ? AppColors.darkGreen
                          : const Color(0xFFC9CED4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _slide(_Slide slide) => Semantics(
    button: true,
    label: '${slide.title}. ${slide.subtitle}. Comprar ahora',
    excludeSemantics: true,
    onTap: () => widget.onOpen(slide.collection),
    child: GestureDetector(
      onTap: () => widget.onOpen(slide.collection),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ShopImage(slide.image, thumbnail: true),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [Color(0xDD000000), Color(0x11000000)],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    slide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  slide.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    child: Text(
                      'Comprar ahora',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.categories, required this.onOpen});
  final List<_Showcase> categories;
  final ValueChanged<ProductCollection> onOpen;
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: 96 + 22 * scale,
      child: ListView.builder(
        key: const PageStorageKey('categories'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemExtent: 80 + (scale - 1) * 50,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final label = category.collection.label;
          return Semantics(
            button: true,
            label: 'Ver $label',
            excludeSemantics: true,
            onTap: () => onOpen(category.collection),
            child: InkWell(
              onTap: () => onOpen(category.collection),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.softGreen,
                      ),
                      child: ClipOval(
                        child: ShopImage(category.image, thumbnail: true),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RecommendedCarousel extends StatelessWidget {
  const RecommendedCarousel({
    super.key,
    required this.products,
    required this.onOpen,
  });
  final List<Product> products;
  final ValueChanged<Product> onOpen;
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: 236 + (scale - 1) * 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: 160 + (scale - 1) * 40,
          child: RecommendedCard(
            product: products[index],
            onOpen: () => onOpen(products[index]),
          ),
        ),
      ),
    );
  }
}

class RecommendedCard extends StatelessWidget {
  const RecommendedCard({
    super.key,
    required this.product,
    required this.onOpen,
  });
  final Product product;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ColoredBox(
                    color: AppColors.background,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ShopImage(product.image, thumbnail: true),
                        if (product.onSale)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: OfferBadge(discount: product.discount),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.brand.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: money(product.price),
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (product.onSale) ...[
                      const TextSpan(text: '  '),
                      TextSpan(
                        text: money(product.oldPrice),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Cuenta regresiva decorativa hasta la medianoche.
class _Countdown extends StatefulWidget {
  const _Countdown();
  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_active) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _active = TickerMode.valuesOf(context).enabled;
    final now = DateTime.now();
    final left = DateTime(now.year, now.month, now.day + 1).difference(now);
    String two(int value) => value.toString().padLeft(2, '0');
    final hours = left.inHours, minutes = left.inMinutes % 60;
    return Semantics(
      label: 'Las ofertas terminan en $hours horas y $minutes minutos',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.yellow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, size: 15, color: AppColors.ink),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Terminan en ${two(hours)}:${two(minutes)}:${two(left.inSeconds % 60)}',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.brands, required this.onOpen});
  final List<String> brands;
  final ValueChanged<String> onOpen;
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: 64 + (scale - 1) * 20,
      child: ListView.separated(
        key: const PageStorageKey('brands'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: brands.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final brand = brands[index];
          return Semantics(
            button: true,
            label: 'Ver productos de $brand',
            excludeSemantics: true,
            onTap: () => onOpen(brand),
            child: Material(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: InkWell(
                onTap: () => onOpen(brand),
                child: SizedBox(
                  width: 118 + (scale - 1) * 30,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          brand.toUpperCase(),
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.2,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AudienceTiles extends StatelessWidget {
  const _AudienceTiles({required this.audiences, required this.onOpen});
  final List<_Showcase> audiences;
  final ValueChanged<ProductCollection> onOpen;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - 10 * (audiences.length - 1)) /
            audiences.length;
        return SizedBox(
          height: (width * 1.3).clamp(140.0, 240.0),
          child: Row(
            children: [
              for (final (index, audience) in audiences.indexed) ...[
                if (index > 0) const SizedBox(width: 10),
                Expanded(child: _audienceTile(audience)),
              ],
            ],
          ),
        );
      },
    ),
  );

  Widget _audienceTile(_Showcase audience) {
    final label = audience.collection.label;
    return Semantics(
      button: true,
      label: 'Ver productos para $label',
      excludeSemantics: true,
      onTap: () => onOpen(audience.collection),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => onOpen(audience.collection),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShopImage(audience.image, thumbnail: true),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Color(0xCC000000), Colors.transparent],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ver más  ›',
                        style: TextStyle(
                          color: AppColors.yellow,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubBanner extends StatelessWidget {
  const _ClubBanner({required this.points});
  final int points;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 28, 16, 0),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [AppColors.darkGreen, AppColors.green],
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLATANITOS CLUB',
                  style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gana 1 punto por cada S/ 1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Canjea ${ShopState.pointsPerRedemption} puntos por '
                  '${money(ShopState.redemptionValue)} en tu monedero. '
                  'Hoy tienes $points puntos.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => openWithLogin(
                    context,
                    AuthPrompt.account,
                    (_) => const PointsScreen(),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(0, 44),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  child: const Text('Ver mis puntos'),
                ),
              ],
            ),
          ),
          if (constraints.maxWidth >= 340) ...[
            const SizedBox(width: 12),
            const ExcludeSemantics(
              child: Icon(
                Icons.workspace_premium_outlined,
                size: 64,
                color: AppColors.yellow,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Benefits extends StatelessWidget {
  const _Benefits();
  static const _items = [
    (
      Icons.local_shipping_outlined,
      'Envíos a todo el Perú',
      'Recibe tu pedido donde estés',
    ),
    (
      Icons.verified_user_outlined,
      'Compra 100% segura',
      'Pagos simulados en esta demo',
    ),
    (
      Icons.sync_alt,
      'Cambios y devoluciones',
      'Cambia tu talla sin complicaciones',
    ),
    (
      Icons.storefront_outlined,
      'Retiro en tienda',
      'Recoge gratis en tu tienda favorita',
    ),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        return Column(
          children: [
            for (var start = 0; start < _items.length; start += columns) ...[
              if (start > 0) const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (
                      var index = start;
                      index < start + columns;
                      index++
                    ) ...[
                      if (index > start) const SizedBox(width: 12),
                      Expanded(child: _card(context, _items[index])),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    ),
  );

  Widget _card(BuildContext context, (IconData, String, String) item) =>
      MergeSemantics(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.softGreen,
                child: Icon(item.$1, color: AppColors.green, size: 21),
              ),
              const SizedBox(height: 10),
              Text(
                item.$2,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(item.$3, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();
  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    return Material(
      color: Colors.white,
      shape: const Border(top: BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: const Text(
                'Atención al cliente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            for (final (icon, label, screen) in [
              (Icons.support_agent, 'Centro de ayuda', const SupportScreen()),
              (
                Icons.place_outlined,
                'Tiendas y horarios',
                const StoresScreen(),
              ),
              (Icons.menu_book_outlined, 'Guías y blog', const BlogScreen()),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon, color: AppColors.darkGreen),
                title: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.muted,
                ),
                onTap: () => open(screen),
              ),
            const Divider(height: 24),
            const Text(
              'Síguenos como Platanitos Perú',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.facebook, color: AppColors.muted),
                  SizedBox(width: 18),
                  Icon(Icons.camera_alt_outlined, color: AppColors.muted),
                  SizedBox(width: 18),
                  Icon(Icons.music_note_outlined, color: AppColors.muted),
                  SizedBox(width: 18),
                  Icon(Icons.smart_display_outlined, color: AppColors.muted),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Center(child: BrandLogo(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              '© Platanitos · Demo académica sin fines comerciales',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
