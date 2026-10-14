enum MembershipLevel {
  classic('Clásica', 0, [
    'Envío estándar a todo el Perú',
    'Ofertas por correo',
  ]),
  silver('Plata', 300, [
    'Envío gratis desde S/ 149',
    'Acceso anticipado a campañas',
    'Doble puntos en tu cumpleaños',
  ]),
  gold('Oro', 1000, [
    'Envío gratis en todas tus compras',
    'Cambios sin costo por 60 días',
    'Atención preferente en tienda',
  ]);

  const MembershipLevel(this.label, this.minPoints, this.benefits);
  final String label;
  final int minPoints;
  final List<String> benefits;

  static MembershipLevel forPoints(int points) =>
      values.lastWhere((level) => points >= level.minPoints);

  MembershipLevel? get next =>
      index + 1 < values.length ? values[index + 1] : null;
}

class WalletMovement {
  const WalletMovement({
    required this.description,
    required this.amount,
    required this.date,
  });
  final String description;
  final double amount;
  final DateTime date;
}
