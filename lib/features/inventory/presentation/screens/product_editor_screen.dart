import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/remote_inventory_repository.dart';

class ProductEditorScreen extends StatefulWidget {
  const ProductEditorScreen({super.key, required this.repository, this.productId});
  final RemoteInventoryRepository repository;
  final String? productId;

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final name = TextEditingController();
  final description = TextEditingController();
  EditableProduct? product;
  List<InventoryCategory> categories = const [];
  List<CatalogBrand> brands = const [];
  var loading = true;
  var saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final loadedCategories = await widget.repository.categories();
      final loadedBrands = await widget.repository.brands();
      final loaded = widget.productId == null
          ? EditableProduct(
              categoryId: loadedCategories.isEmpty ? '' : loadedCategories.first.id,
              brandId: loadedBrands.isEmpty ? '' : loadedBrands.first.id,
            )
          : await widget.repository.product(widget.productId!);
      if (!mounted) return;
      name.text = loaded.name;
      description.text = loaded.description;
      setState(() {
        categories = loadedCategories;
        brands = loadedBrands;
        product = loaded;
        loading = false;
      });
    } catch (caught) {
      if (!mounted) return;
      setState(() {
        error = '$caught';
        loading = false;
      });
    }
  }

  Future<void> _save() async {
    final current = product;
    if (current == null || saving) return;
    current.name = name.text.trim();
    current.description = description.text.trim();
    setState(() => saving = true);
    try {
      await widget.repository.saveProduct(current);
      if (mounted) Navigator.pop(context, true);
    } catch (caught) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$caught')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = product;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Nuevo producto' : 'Editar producto'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : current == null
          ? Center(child: Text(error ?? 'No se pudo abrir el producto.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: current.categoryId.isEmpty ? null : current.categoryId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(value: category.id, child: Text(category.name)),
                  ],
                  onChanged: (value) => setState(() => current.categoryId = value ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: current.brandId.isEmpty ? null : current.brandId,
                  decoration: const InputDecoration(labelText: 'Marca'),
                  items: [
                    for (final brand in brands)
                      DropdownMenuItem(value: brand.id, child: Text(brand.name)),
                  ],
                  onChanged: (value) => setState(() => current.brandId = value ?? ''),
                ),
                const SizedBox(height: 20),
                const Text('Fotos', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  'Se guardan en el orden de esta lista: la primera es la foto principal.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                for (var index = 0; index < current.images.length; index++) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: current.images[index].url,
                          decoration: InputDecoration(labelText: 'Foto ${index + 1}'),
                          onChanged: (value) => current.images[index].url = value,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Quitar foto',
                        onPressed: current.images.length == 1
                            ? null
                            : () => setState(() => current.images.removeAt(index)),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => current.images.add(EditableImage(url: ''))),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar foto'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Variantes', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  'Al guardar quedan ordenadas por sistema de talla, talla y color.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                for (var index = 0; index < current.variants.length; index++)
                  _VariantFields(
                    key: ObjectKey(current.variants[index]),
                    variant: current.variants[index],
                    onRemove: current.variants.length == 1
                        ? null
                        : () => setState(() => current.variants.removeAt(index)),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => current.variants.add(EditableVariant())),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar variante'),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: saving ? null : _save,
                  child: Text(saving ? 'Guardando…' : 'Guardar producto'),
                ),
              ],
            ),
    );
  }
}

class _VariantFields extends StatelessWidget {
  const _VariantFields({super.key, required this.variant, required this.onRemove});
  final EditableVariant variant;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: variant.sizeSystem,
            decoration: const InputDecoration(labelText: 'Sistema de talla'),
            items: const [
              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
              DropdownMenuItem(value: 'US', child: Text('US')),
              DropdownMenuItem(value: 'CM', child: Text('CM')),
              DropdownMenuItem(value: 'ALPHA', child: Text('Alfabética')),
              DropdownMenuItem(value: 'ONE_SIZE', child: Text('Talla única')),
            ],
            onChanged: (value) => variant.sizeSystem = value ?? 'EUR',
          ),
          TextFormField(
            initialValue: variant.sizeValue,
            decoration: const InputDecoration(labelText: 'Talla'),
            onChanged: (value) => variant.sizeValue = value,
          ),
          TextFormField(
            initialValue: variant.color,
            decoration: const InputDecoration(labelText: 'Color'),
            onChanged: (value) => variant.color = value,
          ),
          TextFormField(
            initialValue: variant.price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Precio'),
            onChanged: (value) => variant.price = value,
          ),
          TextFormField(
            initialValue: variant.stock,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Stock'),
            onChanged: (value) => variant.stock = value,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onRemove, child: const Text('Quitar variante')),
          ),
        ],
      ),
    ),
  );
}
