# Seguridad de MAVI'S SHOP 1.1

Esta versión refuerza el proyecto. No constituye certificación, auditoría independiente ni garantía de ausencia de vulnerabilidades.

## Controles aplicados

- RLS en tablas. Escrituras de usuarios únicamente por funciones validadas; procesador interno y sus tablas en un esquema privado sin permisos del navegador.
- Administrador único con segundo factor TOTP requerido por la base para acciones y lecturas administrativas. El acceso inicial solo permite preparar su segundo factor. Otros usuarios con MFA inscrito también deben verificarlo para operar.
- Clave pública separada de las privadas: .env para web; .env.admin solo local para crear admin. Archivos reales ignorados por Git. Un control de compilación rechaza claves privilegiadas en variables VITE_.
- CAPTCHA Turnstile integrado en ingreso, registro y recuperación. Su validación real la hace Supabase; el propietario debe activar CAPTCHA allí con el secreto correspondiente.
- Catálogo y perfiles públicos limitados; los compradores sin productos no se listan públicamente. Los participantes de pedidos/chat ven los nombres necesarios. Los gastos internos solo los consulta el vendedor o administrador autorizado.
- Chat con permisos por participante, adjuntos privados, bloqueo y revisión administrativa de texto reportado auditada.
- Validación del servidor: tamaño máximo de solicitud, campos obligatorios, nulos, cantidades, inventario, variantes y costos. Se rechazan variantes duplicadas en un carrito.
- Reserva/cancelación transaccional con bloqueo de filas; solicitud de pedido idempotente mediante UUID. Reintentar el mismo pedido con el mismo UUID no crea otra venta. El ID se mantiene durante reintentos en la misma pestaña, no tras recargar.
- Recepción confirmada por comprador o administrador. Reseñas solo para pedidos entregados y una por pedido.
- Límites por cuenta: 120 operaciones/minuto, 10 creaciones de carrito/hora, 10 reportes/hora, 30 ediciones/publicaciones/hora, 500 publicaciones, 20 cargas/minuto y 1000 archivos acumulados. Los rechazos revierten su transacción; el control cuenta operaciones exitosas. No sustituye los límites por IP ni una defensa DDoS del proveedor.
- Imágenes de la interfaz restringidas al Storage de tu Supabase; se bloquean URLs externas de rastreo y esquemas ejecutables. Se validan tipos del carrito recuperado del navegador y se escapan textos al construir HTML.
- Cabeceras CSP, HSTS, anti-iframe, nosniff, restricciones de permisos y no-store en Vercel. CSP permite Supabase y Turnstile. Se conserva unsafe-inline solo para estilos existentes, nunca para scripts. Usa URL estándar *.supabase.co; un dominio personalizado de Supabase requiere ajustar CSP y validación.
- Vite actualizado a una versión corregida y servidor local ligado a 127.0.0.1. GitHub Actions para pruebas, compilación y auditoría; Dependabot para avisos de nuevas dependencias.

## Lo que debe configurar el propietario

1. Activar email/contraseña, confirmación de email, SMTP, TOTP y CAPTCHA en Supabase. El código cliente no puede imponer la configuración de Auth del servidor.
2. Establecer contraseña mínima de 16 caracteres en Auth para nuevas cuentas, con límites de intentos y protección de contraseñas filtradas si está disponible en tu plan. El administrador usa una contraseña NUEVA y única; no reutilices una que hayas compartido por chat.
3. Configurar Site URL y una lista de redirecciones concreta para producción. No autorizar comodines de dominios ajenos. Retirar localhost de la configuración productiva cuando ya no se use.
4. Usar cuentas separadas de desarrollo y producción; guardar secretos en los servicios correspondientes y activar MFA en GitHub, Supabase, Vercel y correo administrativo.
5. Configurar reglas de firewall y límites por IP en los proveedores para las rutas web/API y Auth. El límite de este código es por cuenta, no evita múltiples registros fraudulentos por sí solo.
6. Configurar respaldos de base de datos y Storage, retención y ensayo de restauración. Revisar logs, consumo, fallos de correo y alertas operativas.
7. Validar dominio/remitente, DNS y el secreto del webhook. Rotar las claves si se exponen, y volver a desplegar donde corresponda.
8. Configurar protección de rama y exigir el workflow de verificación antes de integrar cambios. Revisar y resolver alertas futuras; un audit sin hallazgos hoy no cubre el futuro.

## Límites explícitos

- No hubo acceso a tus credenciales ni validación contra tus instancias reales. Registro, MFA real, correo, CAPTCHA y Storage requieren pruebas en ese entorno.
- El formato MIME y tamaño se restringen en Supabase; este paquete no incluye antivirus, análisis de contenido, cuarentena o validación binaria en servidor. No permite documentos o ejecutables en la interfaz. Si tu exposición pública lo requiere, añade análisis de archivos antes de publicar.
- Las fotos del bucket products son públicas por diseño, también si se conoce la URL de una foto previamente publicada. No deben contener información privada. No hay limpieza automática de huérfanos; revisar consumo y archivos desde la administración de Storage.
- El chat no tiene cifrado de extremo a extremo: Supabase y quienes administran el servicio pueden acceder a datos. Las URLs firmadas de adjuntos caducan a los 10 minutos y son utilizables por quien tenga ese enlace hasta su caducidad.
- Las sesiones de Supabase se almacenan en el navegador; CSP y escape de textos reducen XSS, pero no eliminan todo riesgo de robo de sesión en un dispositivo comprometido. No es una arquitectura de cookies HttpOnly.
- El envío de correo no incluye una cola automática de reintentos. Revisa fallos y reintenta o incorpora un servicio de cola antes de exigir entrega garantizada.
- Pagos, envíos y devoluciones físicas se coordinan fuera de la plataforma. Una confirmación registrada no acredita un movimiento bancario.
- No se realizó pentest externo ni certificación legal. Revisa políticas del negocio y el tratamiento de datos según tu operación.

## Si ocurre una exposición

Revoca/rota la clave afectada desde su proveedor, actualiza el secreto en el destino correcto, vuelve a desplegar y revisa logs y sesiones. No desactives RLS para resolver errores. Contacta con el soporte del proveedor si detectas acceso no autorizado.

Referencias: [RLS de Supabase](https://supabase.com/docs/guides/database/postgres/row-level-security), [CAPTCHA](https://supabase.com/docs/guides/auth/auth-captcha), [claves de API](https://supabase.com/docs/guides/getting-started/api-keys).
