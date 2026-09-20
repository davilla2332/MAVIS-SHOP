# Actualizar a MAVI'S SHOP 1.1

Si no instalaste nada, sigue INSTRUCCIONES.md y ejecuta solamente 01-schema.sql.

Si ya instalaste la versión anterior:

1. Respalda la base y los archivos de Storage.
2. Reemplaza el código con este paquete, conservando tu proyecto Supabase y las variables públicas reales.
3. Ejecuta únicamente supabase/03-security.sql. Conserva registros y mueve el procesador de escritura al esquema privado. Puede repetirse. No ejecutes 02 después: es un archivo histórico y puede revertir las funciones nuevas.
4. Configura Turnstile en Supabase Auth y VITE_TURNSTILE_SITE_KEY en la web.
5. El administrador debe inscribir y verificar TOTP desde Mi perfil para recuperar sus permisos de gestión.
6. Separa las claves locales: .env contiene solo datos públicos; .env.admin solo se usa para la creación administrativa y se elimina al terminar. Si admin ya existe, no vuelvas a crearlo.
7. Vuelve a desplegar en Vercel y realiza la prueba de aceptación de PUESTA-EN-MARCHA.md.

Los pedidos existentes se conservan. El frontend nuevo usa un ID de solicitud para evitar duplicados y consulta los gastos por un canal exclusivo del vendedor/administrador. La recepción la confirma comprador o administrador.

El archivo histórico 02-renombrar-marca.sql se mantiene para referencia y no se usa con esta versión.
