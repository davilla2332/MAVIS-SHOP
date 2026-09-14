# MAVI'S SHOP — Guía de instalación

Proyecto preparado para GitHub + Supabase + Vercel. Catálogo vacío; no contiene productos ni usuarios de prueba. El administrador se crea por separado. El logo está en `public/logo.png` y se usa también como favicon y apple-touch-icon. No hace falta crear una imagen adicional para la pestaña.

## 1. Lo que necesitas

- Una cuenta en GitHub, un proyecto nuevo de Supabase y una cuenta de Vercel.
- Node.js 22 o superior en tu computadora.
- Un correo real para administrar y recuperar tu cuenta.

Los archivos funcionan como proyecto: no abras index.html con doble clic. Usa `npm run dev` o despliega con Vercel.

## 2. Crear la base de datos

1. Crea un proyecto NUEVO en Supabase y guarda su contraseña de base de datos.
2. Abre SQL Editor, crea una consulta, pega TODO `supabase/01-schema.sql` y ejecuta una sola vez. Crea tablas, funciones, políticas RLS y buckets de imágenes.
3. No ejecutes este archivo en una base existente con tablas del mismo nombre. No desactives RLS ni concedas permisos de escritura directa a authenticated.
4. En Authentication, habilita correo y contraseña y la confirmación del correo.
5. En la configuración de API, copia Project URL y la clave pública anon/publishable.
6. Configura SMTP personalizado en Authentication para enviar confirmaciones y recuperación a tus clientes. El servicio de correo de desarrollo puede tener restricciones.

## 3. Probar en tu computadora

Abre una terminal dentro de la carpeta que contiene package.json:

```bash
npm ci
```

Duplica `.env.example`, cambia su nombre a `.env` y completa:

```dotenv
VITE_SUPABASE_URL=https://TU-PROYECTO.supabase.co
VITE_SUPABASE_ANON_KEY=TU_CLAVE_PUBLICA
VITE_ADMIN_EMAIL=TU_CORREO_REAL
```

Ejecuta:

```bash
npm run dev
```

Abre la dirección que muestra la terminal. Sin variables, la página muestra su diseño y catálogo vacío, pero no simula cuentas ni pedidos.

## 4. Crear el administrador único

La pantalla acepta el usuario `admin` y lo traduce al correo configurado en VITE_ADMIN_EMAIL. Las otras cuentas entran con correo. El ID de cliente se genera en la base al crear cada cuenta: prefijo MAVI y un UUID completo, único y permanente.

En el archivo LOCAL `.env`, completa también:

```dotenv
SUPABASE_SERVICE_ROLE_KEY=TU_CLAVE_PRIVADA_SERVICE_ROLE
ADMIN_EMAIL=EL_MISMO_CORREO_DE_VITE_ADMIN_EMAIL
ADMIN_PASSWORD=LA_CONTRASEÑA_INICIAL_QUE_ELEGISTE
```

Coloca en ADMIN_PASSWORD la contraseña inicial que indicaste en la conversación. No está incrustada en este proyecto ni en el navegador. Usa un correo que todavía no esté registrado. Ejecuta:

```bash
npm run admin
```

El script crea la cuenta confirmada y la asigna a la tabla administradora. La base permite una sola fila administradora. Ninguna cuenta puede asignarse ese permiso desde el registro público.

Después, entra con `admin`, cambia la contraseña y activa verificación en dos pasos desde Mi perfil. Guarda los datos de tu aplicación autenticadora. El bloqueo de acciones sin segundo factor también se verifica en la base de datos.

Si perdiste tu segundo factor, recupera el acceso desde la administración de Supabase; no cambies las políticas para evitarlo. Si ya existe una cuenta administradora, el script no la modifica. Si una creación se interrumpe entre la cuenta y su asignación, revisa Authentication y la tabla administrators antes de repetirla.

Borra del `.env` la clave service role cuando termines si ya no la necesitas. Nunca la publiques en GitHub, ni uses un nombre VITE_ para ella. `.gitignore` excluye los archivos .env.

## 5. Subir a GitHub

