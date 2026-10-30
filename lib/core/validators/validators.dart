abstract final class Validators {
  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Escribe tu correo. Ejemplo: nombre@correo.com';
    }
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
        ? null
        : 'El correo no es válido. Usa el formato nombre@correo.com';
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Escribe una contraseña de al menos 8 caracteres.';
    return text.length >= 8
        ? null
        : 'Faltan caracteres. Usa al menos 8 (ahora tienes ${text.length}).';
  }

  static String? name(String? value) {
    final parts = (value ?? '').trim().split(RegExp(r'\s+'));
    if ((value ?? '').trim().isEmpty) {
      return 'Escribe tu nombre y apellido.';
    }
    return parts.length >= 2
        ? null
        : 'Incluye también tu apellido. Ejemplo: Ana Pérez.';
  }

  static String? phone(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Escribe tu celular de 9 dígitos, empezando en 9.';
    return RegExp(r'^9\d{8}$').hasMatch(text)
        ? null
        : 'El celular debe tener 9 dígitos y empezar con 9. Ejemplo: 987654321.';
  }

  static String normalizePhone(String value) =>
      value.trim().replaceAll(RegExp(r'[\s()\-]'), '');

  static String? registrationPhone(String? value) {
    final text = normalizePhone(value ?? '');
    if (text.isEmpty) {
      return 'Escribe tu número con código de país. Ejemplo: +51987654321.';
    }
    return RegExp(r'^\+?[0-9]{1,15}$').hasMatch(text)
        ? null
        : 'Solo números, hasta 15 dígitos. Revisa el código de país.';
  }

  static String? document(String? value, String type) {
    final text = value ?? '';
    if (text.isEmpty) {
      return type == 'DNI'
          ? 'Escribe tu DNI de 8 dígitos.'
          : 'Escribe el número de documento.';
    }
    final valid =
        (type == 'DNI' ? RegExp(r'^\d{8}$') : RegExp(r'^[a-zA-Z0-9]{6,12}$'))
            .hasMatch(text);
    if (valid) return null;
    return type == 'DNI'
        ? 'El DNI debe tener exactamente 8 dígitos, sin letras ni espacios.'
        : 'Usa entre 6 y 12 caracteres (letras o números).';
  }
}
