import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../inventory/domain/inventory_models.dart';
import '../../../operations/domain/operations_models.dart';
import '../../../operations/presentation/widgets/operations_error_view.dart';

class StoreOperationsScreen extends StatefulWidget {
  const StoreOperationsScreen({super.key});

  @override
  State<StoreOperationsScreen> createState() => _StoreOperationsScreenState();
}

class _StoreOperationsScreenState extends State<StoreOperationsScreen> {
  Future<(List<StoreReservation>, List<InventoryItem>)>? data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    data ??= _load();
  }

  Future<(List<StoreReservation>, List<InventoryItem>)> _load() async {
    final state = ShopScope.of(context);
    return (
      await state.operationsRepository?.reservations() ?? const [],
      await state.inventoryRepository?.list() ?? const [],
    );
  }

  Future<void> _create(List<InventoryItem> inventory) async {
    if (inventory.isEmpty) return;
    var variant = inventory.first.variantId;
    final customer = TextEditingController();
    final quantity = TextEditingController(text: '1');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva reserva'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: variant,
                  isExpanded: true,
                  items: [
                    for (final item in inventory.where(
                      (item) => item.availableStock > 0,
                    ))
                      DropdownMenuItem(
                        value: item.variantId,
                        child: Text(
                          '${item.productName} · ${item.sizeValue} (${item.availableStock})',
                        ),
                      ),
                  ],
                  onChanged: (value) => setDialogState(() => variant = value!),
                  decoration: const InputDecoration(
                    labelText: 'Producto y talla',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: customer,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
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
              child: const Text('Reservar'),
            ),
          ],
        ),
      ),
    );
    final units = int.tryParse(quantity.text);
    if (accepted == true &&
        customer.text.trim().isNotEmpty &&
        units != null &&
        units > 0 &&
        mounted) {
      try {
        final state = ShopScope.of(context);
        await state.operationsRepository!.createReservation(
          variantId: variant,
          customerName: customer.text,
          quantity: units,
          workerId: state.user.id ?? 'demo-tienda',
        );
        if (mounted) {
          setState(() {
            data = _load();
          });
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$error')));
        }
      }
    }
    customer.dispose();
    quantity.dispose();
  }

  Future<void> _update(StoreReservation item, String status) async {
    try {
      await ShopScope.of(context).operationsRepository!
          .updateReservation(item.id, status);
      if (mounted) {
        setState(() {
          data = _load();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar la reserva.')),
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<(List<StoreReservation>, List<InventoryItem>)>(
    future: data,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return OperationsErrorView(
          onRetry: () => setState(() {
            data = _load();
          }),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final reservations = snapshot.data!.$1;
      final inventory = snapshot.data!.$2;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Reservas en tienda',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              FilledButton.icon(
                onPressed: () => _create(inventory),
                icon: const Icon(Icons.add),
                label: const Text('Reservar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (reservations.isEmpty)
            const Card(
              child: ListTile(title: Text('No hay reservas registradas.')),
            ),
          for (final item in reservations)
            Card(
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(item.productName),
                subtitle: Text(
                  '${item.customerName} · ${item.quantity} unidad(es)\nEstado: ${item.status}',
                ),
                isThreeLine: true,
                trailing: item.status != 'ACTIVE'
                    ? const Icon(Icons.check_circle_outline)
                    : Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Entregado',
                            onPressed: () => _update(item, 'COLLECTED'),
                            icon: const Icon(Icons.check),
                          ),
                          IconButton(
                            tooltip: 'Cancelar',
                            onPressed: () => _update(item, 'CANCELLED'),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      );
    },
  );
}
