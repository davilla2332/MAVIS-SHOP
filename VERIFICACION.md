# Verificación de MAVI'S SHOP 1.1

Comprobaciones locales de esta entrega:

- Compilación de producción Vite 6.4.3: aprobada.
- 14 pruebas automatizadas: aprobadas. Incluyen permisos, IDs, edición ajena, precios del servidor, reserva/cancelación, chat privado, bloqueo, auditoría, cupones, reseñas, MFA, gastos privados, perfiles públicos limitados, idempotencia, límites, validación de entradas, URLs de imágenes y detección de secretos en variables VITE_.
- npm audit: 0 vulnerabilidades conocidas reportadas para el árbol de dependencias instalado al verificar esta versión. Este resultado no es una auditoría integral del código y puede cambiar con nuevos avisos.
- Migración desde el esquema anterior, repetida dos veces: aprobada; se conservó el perfil de ensayo.
- Chromium local: inicio en escritorio y catálogo a 390 px revisados. Sin errores de JavaScript ni desbordamiento horizontal; validación del campo de teléfono comprobada. Capturas en docs/.
- Inicio y registro compilados servidos con las cabeceras CSP de vercel.json: sin violaciones CSP ni errores JavaScript en esas páginas sin conexión a Supabase.

Límites: PostgreSQL embebido PGlite emula el esquema básico de Auth/Storage para los tests; no sustituye Supabase real. Las comprobaciones visuales no cubren todos los paneles autenticados. No se probaron CAPTCHA, correo, MFA remoto, subida real de archivos ni despliegue en tus servicios porque no están conectados. No se realizó prueba de carga, pentest externo ni validación de recuperación de respaldos.

Los datos de prueba están aislados en memoria y no se insertan en la instalación. El paquete no contiene .env reales, claves privadas o contraseñas de administrador.