1. Crea un repositorio, por ejemplo `mavis-shop`.
2. Sube el CONTENIDO de esta carpeta, incluyendo package.json, package-lock.json, index.html, src, public, supabase, scripts y vercel.json.
3. No subas el ZIP como único archivo. No subas node_modules, .env ni claves privadas.
4. Puedes usar GitHub Desktop para publicar la carpeta completa o los comandos habituales de git. Mantén el repositorio privado si prefieres.

## 6. Publicar en Vercel

1. En Vercel selecciona Add New → Project e importa el repositorio de GitHub.
2. Framework: Vite. Directorio raíz: donde está package.json. Build: `npm run build`. Output: `dist`.
3. Agrega solamente las tres variables VITE_ descritas en el paso 3.
4. Despliega y copia la dirección HTTPS de producción.
5. En Supabase → Authentication → URL Configuration, establece Site URL con esa dirección y agrega a Redirect URLs:
   - `https://TU-SITIO.vercel.app/**`
   - `http://localhost:5173/**` (solo para desarrollo)
6. Si cambias variables VITE_ en Vercel, vuelve a desplegar: se incorporan durante la compilación.
7. Si añades un dominio propio, actualiza también las URLs de Supabase.

## 7. Avisos por correo (configuración adicional)

Los avisos dentro de la web funcionan con las tablas de Supabase. Para enviar también correos de pedidos y mensajes se incluye `supabase/functions/send-notification/index.ts`. Esto es independiente del SMTP de registro/recuperación.

