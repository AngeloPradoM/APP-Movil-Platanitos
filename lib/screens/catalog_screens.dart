import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/mock_data.dart';
import '../models/shop_models.dart';
import '../state/shop_state.dart';
import '../widgets/shop_widgets.dart';
import 'product_screen.dart';

void openProduct(BuildContext context, Product product) => Navigator.push(
  context,
  MaterialPageRoute<void>(builder: (_) => ProductScreen(product: product)),
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onCatalog});
  final VoidCallback onCatalog;
  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        SearchField(
          value: state.catalog.query,
          onChanged: (value) {
            state.catalog.query = value;
            state.updateCatalog();
          },
          onSubmit: onCatalog,
        ),
        const SizedBox(height: 20),
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: InkWell(
                onTap: () {
                  state.catalog.clear();
                  state.updateCatalog();
                  onCatalog();
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 29,
                      backgroundColor: index == 2
                          ? AppColors.yellow.withValues(alpha: .25)
                          : AppColors.softGreen,
                      child: Icon(
                        [
                          Icons.grid_view,
                          Icons.shopping_bag_outlined,
                          Icons.favorite_border,
                          Icons.watch_outlined,
                        ][index],
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ['Calzado', 'Carteras', 'Ofertas', 'Accesorios'][index],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 270 + (MediaQuery.textScalerOf(context).scale(1) - 1) * 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ShopImage(bannerImage),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SOLO POR TIEMPO LIMITADO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Cyber Days\n50% Off',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Exclusivo en Calzado y Carteras',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.darkGreen,
                        ),
                        onPressed: onCatalog,
                        child: const Text('Comprar ahora  ›'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recomendados para ti',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(onPressed: onCatalog, child: const Text('Ver todo')),
          ],
        ),
        const SizedBox(height: 12),
        ProductGrid(
          products: state.catalogProducts,
          onOpen: (product) => openProduct(context, product),
        ),
        const SizedBox(height: 28),
        const Divider(),
        const Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            ListBenefit(
              icon: Icons.local_shipping_outlined,
              title: 'Envíos a todo el Perú',
              subtitle: 'Recibe donde estés',
            ),
            ListBenefit(
              icon: Icons.credit_card,
              title: 'Compra 100% segura',
              subtitle: 'Pagos simulados en esta demo',
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class ListBenefit extends StatelessWidget {
  const ListBenefit({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppColors.green),
      const SizedBox(width: 10),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ShopScope.of(context).loadRemoteCatalog();
    });
  }
  Future<void> apply() async {
    setState(() => loading = true);
    ShopScope.of(context).updateCatalog();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() => loading = false);
  }

  Future<void> filters() async {
    final filter = ShopScope.of(context).catalog;
    String? brand = filter.brand, color = filter.color;
    int? size = filter.sizeIndex;
    double price = filter.maxPrice;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Filtrar productos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: brand ?? '',
                decoration: const InputDecoration(labelText: 'Marca'),
                items: ['', ...ShopScope.of(context).catalogProducts.map((p) => p.brand).toSet()]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.isEmpty ? 'Todas' : value),
                      ),
                    )
                    .toList(),
                onChanged: (value) => brand = value == '' ? null : value,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: color ?? '',
                decoration: const InputDecoration(labelText: 'Color'),
                items: ['', ...ShopScope.of(context).catalogProducts.map((p) => p.color).toSet()]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.isEmpty ? 'Todos' : value),
                      ),
                    )
                    .toList(),
                onChanged: (value) => color = value == '' ? null : value,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: size ?? -1,
                decoration: const InputDecoration(labelText: 'Talla EUR'),
                items: [
                  const DropdownMenuItem(value: -1, child: Text('Todas')),
                  ...List.generate(
                    6,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(sizeLabels[SizeSystem.eur]![index]),
                    ),
                  ),
                ],
                onChanged: (value) => size = value == -1 ? null : value,
              ),
              const SizedBox(height: 18),
              Text('Precio máximo: ${money(price)}'),
              Slider(
                min: 50,
                max: 250,
                divisions: 40,
                value: price,
                onChanged: (value) => update(() => price = value),
              ),
              FilledButton(
                onPressed: () {
                  filter.brand = brand;
                  filter.color = color;
                  filter.sizeIndex = size;
                  filter.maxPrice = price;
                  Navigator.pop(context, true);
                },
                child: const Text('Aplicar filtros'),
              ),
              TextButton(
                onPressed: () {
                  filter.clear();
                  Navigator.pop(context, true);
                },
                child: const Text('Limpiar filtros'),
              ),
            ],
          ),
        ),
      ),
    );
    if (changed == true && mounted) await apply();
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context), filter = state.catalog;
    final result = filter.apply(state.catalogProducts);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        SearchField(
          value: filter.query,
          onChanged: (value) {
            filter.query = value;
            state.updateCatalog();
          },
          onSubmit: apply,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ActionChip(
              label: Text(
                filter.sizeIndex == null
                    ? 'Talla'
                    : 'Talla ${sizeLabels[SizeSystem.eur]![filter.sizeIndex!]}',
              ),
              avatar: const Icon(Icons.expand_more, size: 16),
              onPressed: filters,
            ),
            ActionChip(
              label: Text(filter.brand ?? 'Marca'),
              onPressed: filters,
            ),
            ActionChip(
              label: Text(filter.color ?? 'Color'),
              onPressed: filters,
            ),
            ActionChip(
              label: Text(
                filter.maxPrice < 250 ? money(filter.maxPrice) : 'Precio',
              ),
              onPressed: filters,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filter.query.isEmpty
                        ? 'Calzado para ti'
                        : 'Resultados para “${filter.query}”',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${result.length} productos',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            SortMenu(
              value: filter.sort,
              onChanged: (value) {
                filter.sort = value;
                state.updateCatalog();
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (state.catalogError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.orange),
                const SizedBox(width: 8),
                const Expanded(child: Text('El sistema está fallando en este momento. Mostramos datos de respaldo.')),
                TextButton(onPressed: state.loadRemoteCatalog, child: const Text('Reintentar')),
              ],
            ),
          ),
        if (state.catalogLoading || loading)
          const CatalogSkeleton()
        else if (state.catalogError != null && state.catalogProducts.isEmpty)
          EmptyState(
            icon: Icons.cloud_off,
            title: 'El sistema está presentando problemas',
            message: 'No pudimos cargar el catálogo en este momento. Intenta nuevamente.',
            action: 'Reintentar',
            onAction: state.loadRemoteCatalog,
          )
        else if (result.isEmpty)
          EmptyState(
            icon: Icons.search,
            title: 'No encontramos productos',
            message: 'Prueba con otra palabra o elimina los filtros.',
            action: 'Limpiar búsqueda y filtros',
            onAction: () {
              filter.clear();
              state.updateCatalog();
            },
          )
        else
          ProductGrid(
            products: result,
            onOpen: (product) => openProduct(context, product),
          ),
      ],
    );
  }
}

