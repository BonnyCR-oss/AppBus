## Configuracion de Envio de Emails - Bus Claros

Este proyecto envia el correo directamente desde Flutter usando SMTP en `EmailService`.

## Configuracion SMTP (contrasenia de aplicacion)

Ejecuta la app con estas variables:

```bash
flutter run \
  --dart-define=SMTP_HOST=smtp.gmail.com \
  --dart-define=SMTP_PORT=587 \
  --dart-define=SMTP_USER=tu_correo@gmail.com \
  --dart-define=SMTP_PASS_APP=tu_contrasenia_de_aplicacion \
  --dart-define=SMTP_FROM_NAME="Bus Claros"
```

Si no pasas estas variables, la app crea el usuario pero mostrara aviso de que no pudo enviar correo.

## Recomendaciones para Gmail

1. Activa verificacion en dos pasos.
2. Genera una contrasenia de aplicacion.
3. Usa esa contrasenia en `SMTP_PASS_APP`.

## Seguridad

- Las contrasenias de usuarios se generan automaticamente y se guardan hasheadas con BCrypt.
- El admin no puede escribir contrasenia manual.
- El correo contiene una contrasenia temporal para primer ingreso.
