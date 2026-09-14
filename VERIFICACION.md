# Verificación del paquete

- Compilación de producción con Vite: aprobada.
- 7 pruebas de PostgreSQL embebido: aprobadas.
- Se verificaron permisos, identidad única, edición ajena, moderación, reserva y restauración de stock, precios de servidor, chat privado, bloqueo, auditoría, cupones, flujo de pedido, reseñas y exigencia de MFA.
- No hay cuentas ni productos de prueba en el SQL de instalación. Los datos de tests viven en una base temporal en memoria.
- El logo está incluido localmente y referenciado desde la cabecera, inicio, acceso y enlaces icon/apple-touch-icon del HTML.
- La comprobación visual automatizada no pudo completarse: no había un navegador instalado y la descarga de Chromium agotó el tiempo de espera. Revisar escritorio y celular después del despliegue.
- No se usaron credenciales de tus cuentas ni se hicieron pruebas contra tu Supabase. Quedan por comprobar con tu configuración: registro y correos reales, Storage, MFA, función de avisos, login administrador y dominio de Vercel.

Consulta INSTRUCCIONES.md para la instalación y los límites de cada módulo.

Actualización de marca: compilación y siete pruebas SQL nuevamente aprobadas; migración de nombre comprobada sobre una base de prueba. No se realizaron pruebas con servicios reales.
