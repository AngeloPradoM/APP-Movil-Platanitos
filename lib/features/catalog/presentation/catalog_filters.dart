import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../shared/models/shop_models.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/shop_widgets.dart';

String productsLabel(int count) =>
    count == 1 ? '1 producto' : '$count productos';

enum FilterSection {
  sort('Ordenar por'),
  price('Precio'),
  offers('Ofertas'),
  size('Talla'),
  brand('Marca'),
  color('Color');

  const FilterSection(this.title);
  final String title;
}

const _swatches = <String, Color>{
  'negro': Color(0xFF1E1E1E),
  'blanco': Colors.white,
  'azul': Color(0xFF2F6FD6),
  'azul marino': Color(0xFF1F2A5A),
  'celeste': Color(0xFF8ECDF0),
  'turquesa': Color(0xFF30C5C0),
  'gris': Color(0xFF9AA0A6),
  'plomo': Color(0xFF6E7378),
  'plata': Color(0xFFC0C4C8),
  'verde': Color(0xFF2E8B57),
  'beige': Color(0xFFE8D9BC),
  'crema': Color(0xFFF6EBD0),
  'nude': Color(0xFFE3BC9A),
  'camel': Color(0xFFC19A6B),
  'marron': Color(0xFF7B4B2A),
  'wengue': Color(0xFF4B3426),
  'carey': Color(0xFF8B5A2B),
  'rosado': Color(0xFFF4A7B9),
  'fucsia': Color(0xFFE91E8C),
  'coral': Color(0xFFFF7F50),
  'rojo': Color(0xFFD32F2F),
  'vino': Color(0xFF7B1E3A),
  'naranja': Color(0xFFF57C00),
  'amarillo': AppColors.yellow,
  'dorado': Color(0xFFD4AF37),
  'oro rosa': Color(0xFFE0A899),
  'lila': Color(0xFFC8A2C8),
  'morado': Color(0xFF7E57C2),
};

/// Muestra del color; los multicolores llevan un degradado y los que no
/// tienen color (transparente, sin color) solo el borde.
class ColorDot extends StatelessWidget {
  const ColorDot(this.color, {super.key, this.size = 18});
  final String color;
  final double size;
  @override
  Widget build(BuildContext context) {
    final name = normalizeText(color);
    final fill = _swatches[name];
    final mixed = const ['multicolor', 'varios', 'floral', 'estampado'];
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          gradient: fill == null && mixed.contains(name)
              ? const SweepGradient(
                  colors: [
                    Color(0xFFE53935),
                    Color(0xFFFDD835),
                    Color(0xFF43A047),
                    Color(0xFF1E88E5),
                    Color(0xFF8E24AA),
                    Color(0xFFE53935),
                  ],
                )
              : null,
          border: Border.all(color: const Color(0xFFCFD4D9)),
        ),
      ),
    );
  }
}

/// Barra de filtros: "Filtrar" abre el panel completo y cada pastilla abre
/// solo su sección. Las opciones salen de los productos de [source].
class CatalogFilterBar extends StatelessWidget {
  const CatalogFilterBar({
    super.key,
    required this.filter,
    required this.facets,
    required this.onOpen,
    required this.onChanged,
  });
  final CatalogFilter filter;
  final CatalogFacets facets;
  final ValueChanged<FilterSection?> onOpen;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    String counted(String label, int count) =>
        count == 0 ? label : '$label ($count)';
    final price = filter.price;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          for (final pill in [
            FilterPill(
              label: counted('Filtrar', filter.selectionCount),
              icon: Icons.tune,
              selected: filter.selectionCount > 0,
              minHeight: 44,
              onTap: () => onOpen(null),
            ),
            FilterPill(
              label: filter.sort == ProductSort.recommended
                  ? 'Ordenar'
                  : filter.sort.label,
              icon: Icons.swap_vert,
              selected: filter.sort != ProductSort.recommended,
              minHeight: 44,
              onTap: () => onOpen(FilterSection.sort),
            ),
            if (facets.sizes.isNotEmpty)
              FilterPill(
                label: counted('Talla', filter.sizes.length),
                selected: filter.sizes.isNotEmpty,
                minHeight: 44,
                onTap: () => onOpen(FilterSection.size),
              ),
            if (facets.brands.length > 1 || filter.brands.isNotEmpty)
              FilterPill(
                label: counted('Marca', filter.brands.length),
                selected: filter.brands.isNotEmpty,
                minHeight: 44,
                onTap: () => onOpen(FilterSection.brand),
              ),
            if (facets.colors.length > 1 || filter.colors.isNotEmpty)
              FilterPill(
                label: counted('Color', filter.colors.length),
                selected: filter.colors.isNotEmpty,
                minHeight: 44,
                onTap: () => onOpen(FilterSection.color),
              ),
            FilterPill(
              label: price?.label ?? 'Precio',
              selected: price != null,
              minHeight: 44,
              onTap: () => onOpen(FilterSection.price),
            ),
            if (facets.offers > 0 || filter.onSaleOnly)
              FilterPill(
                label: 'Solo ofertas',
                icon: Icons.local_offer_outlined,
                selected: filter.onSaleOnly,
                minHeight: 44,
                onTap: () {
                  filter.onSaleOnly = !filter.onSaleOnly;
                  onChanged();
                },
              ),
          ])
            Padding(padding: const EdgeInsets.only(right: 8), child: pill),
        ],
      ),
    );
  }
}

