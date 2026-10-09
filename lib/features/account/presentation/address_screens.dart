import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_theme.dart';
import '../../../core/validators.dart';
import '../../../shared/models/shop_models.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/shop_widgets.dart';

const peruDepartments = [
  'Amazonas',
  'Áncash',
  'Apurímac',
  'Arequipa',
  'Ayacucho',
  'Cajamarca',
  'Callao',
  'Cusco',
  'Huancavelica',
  'Huánuco',
  'Ica',
  'Junín',
  'La Libertad',
  'Lambayeque',
  'Lima',
  'Loreto',
  'Madre de Dios',
  'Moquegua',
  'Pasco',
  'Piura',
  'Puno',
  'San Martín',
  'Tacna',
  'Tumbes',
  'Ucayali',
];

const _labels = ['Casa', 'Trabajo', 'Otro'];

/// Abre el formulario y devuelve `true` si se guardó la dirección.
Future<bool> openAddressForm(
  BuildContext context, {
  ShippingAddress? initial,
}) async =>
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddressFormScreen(initial: initial)),
    ) ==
    true;

String? _required(String? value, {int min = 2, required String message}) =>
    (value?.trim().length ?? 0) >= min ? null : message;

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, this.initial});
  final ShippingAddress? initial;
  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final form = GlobalKey<FormState>();
  late final ShippingAddress? initial = widget.initial;
  late final recipient = TextEditingController(text: initial?.recipient);
  late final phone = TextEditingController(text: initial?.phone);
  late final line1 = TextEditingController(text: initial?.line1);
  late final district = TextEditingController(text: initial?.district);
  late final province = TextEditingController(
    text: initial?.province ?? 'Lima',
  );
  late final reference = TextEditingController(text: initial?.reference);
  late String label = initial?.label ?? _labels.first;
  late String department = peruDepartments.contains(initial?.department)
      ? initial!.department
      : 'Lima';
  late bool isDefault = initial?.isDefault ?? false;
  bool saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initial != null || recipient.text.isNotEmpty) return;
    final user = ShopScope.of(context).user;
    recipient.text = user.name;
    phone.text = user.phone;
  }

  @override
  void dispose() {
    for (final controller in [
      recipient,
      phone,
      line1,
      district,
      province,
      reference,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await ShopScope.of(context).saveAddress(
        ShippingAddress(
          id: initial?.id,
          label: label,
          recipient: recipient.text.trim(),
          phone: phone.text.trim(),
          line1: line1.text.trim(),
          district: district.text.trim(),
          province: province.text.trim(),
          department: department,
          reference: reference.text.trim(),
          isDefault: isDefault,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on StateError catch (error) {
      if (mounted) feedback(context, error.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: initial == null ? 'Nueva dirección' : 'Editar dirección',
    bottom: FilledButton(
      style: primaryButtonStyle,
      onPressed: saving ? null : save,
      child: Text(saving ? 'Guardando…' : 'Guardar dirección'),
    ),
    child: ColoredBox(
      color: softBackground,
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const Text(
              '¿A dónde enviamos tu pedido?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Escribe tu dirección completa para que el courier llegue sin problemas.',
              style: TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 20),
            fieldLabel('Tipo de dirección'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _labels)
                  FilterPill(
                    label: option,
                    selected: label == option,
                    onTap: () => setState(() => label = option),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            fieldLabel('Nombre de quien recibe'),
            TextFormField(
              controller: recipient,
              textCapitalization: TextCapitalization.words,
              decoration: fieldDecoration('Nombres y Apellidos'),
              validator: Validators.name,
            ),
            const SizedBox(height: 16),
            fieldLabel('Teléfono de contacto'),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: fieldDecoration('987 654 321'),
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            fieldLabel('Dirección'),
            TextFormField(
              controller: line1,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 180,
              decoration: fieldDecoration(
                'Av. / Calle / Jr., número, dpto o interior',
              ).copyWith(counterText: ''),
              validator: (value) => _required(
                value,
                min: 5,
                message: 'Escribe la calle y el número.',
              ),
            ),
            const SizedBox(height: 16),
            fieldLabel('Departamento'),
            DropdownButtonFormField<String>(
              initialValue: department,
              isExpanded: true,
              decoration: fieldDecoration(''),
              items: [
                for (final value in peruDepartments)
                  DropdownMenuItem(value: value, child: Text(value)),
              ],
              onChanged: (value) =>
                  setState(() => department = value ?? department),
            ),
            const SizedBox(height: 16),
            fieldLabel('Provincia'),
            TextFormField(
              controller: province,
              textCapitalization: TextCapitalization.words,
              decoration: fieldDecoration('Ej. Lima'),
              validator: (value) =>
                  _required(value, message: 'Escribe la provincia.'),
            ),
            const SizedBox(height: 16),
            fieldLabel('Distrito'),
            TextFormField(
              controller: district,
              textCapitalization: TextCapitalization.words,
              decoration: fieldDecoration('Ej. Miraflores'),
              validator: (value) =>
                  _required(value, message: 'Escribe el distrito.'),
            ),
            const SizedBox(height: 16),
            fieldLabel('Referencia (opcional)'),
            TextFormField(
              controller: reference,
              maxLength: 180,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration('Ej. Frente al parque, puerta verde')
                  .copyWith(counterText: ''),
            ),
            if (initial?.isDefault != true) ...[
              const SizedBox(height: 8),
              MergeSemantics(
                child: CheckboxListTile(
                  value: isDefault,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.darkGreen,
                  title: const Text(
                    'Usar como dirección principal',
                    style: TextStyle(fontSize: 13.5),
                  ),
                  onChanged: (value) =>
                      setState(() => isDefault = value ?? false),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    final addresses = state.addresses;
    return PageFrame(
      title: 'Mis direcciones',
      bottom: FilledButton.icon(
        style: primaryButtonStyle,
        onPressed: () => openAddressForm(context),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Agregar dirección'),
      ),
      child: ColoredBox(
        color: softBackground,
        child: addresses.isEmpty
            ? const EmptyState(
                icon: Icons.location_on_outlined,
                title: 'Aún no tienes direcciones',
                message:
                    'Agrega la dirección donde quieres recibir tus pedidos.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: addresses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  return AddressCard(
                    address: address,
                    onEdit: () => openAddressForm(context, initial: address),
                    onRemove: () => _confirmRemove(context, address),
                    onMakeDefault: address.isDefault
                        ? null
                        : () => _run(
                            context,
                            state.saveAddress(
                              address.copyWith(isDefault: true),
                            ),
                          ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    ShippingAddress address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar dirección?'),
        content: Text('${address.label}: ${address.line1}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _run(context, ShopScope.of(context).removeAddress(address));
    }
  }

  Future<void> _run(BuildContext context, Future<void> action) async {
    try {
      await action;
    } on StateError catch (error) {
      if (context.mounted) feedback(context, error.message);
    }
  }
}

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    this.selected,
    this.onTap,
    this.onEdit,
    this.onRemove,
    this.onMakeDefault,
  });
  final ShippingAddress address;

  /// Si no es `null`, la tarjeta se comporta como opción seleccionable.
  final bool? selected;
  final VoidCallback? onTap, onEdit, onRemove, onMakeDefault;

  @override
  Widget build(BuildContext context) {
    final active = selected ?? false;
    return Semantics(
      selected: selected,
      child: Material(
        color: active ? AppColors.softGreen : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: active ? AppColors.darkGreen : fieldBorderColor,
            width: active ? 1.4 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : AppColors.softGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    switch (address.label) {
                      'Casa' => Icons.home_outlined,
                      'Trabajo' => Icons.work_outline,
                      _ => Icons.location_on_outlined,
                    },
                    color: AppColors.darkGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            address.label,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (address.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : AppColors.softGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Principal',
                                style: TextStyle(
                                  color: AppColors.darkGreen,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.line1,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        address.region,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (address.reference.isNotEmpty)
                        Text(
                          'Ref.: ${address.reference}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        '${address.recipient}${address.phone.isEmpty ? '' : ' · ${address.phone}'}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (onMakeDefault != null)
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.darkGreen,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: onMakeDefault,
                          child: const Text('Usar como principal'),
                        ),
                    ],
                  ),
                ),
                if (selected != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    child: Icon(
                      active
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: active ? AppColors.darkGreen : fieldBorderColor,
                    ),
                  ),
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Editar dirección',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                if (onRemove != null)
                  IconButton(
                    tooltip: 'Eliminar dirección',
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.danger,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
