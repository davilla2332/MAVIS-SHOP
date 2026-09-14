# Actualización a MAVI'S SHOP

La marca cambió en cabeceras, inicio, textos, título de pestaña, correos, WhatsApp, nombre de la aplicación autenticadora y configuración inicial. El símbolo M con bolsa sirve también para MAVI'S SHOP y continúa como logo/favicon; el nombre se presenta como texto a su lado.

## Si todavía no instalaste Supabase

Sigue INSTRUCCIONES.md y ejecuta solamente `supabase/01-schema.sql` en un proyecto nuevo.

## Si ya tienes Supabase con la versión anterior

1. Guarda una copia de tus archivos actuales y de tu configuración .env.
2. Reemplaza el código del repositorio con el contenido de este proyecto. Conserva tu .env local, tus variables de Vercel y el mismo proyecto de Supabase.
3. Ejecuta SOLO `supabase/02-renombrar-marca.sql` en SQL Editor. Actualiza el nombre guardado y el texto de nuevos avisos. No ejecutes otra vez 01-schema.sql.
4. Actualiza el nombre del remitente MAIL_FROM de la función de correo, manteniendo la misma dirección verificada; ejemplo: MAVI'S SHOP <avisos@tudominio.com>. Actualiza también el nombre del remitente SMTP y tus plantillas de confirmación/recuperación en Supabase.
5. Vuelve a desplegar la función send-notification si la utilizas, para actualizar el asunto y cuerpo del correo.
6. Publica el cambio en GitHub y vuelve a desplegar en Vercel.
7. Recarga la web. Verifica el nombre en el título de pestaña, cabecera y correos nuevos.

Los IDs de clientes existentes y el carrito local se conservan. Los IDs seguirán usando el prefijo técnico MAVI-; son identificadores permanentes, no el nombre público de la marca. Las conversaciones y avisos históricos no se reescriben. Los factores MFA ya inscritos pueden seguir mostrando su nombre anterior en la aplicación autenticadora: renombra esa entrada allí si deseas.

El repositorio, carpeta y URL pueden llamarse `mavis-shop` (sin espacios ni apóstrofo). Renombrar este ZIP no cambia automáticamente los nombres o URLs de tus servicios externos.
