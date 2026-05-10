import 'dart:math';

class PasswordGenerator {
  static const String _mayusculas = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _minusculas = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numeros = '0123456789';
  static const String _especiales = '!@#\$%^&*-_=+';

  /// Genera una contraseña segura y aleatoria
  /// Longitud mínima: 12 caracteres
  /// Incluye: mayúsculas, minúsculas, números y caracteres especiales
  static String generarContraseniaSegura({int longitud = 12}) {
    if (longitud < 12) longitud = 12;

    final random = Random.secure();
    final caracteres = _mayusculas + _minusculas + _numeros + _especiales;
    final contrasenia = <String>[];

    // Asegurar que tenga al menos 1 de cada tipo
    contrasenia.add(_mayusculas[random.nextInt(_mayusculas.length)]);
    contrasenia.add(_minusculas[random.nextInt(_minusculas.length)]);
    contrasenia.add(_numeros[random.nextInt(_numeros.length)]);
    contrasenia.add(_especiales[random.nextInt(_especiales.length)]);

    // Llenar el resto aleatoriamente
    for (int i = contrasenia.length; i < longitud; i++) {
      contrasenia.add(caracteres[random.nextInt(caracteres.length)]);
    }

    // Mezclar para que no sea predecible
    contrasenia.shuffle();

    return contrasenia.join();
  }

  /// Valida si una contraseña es segura
  static bool esContraseniaSegura(String contrasenia) {
    if (contrasenia.length < 12) return false;
    if (!contrasenia.contains(RegExp(r'[A-Z]'))) return false;
    if (!contrasenia.contains(RegExp(r'[a-z]'))) return false;
    if (!contrasenia.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }
}
