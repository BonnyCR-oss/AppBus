class SmtpConfig {
  // Completa estos valores con tu correo SMTP.
  static const String host = 'smtp.gmail.com';
  static const int port = 587;
  static const bool useSsl = false;

  // Correo remitente (ejemplo: tu_correo@gmail.com).
  static const String username ='bonnycresporomero@gmail.com';

  // Contrasenia de aplicacion del correo.
  static const String appPassword ='wzxu lugp llru cdsq';

  // Nombre que aparecera como remitente.
  static const String fromName = "Bus Claros";

  static String get cleanHost => host.trim();
  static String get cleanUsername => username.trim();
  static String get cleanAppPassword =>
      appPassword.replaceAll(RegExp(r'\s+'), '').trim();

  static bool get isConfigured {
    return cleanHost.isNotEmpty &&
        cleanUsername.isNotEmpty &&
        cleanAppPassword.isNotEmpty;
  }
}
