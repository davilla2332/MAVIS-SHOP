# Qué necesitas para poner MAVI'S SHOP en funcionamiento

El ZIP contiene el código; no conecta automáticamente tus cuentas ni acredita pruebas en un entorno real. Una tienda operativa necesita instalar y comprobar cada servicio.

## Servicios y datos

| Necesitas | Para qué | Dónde se configura |
|---|---|---|
| Repositorio GitHub | Guardar el código y publicar cambios | GitHub; subir el contenido, no solo el ZIP |
| Proyecto Supabase | Usuarios, IDs, productos, inventario, pedidos y chat | Ejecutar 01-schema.sql si es nuevo; 02-renombrar-marca.sql si ya instalaste la versión anterior |
| Supabase Auth y Storage | Registro, recuperación y fotografías | Correo/contraseña, confirmación de correo, URLs permitidas; el SQL crea buckets y políticas |
| Vercel | Servir la web por HTTPS | Importar GitHub, Vite, build npm run build, salida dist, tres variables VITE_ |
| Correo real de administrador | Crear la cuenta admin y recuperar acceso | .env local y script npm run admin; en instalaciones existentes conservar la cuenta |
| Proveedor SMTP | Correos de confirmación y recuperación a clientes reales | Authentication → SMTP de Supabase |
| Resend + dominio remitente verificado | Avisos de pedidos y mensajes con la función incluida | Desplegar send-notification, configurar secretos y webhook |
| Contacto y políticas del negocio | Atención, privacidad, devoluciones y reglas de venta | Administración → Configuración |
| Usuarios vendedores con WhatsApp válido | Contacto directo desde sus productos | Perfil; número internacional como +50760000000 |

La web puede utilizar una dirección de Vercel. Para enviar correos a clientes mediante Resend necesitas un dominio remitente verificado; esto es distinto de la dirección donde alojas la tienda. El nombre técnico del repositorio y dominio se escribe sin apóstrofo, por ejemplo mavis-shop; no implica que ese dominio esté disponible.

El plan Hobby de Vercel se destina al uso personal no comercial. Para esta tienda comercial debes usar un plan que permita ese uso, como Pro. Fuente: [Vercel Hobby](https://vercel.com/docs/plans/hobby).

El SMTP predeterminado de Supabase no está pensado para producción y limita los destinatarios. Configura SMTP propio para abrir el registro al público. Fuente: [SMTP de Supabase](https://supabase.com/docs/guides/auth/auth-smtp).

Resend explica los registros DNS necesarios para verificar un dominio remitente: [Dominios verificados](https://resend.com/docs/dashboard/domains/introduction).

## Variables que debes preparar

En Vercel y en tu .env de desarrollo:

- VITE_SUPABASE_URL: URL de tu proyecto.
- VITE_SUPABASE_ANON_KEY: clave pública de Supabase.
- VITE_ADMIN_EMAIL: correo real asociado a admin.

Solo en tu computadora para crear el administrador inicial:

- SUPABASE_SERVICE_ROLE_KEY.
- ADMIN_EMAIL, igual al correo de arriba.
- ADMIN_PASSWORD.

Solo en los secretos de la Edge Function para avisos:

- RESEND_API_KEY.
- MAIL_FROM: MAVI'S SHOP <avisos@tudominio.com>.
- SITE_URL: dirección final de tu web.
- NOTIFICATION_WEBHOOK_SECRET: secreto aleatorio compartido con el webhook.

No es necesario compartir contraseñas o claves privadas por chat. Ponlas en el lugar indicado. No agregues prefijo VITE_ a claves privadas ni las subas a GitHub.

## Orden recomendado

1. Instalar o actualizar Supabase con el SQL que corresponda.
2. Configurar SMTP, remitente y plantillas de Auth.
3. Crear admin si aún no existe; para una actualización no repetir ese paso.
4. Subir a GitHub y desplegar en Vercel con las tres variables públicas.
5. Añadir la URL de producción a Site URL y Redirect URLs en Supabase.
6. Desplegar la función de correos y su webhook, y activar avisos por correo en los perfiles que los deseen.
7. Configurar contacto, categorías y políticas.
8. Realizar las pruebas siguientes en escritorio y teléfono.

## Prueba real de aceptación

Usa dos cuentas tuyas de prueba y un producto temporal; retíralos al terminar si quieres mantener la tienda vacía.

- Registrar comprador y vendedor; recibir correos y confirmar cuentas. Comprobar IDs diferentes.
- Ingresar, salir y recuperar contraseña en la URL final.
- Ingresar con admin y comprobar su segundo factor si lo activaste.
- Publicar fotos y variantes; aprobar con admin; comprobar catálogo y perfil público.
- Editar solo los productos propios. Probar desde la segunda cuenta que no tenga acceso a edición ajena.
- Abrir WhatsApp: comprobar teléfono, nombre nuevo y enlace al producto.
- Conversar desde las dos cuentas, enviar imagen, recibir mensaje y probar bloqueo/reporte.
- Crear pedido con productos de vendedores distintos si vas a usar ese flujo.
- Comprobar cupón, precio, envío y estado pendiente; aceptar y comprobar reducción del inventario.
- Cancelar una reserva y comprobar restauración de existencias.
- Confirmar manualmente pago, envío y entrega de un pedido de prueba; añadir reseña.
- Solicitar devolución; responder como vendedor y revisar como administrador.
- Recibir avisos internos y por correo; revisar también spam y logs de envío.
- Probar vacaciones y suspensión, y acceso administrador a usuarios y publicaciones.
- Revisar adaptación móvil, fotos, cabecera y título de pestaña.

## Lo que no se activa simplemente creando cuentas

- La revisión visual y las pruebas reales de Auth, Storage y envío de correo siguen pendientes en tus servicios. La compilación y pruebas locales no garantizan todos esos servicios.
- El chat consulta mensajes cada cinco segundos; no tiene notificaciones push del sistema ni llamadas.
- Los pagos, entrega física y reembolsos son responsabilidad de cada vendedor y se registran manualmente, según el modelo acordado.
- El correo incluido no tiene cola automática de reintentos: para operación continua debes revisar fallos y reenviar, o añadir una cola antes de depender de entrega garantizada.
- Respalda tanto la base de datos como las imágenes de Storage y comprueba cómo restaurar. Configura monitoreo de errores, consumos y límites de los servicios.

Abre INSTRUCCIONES.md para el procedimiento detallado y ACTUALIZACION.md para conservar tu instalación existente al cambiar de nombre.