/// Filtros aplicados como chips que se quitan con un toque.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    super.key,
    required this.filter,
    required this.onChanged,
  });
  final CatalogFilter filter;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <(String, Widget?, VoidCallback)>[
      if (filter.collection case final collection?)
        (collection.label, null, () => filter.collection = null),
      for (final brand in filter.brands)
        (brand, null, () => filter.brands.remove(brand)),
      for (final size in filter.sizes)
        (
          sizeDescription(size.value, size.system),
          null,
          () => filter.sizes.remove(size),
        ),
      for (final color in filter.colors)
        (color, ColorDot(color, size: 14), () => filter.colors.remove(color)),
      if (filter.price case final price?)
        (price.label, null, () => filter.price = null),
      if (filter.onSaleOnly)
        ('Solo ofertas', null, () => filter.onSaleOnly = false),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          for (final (label, avatar, remove) in chips)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InputChip(
                label: Text(label),
                avatar: avatar,
                labelStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGreen,
                ),
                backgroundColor: AppColors.softGreen,
                side: const BorderSide(color: AppColors.softGreen),
                shape: const StadiumBorder(),
                deleteIcon: const Icon(Icons.close, size: 16),
                deleteIconColor: AppColors.darkGreen,
                deleteButtonTooltipMessage: 'Quitar filtro $label',
                onPressed: () {
                  remove();
                  onChanged();
                },
                onDeleted: () {
                  remove();
                  onChanged();
                },
              ),
            ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.darkGreen,
              minimumSize: const Size(44, 44),
            ),
            onPressed: () {
              filter
                ..clearSelections()
                ..collection = null;
              onChanged();
            },
            child: const Text('Limpiar todo'),
          ),
        ],
      ),
    );
  }
}

/// Panel de filtros sobre una copia del filtro: solo se aplica al tocar
/// "Ver N productos". Con [section] muestra solo esa sección.
Future<void> showFilterPanel(
  BuildContext context, {
  required CatalogFilter filter,
  required List<Product> Function(ShopState state) source,
  required VoidCallback onApply,
  FilterSection? section,
  bool Function(ShopState state)? loading,
}) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: Colors.white,
  builder: (context) => FilterPanel(
    filter: filter,
    source: source,
    section: section,
    loading: loading,
    onApply: onApply,
  ),
);

class FilterPanel extends StatefulWidget {
  const FilterPanel({
    super.key,
    required this.filter,
    required this.source,
    required this.onApply,
    this.section,
    this.loading,
  });
  final CatalogFilter filter;
  final List<Product> Function(ShopState state) source;
  final VoidCallback onApply;
  final FilterSection? section;
  final bool Function(ShopState state)? loading;
  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late final draft = widget.filter.copy();
  bool allBrands = false;

  List<FilterSection> get sections => widget.section == null
      ? FilterSection.values
      : [widget.section!];

  void _clear() {
    for (final section in sections) {
      switch (section) {
        case FilterSection.sort:
          draft.sort = ProductSort.recommended;
        case FilterSection.price:
          draft.price = null;
        case FilterSection.offers:
          draft.onSaleOnly = false;
        case FilterSection.size:
          draft.sizes.clear();
        case FilterSection.brand:
          draft.brands.clear();
        case FilterSection.color:
          draft.colors.clear();
      }
    }
    setState(() {});
  }

