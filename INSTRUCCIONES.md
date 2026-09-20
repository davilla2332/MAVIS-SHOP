# MAVI'S SHOP 1.1 — Instalación completa

Este paquete incluye toda la web, logo, SQL, chat, pedidos, administrador y función de avisos. No incluye credenciales reales ni cuentas de prueba.

## 1. Archivos y preparación

Extrae el ZIP y abre la carpeta `mavis-shop` en VS Code. Debes ver package.json. Instala Node.js 22 o superior y ejecuta en la terminal:

```bash
npm ci
```

Para trabajar localmente se usa `npm run dev`, no Live Server ni doble clic en index.html. El servidor escucha únicamente en tu computadora, en http://localhost:5173.

## 2. Supabase: elige SOLO el caso que corresponda

**Proyecto nuevo y sin tablas de esta tienda:** abre SQL Editor, pega TODO `supabase/01-schema.sql` y ejecútalo una sola vez. Ya incluye el refuerzo de seguridad de 1.1.

**Ya instalaste una versión anterior:** respalda tu base y Storage. Ejecuta únicamente `supabase/03-security.sql`. No ejecutes 01 otra vez ni 02 después de 03: el archivo 02 es histórico y podría restaurar funciones antiguas. El archivo 03 conserva usuarios, productos, pedidos y chat.

Usa el mismo proyecto Supabase si quieres conservar tus datos. En una instalación existente se conservan los nombres visibles históricos; el nombre público de la tienda se establece a MAVI'S SHOP.

## 3. Configurar autenticación

En Supabase → Authentication → Sign In / Providers:

- Permite nuevos registros.
- Activa el proveedor Email, correo/contraseña y Confirm email.
- Configura SMTP personalizado y remitente real para confirmación y recuperación. El correo predeterminado de desarrollo no sirve para abrir registros públicos.
- Configura MFA/TOTP. La cuenta administradora no podrá gestionar la tienda hasta verificar el segundo factor.
- En las opciones de contraseñas, exige un mínimo de 16 caracteres y revisa límites de intentos. El formulario de la página pide 16; la regla de Supabase es la que lo impone al servidor.

Para CAPTCHA crea un widget Turnstile en Cloudflare con tus dominios autorizados. En Supabase → Authentication → protección contra bots, activa CAPTCHA, selecciona Turnstile y pega su clave SECRETA. Esta clave no se agrega a Vercel ni al código cliente. Copia la SITE KEY pública para el siguiente paso.

## 4. Variables públicas de la página

Copia `.env.example` y llámalo `.env`, junto a package.json. Completa:

```dotenv
VITE_SUPABASE_URL=https://TU-PROYECTO.supabase.co
VITE_SUPABASE_ANON_KEY=sb_publishable_TU_CLAVE_PUBLICA
VITE_ADMIN_EMAIL=tu-correo-real@ejemplo.com
VITE_TURNSTILE_SITE_KEY=TU_SITE_KEY_PUBLICA
```

Project URL y Publishable key están en Connect / Settings → API Keys de Supabase. Aunque la variable diga ANON_KEY, acepta la clave publishable. Estos cuatro valores llegan al navegador. Nunca pegues una clave sb_secret_ o service_role en una variable VITE_.

El .env real no se sube a GitHub. Si vas a ver únicamente el diseño sin conectar servicios, no crees .env todavía. Para Auth real activa las claves y el CAPTCHA; autoriza localhost en el widget si lo vas a usar localmente.

## 5. Crear admin una sola vez

Copia `.env.admin.example` como `.env.admin` en tu computadora:

```dotenv
SUPABASE_URL=https://TU-PROYECTO.supabase.co
SUPABASE_SECRET_KEY=TU_CLAVE_PRIVADA_SB_SECRET
ADMIN_EMAIL=EL_MISMO_CORREO_DE_VITE_ADMIN_EMAIL
ADMIN_PASSWORD=CONTRASEÑA_NUEVA_UNICA_DE_16_O_MAS_CARACTERES
```

Esta clave privada es solo para el script administrativo local. No se usa para compilar la página, no se sube a GitHub y no se agrega a Vercel. Usa una contraseña nueva que no hayas compartido previamente.

Ejecuta:

```bash
npm run admin
```

El correo debe estar libre antes de crearlo. El script crea la cuenta confirmada y asigna el administrador único. Si ya tienes admin, no repitas este paso; conserva su correo y cuenta. Si se creó la cuenta pero falló la asignación, revisa Authentication y administrators antes de repetir.

Ingresa a la web con `admin` y tu contraseña. Ve a Mi perfil → Seguridad → Activar verificación en dos pasos. Escanea el QR con tu aplicación autenticadora e introduce el código. Los permisos administrativos se habilitan cuando la sesión está verificada. Guarda acceso a la aplicación autenticadora; en caso de pérdida necesitarás la administración de Supabase para recuperar el factor.

