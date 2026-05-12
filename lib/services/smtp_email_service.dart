import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:async';
import 'dart:io';

import '../config/smtp_config.dart';

class SmtpEmailService {
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 2;

  Future<void> _enviarMensaje(Message message) async {
    if (kIsWeb) {
      throw 'SMTP directo no funciona en Flutter Web. Usa una API backend (Supabase Edge) para enviar correos.';
    }

    if (!SmtpConfig.isConfigured) {
      throw 'Configuracion SMTP invalida: host=${SmtpConfig.cleanHost.isNotEmpty}, usuario=${SmtpConfig.cleanUsername.isNotEmpty}, appPassword=${SmtpConfig.cleanAppPassword.isNotEmpty}. Revisa lib/config/smtp_config.dart.';
    }

    final servidores = <({String label, SmtpServer server})>[
      (
        label: 'Gmail SSL 465',
        server: SmtpServer(
          SmtpConfig.host,
          port: 465,
          username: SmtpConfig.cleanUsername,
          password: SmtpConfig.cleanAppPassword,
          ssl: true,
        ),
      ),
      (
        label: 'Gmail STARTTLS 587',
        server: SmtpServer(
          SmtpConfig.host,
          port: 587,
          username: SmtpConfig.cleanUsername,
          password: SmtpConfig.cleanAppPassword,
          ssl: false,
        ),
      ),
    ];

    Object? ultimoError;
    for (final servidor in servidores) {
      int intentos = 0;
      while (intentos <= _maxRetries) {
        try {
          intentos++;

          await send(message, servidor.server).timeout(
            _timeout,
            onTimeout: () {
              throw TimeoutException(
                'SMTP connection timeout after ${_timeout.inSeconds}s',
              );
            },
          );

          return;
        } on SocketException catch (e) {
          ultimoError = e;
          if (intentos <= _maxRetries) {
            await Future.delayed(Duration(seconds: intentos * 2));
            continue;
          }
          break;
        } on TimeoutException catch (e) {
          ultimoError = e;
          if (intentos <= _maxRetries) {
            await Future.delayed(Duration(seconds: intentos * 2));
            continue;
          }
          break;
        } catch (e) {
          ultimoError = e;

          if (e.toString().contains('Connection refused') ||
              e.toString().contains('Connection reset') ||
              e.toString().contains('temporarily unavailable')) {
            if (intentos <= _maxRetries) {
              await Future.delayed(Duration(seconds: intentos * 2));
              continue;
            }
            break;
          }

          if (e.toString().contains('535') ||
              e.toString().contains('Authentication failed') ||
              e.toString().contains('Invalid credentials')) {
            throw 'Error de autenticacion con Gmail. Verifica que la contrasenia de aplicacion sea correcta y que 2FA este habilitado.';
          }

          break;
        }
      }
    }

    throw 'No se pudo enviar el correo SMTP tras probar SSL(465) y STARTTLS(587). Verifica red del movil (puertos salientes), VPN/firewall y datos moviles. Detalle: $ultimoError';
  }

  Future<void> enviarContraseniaGenerada({
    required String to,
    required String nombre,
    required String contrasenia,
  }) async {
    final message = Message()
      ..from = Address(SmtpConfig.cleanUsername, SmtpConfig.fromName)
      ..recipients.add(to)
      ..subject = 'Tu contrasenia de acceso - Bus Claros'
      ..html = '''
<div style="font-family: Arial, sans-serif; line-height: 1.5; color: #1f2937;">
  <h2>Bienvenido a Bus Claros</h2>
  <p>Hola $nombre, tu cuenta fue creada correctamente.</p>
  <p>Tu contrasenia temporal es:</p>
  <p style="font-size: 20px; font-weight: bold; letter-spacing: 1px; background: #f3f4f6; padding: 10px; border-radius: 4px;">$contrasenia</p>
  <p>Inicia sesion y cambiala cuando sea posible.</p>
</div>
''';

    await _enviarMensaje(message);
  }

  Future<void> enviarCodigoRestablecimiento({
    required String to,
    required String nombre,
    required String codigo,
  }) async {
    final message = Message()
      ..from = Address(SmtpConfig.cleanUsername, SmtpConfig.fromName)
      ..recipients.add(to)
      ..subject = 'Codigo de verificacion - Bus Claros'
      ..html = '''
<div style="font-family: Arial, sans-serif; line-height: 1.5; color: #1f2937;">
  <h2>Restablecimiento de contrasenia</h2>
  <p>Hola $nombre, recibimos una solicitud para restablecer tu contrasenia.</p>
  <p>Tu codigo de verificacion (4 digitos) es:</p>
  <p style="font-size: 28px; font-weight: bold; letter-spacing: 4px; background: #f3f4f6; padding: 10px; border-radius: 4px; text-align: center;">$codigo</p>
  <p>Si no hiciste esta solicitud, ignora este mensaje.</p>
</div>
''';

    await _enviarMensaje(message);
  }

  Future<void> enviarNuevaContraseniaRestablecida({
    required String to,
    required String nombre,
    required String contrasenia,
  }) async {
    final message = Message()
      ..from = Address(SmtpConfig.cleanUsername, SmtpConfig.fromName)
      ..recipients.add(to)
      ..subject = 'Nueva contrasenia generada - Bus Claros'
      ..html = '''
<div style="font-family: Arial, sans-serif; line-height: 1.5; color: #1f2937;">
  <h2>Tu nueva contrasenia</h2>
  <p>Hola $nombre, tu verificacion fue correcta.</p>
  <p>Tu nueva contrasenia temporal es:</p>
  <p style="font-size: 20px; font-weight: bold; letter-spacing: 1px; background: #f3f4f6; padding: 10px; border-radius: 4px;">$contrasenia</p>
  <p>Usala para iniciar sesion y cambiala cuanto antes.</p>
</div>
''';

    await _enviarMensaje(message);
  }
}