class SortMenu extends StatelessWidget {
  const SortMenu({
    super.key,
    required this.value,
    required this.onChanged,
    this.favorites = false,
  });
  final ProductSort value;
  final ValueChanged<ProductSort> onChanged;
  final bool favorites;
  @override
  Widget build(BuildContext context) => PopupMenuButton<ProductSort>(
    tooltip: 'Ordenar productos',
    initialValue: value,
    onSelected: onChanged,
    itemBuilder: (_) =>
        (favorites
                ? [
                    ProductSort.recent,
                    ProductSort.cheapest,
                    ProductSort.expensive,
                    ProductSort.offers,
                  ]
                : [
                    ProductSort.recommended,
                    ProductSort.cheapest,
                    ProductSort.expensive,
                  ])
            .map(
              (sort) => PopupMenuItem(
                value: sort,
                child: Text(switch (sort) {
                  ProductSort.recommended => 'Recomendados',
                  ProductSort.cheapest => 'Menor precio',
                  ProductSort.expensive => 'Mayor precio',
                  ProductSort.recent => 'Más recientes',
                  ProductSort.offers => 'Ofertas',
                }),
              ),
            )
            .toList(),
    child: const Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(Icons.sort, size: 20),
          SizedBox(width: 5),
          Text('Ordenar'),
        ],
      ),
    ),
  );
}

class CatalogSkeleton extends StatelessWidget {
  const CatalogSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const LinearProgressIndicator(),
      const SizedBox(height: 18),
      Row(
        children: List.generate(
          2,
          (_) => Expanded(
            child: Container(
              height: 240,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onCatalog});
  final VoidCallback onCatalog;
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  ProductSort sort = ProductSort.recent;
  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    final filter = CatalogFilter()..sort = sort;
    final result = filter.apply(
      state.catalogProducts.where((product) => state.favorites.contains(product.id)),
      favorites: state.favorites,
    );
    if (result.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border,
        title: 'Aún no tienes favoritos',
        message: 'Guarda los productos que más te gusten.',
        action: 'Explorar productos',
        onAction: widget.onCatalog,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tus favoritos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${result.length} productos guardados',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            SortMenu(
              value: sort,
              favorites: true,
              onChanged: (value) => setState(() => sort = value),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ProductGrid(
          products: result,
          favoriteActions: true,
          onOpen: (product) => openProduct(context, product),
        ),
      ],
    );
  }
}