Después de crear admin, elimina `.env.admin` si ya no lo necesitas y guarda las credenciales en un gestor de contraseñas.

## 6. GitHub y Vercel

1. Crea un repositorio y sube el contenido de `mavis-shop`, dejando package.json en la raíz. No subas únicamente el ZIP, node_modules, dist o archivos .env reales.
2. En Vercel importa ese repositorio. Selecciona Vite, compilación `npm run build`, carpeta de salida `dist`.
3. Agrega las cuatro variables VITE_ del paso 4 a producción. La compilación productiva se detiene si falta alguna o detecta una clave privilegiada en una variable pública.
4. Para una tienda comercial usa un plan que lo permita; Hobby de Vercel es para uso personal no comercial.
5. Publica. En Supabase configura Site URL con tu dirección HTTPS final y permite sus URLs de redirección. Para este proyecto puedes autorizar `https://TU-SITIO.vercel.app/**` únicamente para tu sitio. Agrega `http://localhost:5173/**` solo cuando lo necesites para desarrollo.
6. En Turnstile autoriza el dominio exacto de tu web. Si cambias variables VITE_, vuelve a desplegar.
7. Verifica que las cabeceras de seguridad de vercel.json se apliquen en producción.

No necesitas un dominio propio para visualizar la web de Vercel. Para correos Resend a clientes reales sí necesitas un dominio remitente verificado.

## 7. Correos de pedidos y mensajes

La función `supabase/functions/send-notification/index.ts` envía avisos de la tabla notifications. Es independiente del SMTP de Auth.

1. Configura Resend y verifica el dominio desde el que enviarás.
2. Despliega la Edge Function send-notification en Supabase. `supabase/config.toml` desactiva JWT solamente en esa función: la petición se valida con un secreto de webhook independiente.
3. Configura sus secretos: RESEND_API_KEY, MAIL_FROM (MAVI'S SHOP <avisos@tudominio.com>), SITE_URL y NOTIFICATION_WEBHOOK_SECRET (valor aleatorio largo). SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY se utilizan solo en el entorno servidor de la función, nunca en Vite.
4. Crea un Database Webhook de tipo INSERT para public.notifications que llame por POST a la función. Agrega el encabezado x-webhook-secret con el mismo secreto.
5. Activa los avisos internos y por correo en los perfiles deseados. Prueba el envío, spam y logs.
6. Los fallos requieren revisión/reintento operativo. La función usa idempotencia del proveedor, pero no incluye una cola de reintentos automática.

## 8. Configuración del negocio y reglas de venta

Configura contacto, categorías y políticas en Administración. Cada vendedor registra teléfono internacional, fotos, variantes y disponibilidad. WhatsApp usa su número registrado. El chat se actualiza mediante consulta cada cinco segundos cuando la conversación está abierta.

El comprador envía solicitudes; el servidor calcula el precio actual. Se crea un pedido por vendedor. Al aceptar se reserva stock; al cancelar una reserva se devuelve. El envío se acuerda antes de aceptar y pagar. El vendedor registra el pago recibido y el envío; comprador o administrador confirman recepción. Los gastos internos son privados para vendedor/administrador. La reseña requiere un pedido entregado.

Los productos con reservas activas no se editan hasta completar/cancelar esas reservas. Un pedido pendiente no reserva stock. Después de registrar pago, se gestiona devolución en lugar de cancelar como si no hubiera pago. La plataforma no mueve dinero ni realiza reembolsos bancarios.

## 9. Verificar antes de abrir

Lee PUESTA-EN-MARCHA.md y SECURITY.md. Prueba con cuentas reales de ensayo el registro, MFA, CAPTCHA, recuperación, imágenes, publicación, aprobación, chat, bloqueo, carrito, inventario, cancelación, pago manual, entrega, reseña y correo. Comprueba permisos desde una cuenta distinta y la vista móvil.

```bash
npm test
npm run audit:security
npm run build
```

GitHub Actions repite estos controles en cambios al repositorio. Configura la rama para exigirlos. Programa respaldos de base y Storage, verifica restauración, revisa logs/consumo y corrige futuras alertas de dependencias.

Referencias: [Supabase SMTP](https://supabase.com/docs/guides/auth/auth-smtp), [CAPTCHA](https://supabase.com/docs/guides/auth/auth-captcha), [API keys](https://supabase.com/docs/guides/getting-started/api-keys), [Vercel Vite](https://vercel.com/docs/frameworks/frontend/vite), [Vercel Hobby](https://vercel.com/docs/plans/hobby).
