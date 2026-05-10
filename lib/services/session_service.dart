import 'package:shared_preferences/shared_preferences.dart';

class SessionData {
  final String nombreUsuario;
  final String contactoUsuario;
  final int rolUsuarioId;

  const SessionData({
    required this.nombreUsuario,
    required this.contactoUsuario,
    required this.rolUsuarioId,
  });
}

class SessionService {
  static const String _kNombreUsuario = 'session_nombre_usuario';
  static const String _kContactoUsuario = 'session_contacto_usuario';
  static const String _kRolUsuarioId = 'session_rol_usuario_id';

  Future<void> guardarSesion({
    required String nombreUsuario,
    required String contactoUsuario,
    required int rolUsuarioId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNombreUsuario, nombreUsuario);
    await prefs.setString(_kContactoUsuario, contactoUsuario);
    await prefs.setInt(_kRolUsuarioId, rolUsuarioId);
  }

  Future<SessionData?> leerSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString(_kNombreUsuario);
    final contacto = prefs.getString(_kContactoUsuario);
    final rol = prefs.getInt(_kRolUsuarioId);

    if (nombre == null || contacto == null || rol == null) {
      return null;
    }

    return SessionData(
      nombreUsuario: nombre,
      contactoUsuario: contacto,
      rolUsuarioId: rol,
    );
  }

  Future<void> limpiarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kNombreUsuario);
    await prefs.remove(_kContactoUsuario);
    await prefs.remove(_kRolUsuarioId);
  }
}