1. Configura un proveedor Resend y verifica tu dominio remitente.
2. Despliega la función `send-notification` con Supabase CLI o el editor de Edge Functions. El archivo config.toml desactiva la comprobación JWT solo en esta función: la petición se autentica mediante un secreto de webhook.
3. Configura sus secretos: `RESEND_API_KEY`, `MAIL_FROM` (ejemplo: MAVI'S SHOP <avisos@tudominio.com>), `SITE_URL` y `NOTIFICATION_WEBHOOK_SECRET` (una cadena aleatoria larga). Las claves SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY son del entorno servidor de Supabase.
4. Crea un Database Webhook para INSERT en public.notifications, método POST, a la URL de esa función. Agrega el encabezado `x-webhook-secret` con el mismo secreto.
5. El usuario activa “Recibir también avisos por correo” en Mi perfil. Debe mantener activos los avisos internos porque estos generan el evento de envío.
6. Prueba una notificación y comprueba los logs. Los fallos devuelven HTTP 500; revisa y reintenta los eventos fallidos. La clave de idempotencia evita duplicados en reintentos dentro de la ventana del proveedor. No hay una cola automática de reintentos en este paquete.

## 8. Funcionamiento incluido

- Inicio, acceso, registro, confirmación, recuperación y MFA opcional.
- Logo, favicon y diseño adaptable a teléfonos.
- Catálogo con búsqueda, categorías, marca, precios, disponibilidad y ordenamiento.
- Productos con fotos ampliables, descripción, precio anterior, especificaciones, garantía, entrega y variantes con inventario.
- Perfil público con productos, descripción, imagen y verificación administrada.
- Borradores, aprobación de publicaciones, pausas, archivo y vacaciones.
- Favoritos, enlaces compartibles y WhatsApp desde el teléfono registrado.
- Cupones por vendedor: porcentaje, vencimiento y activación. Se ingresan en el carrito. Solo afectan a los vendedores que hayan emitido ese código; sin coincidencia no hay descuento.
- Carrito con cantidades, solicitudes separadas por vendedor y cálculo de precios en servidor.
- Reserva de stock al aceptar; cancelación de reservas libera stock. Las operaciones son transaccionales.
- Historial, costos de envío antes de aceptar, gastos para reporte y seguimiento escrito por vendedor.
- Chat privado con imágenes, historial, lectura, bloqueo y reportes. Consulta nuevos mensajes cada 5 segundos mientras la conversación está abierta; no usa WebSockets ni llamadas.
- Opiniones de vendedor verificadas por pedido entregado, una por pedido.
- Devoluciones y reportes con motivo, evidencia descriptiva y resolución. El administrador puede leer el texto de un chat reportado abierto; la revisión queda auditada. Las imágenes del chat siguen privadas para sus participantes.
- Administración: todos los usuarios e IDs, productos por usuario, moderación, verificación, suspensión, pedidos, reportes, configuración y auditoría.
- Resumen de ventas entregadas y resultado de ingresos menos gastos registrados. No es un sistema contable ni calcula impuestos.

## 9. Reglas del pedido

Pendiente → Aceptado (reserva) → Pago confirmado → Enviado → Entregado.
También se permite entrega directa desde Pago confirmado. El comprador o vendedor puede marcar entrega; las reseñas se habilitan cuando el pedido queda entregado. La verificación refleja el historial registrado en la plataforma, no una confirmación bancaria o del transportista.

Un pedido pendiente puede cancelarse por comprador, vendedor o administrador. Una reserva aceptada puede cancelarla vendedor o administrador. Después del pago confirmado se gestiona una solicitud de devolución: los reembolsos se hacen fuera de la web. No se permite cancelar como si no hubiera pago.

Los precios, nombres y variantes quedan copiados en el pedido. Si existen reservas activas, se bloquea la edición del producto hasta completar o cancelar esas reservas, evitando que se rompan variantes o inventario. Un pedido aún pendiente no reserva existencias; el vendedor debe aceptar para reservar.

El envío se acuerda antes de aceptar y pagar. El importe del envío se muestra separado del subtotal. Los gastos registrados son el costo total que ingrese el vendedor; el cálculo de resultado depende de esos datos. No existe integración con bancos, transportistas ni devolución automática de dinero.

## 10. Antes de abrir al público

Configura el contacto real, categorías y políticas específicas desde Administración → Configuración. El texto inicial es informativo: complétalo con las condiciones de tu negocio, privacidad y devoluciones. Verifica el registro con dos correos tuyos, un producto, un pedido, el chat, las fotos y la recuperación en tu dominio real. Prueba también el administrador y MFA.

Activa los límites de registro y medidas antispam de Supabase apropiadas para tu tráfico. El chat tiene un intervalo mínimo de un segundo entre mensajes en servidor. El paquete no incorpora moderación automática de imágenes, verificación de teléfono por SMS, logística ni pagos automáticos.

Programa respaldos según el servicio contratado. Para una copia manual usa Supabase CLI `supabase db dump` y respalda también los objetos de Storage por separado: el dump SQL no contiene las fotos. La retención de copias depende de la configuración del proyecto, no de este ZIP.

## 11. Pruebas incluidas y límites de validación

```bash
npm test
npm run build
```

Las pruebas usan PostgreSQL embebido PGlite con un esquema mínimo de Auth/Storage para comprobar funciones SQL y permisos: privacidad, edición ajena, moderación, reservas y cancelación, precios en servidor, bloqueo de chat, auditoría, cupones, flujo completo, reseñas y MFA. No crean datos en Supabase ni en tu tienda.

La compilación y las pruebas locales no sustituyen una prueba de extremo a extremo con tu Supabase real: correos, Storage, creación del administrador, URLs de recuperación y despliegue requieren tus cuentas y configuración. No se ha creado ni publicado un repositorio o despliegue en tus cuentas.

## Referencias de instalación

- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Políticas RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Permisos de imágenes](https://supabase.com/docs/guides/storage/security/access-control)
- [Vite en Vercel](https://vercel.com/docs/frameworks/frontend/vite)
- [Webhooks de Supabase](https://supabase.com/docs/guides/database/webhooks)
- [Idempotencia de correos Resend](https://resend.com/docs/dashboard/emails/idempotency-keys)

## Identidad visual

Logo generado con ImageGen integrado en public/logo.png. Brief: símbolo M integrado con asa de bolsa de compras, azul marino #14243b y coral #ff6654, silueta simple legible como favicon, sin palabra adicional. El nombre MAVI'S SHOP se escribe como texto accesible junto al símbolo.
