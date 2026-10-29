import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../operations/presentation/widgets/operations_panel.dart';
import '../../data/remote_inventory_repository.dart';
import '../../domain/inventory_models.dart';
import 'product_editor_screen.dart';
import '../controllers/inventory_controller.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  InventoryController? controller;
  final searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (controller != null) return;
    final repository = ShopScope.of(context).inventoryRepository;
    if (repository != null) {
      controller = InventoryController(repository)..load();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    controller?.dispose();
    super.dispose();
  }

  Future<void> openMovement(InventoryItem item) async {
    var type = StockMovementType.entry;
    final quantity = TextEditingController();
    final reason = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            '${item.productName} · ${item.sizeValue} ${item.sizeSystem}',
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<StockMovementType>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de movimiento',
                  ),
                  items: [
                    for (final value in StockMovementType.values)
                      DropdownMenuItem(value: value, child: Text(value.label)),
                  ],
                  onChanged: (value) => setDialogState(() => type = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: type == StockMovementType.adjustment
                        ? 'Nuevo stock físico'
                        : 'Cantidad',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reason,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Motivo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true || !mounted) return;
    final value = int.tryParse(quantity.text);
    final invalidQuantity =
        value == null ||
        value < 0 ||
        (value == 0 && type != StockMovementType.adjustment);
    if (invalidQuantity || reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una cantidad válida y el motivo.'),
        ),
      );
      return;
    }
    try {
      final state = ShopScope.of(context);
      await controller!.registerMovement(
        item: item,
        type: type,
        quantity: value,
        reason: reason.text,
        responsibleUserId: state.user.id ?? 'demo-almacen',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movimiento guardado en el inventario.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message
                : 'No se pudo guardar el movimiento.',
          ),
        ),
      );
    }
  }

  Future<void> editPrice(InventoryItem item) async {
    final field = TextEditingController(
      text: item.price == 0 ? '' : item.price.toStringAsFixed(2),
    );
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Precio · ${item.productName}'),
        content: TextField(
          controller: field,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Precio en soles'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    final price = double.tryParse(field.text.replaceAll(',', '.'));
    if (submitted != true || !mounted || price == null || price < 0) return;
    try {
      await controller!.updatePrice(item, price);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Precio actualizado.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el precio.')),
      );
    }
  }

  Future<void> openEditor([String? productId]) async {
    final repository = ShopScope.of(context).inventoryRepository;
    if (repository is! RemoteInventoryRepository) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ProductEditorScreen(
          repository: repository,
          productId: productId,
        ),
      ),
    );
    if (saved == true) await controller?.load(query: searchController.text);
  }

  Future<void> showHistory(InventoryItem item) async {
    final movements = await controller!.movements(item);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              'Movimientos · ${item.productName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (movements.isEmpty)
              const Text('Todavía no hay movimientos para esta variante.'),
            for (final movement in movements)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  movement.type == StockMovementType.entry
                      ? Icons.add_circle_outline
                      : Icons.remove_circle_outline,
                ),
                title: Text('${movement.type.label}: ${movement.quantity}'),
                subtitle: Text(movement.reason),
                trailing: Text(
                  '${movement.createdAt.day}/${movement.createdAt.month}',
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = controller;
    if (current == null) {
      return const Center(
        child: Text('El inventario no está disponible para esta sesión.'),
      );
    }
    return AnimatedBuilder(
      animation: current,
      builder: (context, _) => RefreshIndicator(
        onRefresh: current.load,
        child: ListView(
          padding: operationsListPadding(context),
          children: [
            const OperationsPanelHeader(
              title: 'Inventario',
              subtitle:
                  'Stock físico, reservado y disponible de cada variante.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OperationsMetricCard(
                  label: 'Variantes',
                  value: '${current.items.length}',
                  icon: Icons.style_outlined,
                ),
                OperationsMetricCard(
                  label: 'Unidades disponibles',
                  value: '${current.availableUnits}',
                  icon: Icons.inventory_2_outlined,
                ),
                OperationsMetricCard(
                  label: 'Stock bajo',
                  value: '${current.lowStockCount}',
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => current.load(query: value),
              decoration: InputDecoration(
                labelText: 'Buscar producto, color o talla',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: () => current.load(query: searchController.text),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            if (ShopScope.of(context).inventoryRepository
                is RemoteInventoryRepository)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => openEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar producto'),
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar solo stock bajo'),
              value: current.lowStockOnly,
              onChanged: (value) => current.load(lowStockOnly: value),
            ),
            if (current.loading) const LinearProgressIndicator(),
            if (current.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  current.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            for (final item in current.items)
              OperationsTile(
                onTap: () => openMovement(item),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OperationsAvatar(
                      icon: Icons.inventory_2_outlined,
                      warning: item.lowStock,
                      label: '${item.availableStock}',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (item.category.isNotEmpty) item.category,
                              item.color,
                              'Talla ${item.sizeValue} ${item.sizeSystem}',
                              if (item.price > 0)
                                'S/ ${item.price.toStringAsFixed(2)}',
                            ].join(' · '),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Físico: ${item.physicalStock} · Reservado: ${item.reservedStock}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (ShopScope.of(context).inventoryRepository
                        is RemoteInventoryRepository)
                      IconButton(
                        tooltip: 'Editar producto',
                        onPressed: () => openEditor(item.productId),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.muted,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Cambiar precio',
                      onPressed: () => editPrice(item),
                      icon: const Icon(
                        Icons.sell_outlined,
                        color: AppColors.muted,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ver movimientos',
                      onPressed: () => showHistory(item),
                      icon: const Icon(Icons.history, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            if (!current.loading &&
                current.items.isEmpty &&
                current.error == null)
              const OperationsEmptyTile(
                message: 'No se encontraron variantes.',
              ),
          ],
        ),
      ),
    );
  }
}

