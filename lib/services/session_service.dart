import 'package:shared_preferences/shared_preferences.dart';

class SessionData {
  final String nombreUsuario;
  final String contactoUsuario;
  final int rolUsuarioId;
  final int? usuarioId;

  const SessionData({
    required this.nombreUsuario,
    required this.contactoUsuario,
    required this.rolUsuarioId,
    this.usuarioId,
  });
}

class SessionService {
  static const String _kNombreUsuario = 'session_nombre_usuario';
  static const String _kContactoUsuario = 'session_contacto_usuario';
  static const String _kRolUsuarioId = 'session_rol_usuario_id';
  static const String _kUsuarioId = 'session_usuario_id';

  Future<void> guardarSesion({
    required String nombreUsuario,
    required String contactoUsuario,
    required int rolUsuarioId,
    int? usuarioId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNombreUsuario, nombreUsuario);
    await prefs.setString(_kContactoUsuario, contactoUsuario);
    await prefs.setInt(_kRolUsuarioId, rolUsuarioId);
    if (usuarioId != null) {
      await prefs.setInt(_kUsuarioId, usuarioId);
    }
  }

  Future<SessionData?> leerSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString(_kNombreUsuario);
    final contacto = prefs.getString(_kContactoUsuario);
    final rol = prefs.getInt(_kRolUsuarioId);
    final usuarioId = prefs.getInt(_kUsuarioId);

    if (nombre == null || contacto == null || rol == null) {
      return null;
    }

    return SessionData(
      nombreUsuario: nombre,
      contactoUsuario: contacto,
      rolUsuarioId: rol,
      usuarioId: usuarioId,
    );
  }

  Future<void> limpiarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kNombreUsuario);
    await prefs.remove(_kContactoUsuario);
    await prefs.remove(_kRolUsuarioId);
    await prefs.remove(_kUsuarioId);
  }
}
