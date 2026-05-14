import 'dart:math';

class PasswordGenerator {
  static const String _mayusculas = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _minusculas = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numeros = '0123456789';

  /// Genera una contrasenia temporal basada en CI, nombres y apellidos.
  /// Formato base: NomApe#### (minimo 12 chars, con relleno si falta).
  static String generarContraseniaDesdeDatos({
    required String ci,
    required String nombres,
    required String apellidos, 
  }) {
    final ciLimpio = ci.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    final nombreLimpio = _soloLetrasNumeros(nombres);
    final apellidoLimpio = _soloLetrasNumeros(apellidos);

    final parteNombre = _capitalizar(
      _tomarFragmento(nombreLimpio, fallback: 'usr', longitud: 3),
    );
    final parteApellido = _capitalizar(
      _tomarFragmento(apellidoLimpio, fallback: 'tmp', longitud: 3),
    );
    final parteCi = _ultimosCaracteres(ciLimpio, 4, fallback: '0000');

    var contrasenia = '$parteNombre$parteApellido$parteCi';

    if (contrasenia.length < 12) {
      contrasenia = contrasenia.padRight(12, 'x');
    }

    return contrasenia;
  }

  /// Genera una contraseña segura y aleatoria
  /// Longitud mínima: 12 caracteres
  /// Incluye: mayúsculas, minúsculas y números
  static String generarContraseniaSegura({int longitud = 12}) {
    if (longitud < 12) longitud = 12;

    final random = Random.secure();
    final caracteres = _mayusculas + _minusculas + _numeros;
    final contrasenia = <String>[];

    // Asegurar que tenga al menos 1 de cada tipo
    contrasenia.add(_mayusculas[random.nextInt(_mayusculas.length)]);
    contrasenia.add(_minusculas[random.nextInt(_minusculas.length)]);
    contrasenia.add(_numeros[random.nextInt(_numeros.length)]);

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

  static String _soloLetrasNumeros(String texto) {
    return texto.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').trim();
  }

  static String _tomarFragmento(
    String texto, {
    required String fallback,
    required int longitud,
  }) {
    if (texto.isEmpty) return fallback;
    return texto.substring(0, min(longitud, texto.length)).toLowerCase();
  }

  static String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    final primera = texto[0].toUpperCase();
    final resto = texto.substring(1).toLowerCase();
    return '$primera$resto';
  }

  static String _ultimosCaracteres(String texto, int cantidad, {required String fallback}) {
    if (texto.isEmpty) return fallback;
    if (texto.length >= cantidad) {
      return texto.substring(texto.length - cantidad);
    }
    return texto.padLeft(cantidad, '0');
  }
}
