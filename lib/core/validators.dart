abstract final class Validators {
  static String? email(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Ingresa un correo electrónico válido.';
  static String? password(String? value) =>
      (value?.length ?? 0) >= 8 ? null : 'Usa al menos 8 caracteres.';
  static String? name(String? value) =>
      (value ?? '').trim().split(RegExp(r'\s+')).length >= 2
      ? null
      : 'Ingresa tu nombre y apellido.';
  static String? phone(String? value) =>
      RegExp(r'^9\d{8}$').hasMatch(value ?? '')
      ? null
      : 'Ingresa un celular peruano de 9 dígitos.';
  static String? document(String? value, String type) =>
      (type == 'DNI' ? RegExp(r'^\d{8}$') : RegExp(r'^[a-zA-Z0-9]{6,12}$'))
          .hasMatch(value ?? '')
      ? null
      : type == 'DNI'
      ? 'El DNI debe tener 8 dígitos.'
      : 'Ingresa un documento válido.';
}
