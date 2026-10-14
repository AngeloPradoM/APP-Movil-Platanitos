enum UserRole {
  cliente('CLIENTE', 'Cliente'),
  almacen('ALMACEN', 'Almacén'),
  repartidor('REPARTIDOR', 'Repartidor'),
  atencionCliente('ATENCION_CLIENTE', 'Atención al cliente'),
  administrador('ADMINISTRADOR', 'Administrador'),
  trabajadorTienda('TRABAJADOR_TIENDA', 'Trabajador de tienda');

  const UserRole(this.value, this.label);
  final String value;
  final String label;

  // Compatibilidad con los nombres utilizados por la API anterior.
  static const administrativo = administrador;
  static const postulante = cliente;

  static UserRole fromJson(dynamic value) => switch ('$value'.toUpperCase()) {
    'ADMINISTRATIVO' || 'ADMINISTRADOR' => administrador,
    'ALMACEN' => almacen,
    'REPARTIDOR' => repartidor,
    'ATENCION_CLIENTE' => atencionCliente,
    'TRABAJADOR_TIENDA' => trabajadorTienda,
    'POSTULANTE' || 'CLIENTE' => cliente,
    _ => cliente,
  };
}

class AppUser {
  const AppUser({
    required this.name,
    required this.document,
    required this.email,
    required this.phone,
    this.id,
    this.role = UserRole.cliente,
  });

  final String? id;
  final String name;
  final String document;
  final String email;
  final String phone;
  final UserRole role;

  AppUser copyWith({String? name, String? email, String? phone}) => AppUser(
    id: id,
    name: name ?? this.name,
    document: document,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    role: role,
  );
}