  void _apply() {
    widget.filter.copyFrom(draft);
    Navigator.pop(context);
    widget.onApply();
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    final products = widget.source(state);
    final facets = draft.facets(products);
    final count = draft.apply(products).length;
    final loading = widget.loading?.call(state) ?? false;
    final children = [
      for (final section in sections)
        ..._section(section, facets, single: widget.section != null),
    ];
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .92,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.section?.title ?? 'Filtrar',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          Flexible(
            child: children.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No hay opciones para este filtro.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    children: children,
                  ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      style: secondaryButtonStyle,
                      onPressed: _clear,
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      style: primaryButtonStyle,
                      onPressed: _apply,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Ver ${productsLabel(count)}'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
  );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool enabled = true,
    Widget? avatar,
  }) => FilterChip(
    label: Text(label),
    avatar: avatar,
    selected: selected,
    onSelected: enabled || selected ? (_) => setState(onTap) : null,
    showCheckmark: avatar == null,
    selectedColor: AppColors.softGreen,
    checkmarkColor: AppColors.darkGreen,
    backgroundColor: Colors.white,
    side: BorderSide(
      color: selected ? AppColors.darkGreen : const Color(0xFFE2E5EA),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    labelStyle: TextStyle(
      fontSize: 13,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      color: selected ? AppColors.darkGreen : AppColors.ink,
    ),
  );

  Widget _wrap(List<Widget> children) =>
      Wrap(spacing: 8, runSpacing: 4, children: children);

  List<Widget> _section(
    FilterSection section,
    CatalogFacets facets, {
    required bool single,
  }) {
    final title = single ? const <Widget>[] : [_title(section.title)];
    switch (section) {
      case FilterSection.sort:
        return [
          ...title,
          _wrap([
            for (final sort in catalogSorts)
              _chip(
                label: sort.label,
                selected: draft.sort == sort,
                onTap: () => draft.sort = sort,
              ),
          ]),
        ];
      case FilterSection.price:
        return [
          ...title,
          _wrap([
            for (final (:value, :count) in facets.prices)
              _chip(
                label: '${value.label} ($count)',
                selected: draft.price == value,
                enabled: count > 0,
                onTap: () => draft.price = draft.price == value ? null : value,
              ),
          ]),
        ];
      case FilterSection.offers:
        if (facets.offers == 0 && !draft.onSaleOnly) return const [];
        return [
          ...title,
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Solo ofertas'),
            subtitle: Text('${productsLabel(facets.offers)} con descuento'),
            value: draft.onSaleOnly,
            activeThumbColor: AppColors.darkGreen,
            onChanged: (value) => setState(() => draft.onSaleOnly = value),
          ),
        ];
      case FilterSection.size:
        if (facets.sizes.isEmpty) return const [];
        final groups = <String, List<FacetCount<SizeOption>>>{};
        for (final option in facets.sizes) {
          (groups[sizeGroupLabel(option.value)] ??= []).add(option);
        }
        return [
          ...title,
          for (final MapEntry(key: group, value: options) in groups.entries) ...[
            if (groups.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  group,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            _wrap([
              for (final (:value, :count) in options)
                Semantics(
                  label: '${sizeDescription(value.value, value.system)}, '
                      '${productsLabel(count)}',
                  child: _chip(
                    label: value.value,
                    selected: draft.sizes.contains(value),
                    enabled: count > 0,
                    onTap: () => draft.sizes.contains(value)
                        ? draft.sizes.remove(value)
                        : draft.sizes.add(value),
                  ),
                ),
            ]),
          ],
        ];
      case FilterSection.brand:
        if (facets.brands.isEmpty) return const [];
        final limit = single || allBrands ? facets.brands.length : 8;
        return [
          ...title,
          for (final (:value, :count) in facets.brands.take(limit))
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.darkGreen,
              value: draft.brands.contains(value),
              onChanged: count > 0 || draft.brands.contains(value)
                  ? (checked) => setState(
                      () => checked == true
                          ? draft.brands.add(value)
                          : draft.brands.remove(value),
                    )
                  : null,
              title: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
              secondary: Text(
                '$count',
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
            ),
          if (facets.brands.length > limit)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkGreen,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: () => setState(() => allBrands = true),
                child: Text('Ver las ${facets.brands.length} marcas'),
              ),
            ),
        ];
      case FilterSection.color:
        if (facets.colors.isEmpty) return const [];
        return [
          ...title,
          _wrap([
            for (final (:value, :count) in facets.colors)
              _chip(
                label: '$value ($count)',
                avatar: ColorDot(value),
                selected: draft.colors.contains(value),
                enabled: count > 0,
                onTap: () => draft.colors.contains(value)
                    ? draft.colors.remove(value)
                    : draft.colors.add(value),
              ),
          ]),
        ];
    }
  }
}

class CatalogSkeleton extends StatelessWidget {
  const CatalogSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando productos',
    child: Column(
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
    ),
  );
}

/// Aviso de datos de respaldo cuando el backend no responde.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.onRetry, this.message});
  final VoidCallback onRetry;
  final String? message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message ??
                'El sistema está fallando en este momento. Mostramos datos de respaldo.',
            style: const TextStyle(fontSize: 12.5),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
          onPressed: onRetry,
          child: const Text('Reintentar'),
        ),
      ],
    ),
  );
}
