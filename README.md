# MAVI'S SHOP 1.1

Proyecto completo del marketplace en español, con logo, usuarios, productos, pedidos, WhatsApp, chat y administrador. Vite + Supabase, para desplegar desde GitHub en Vercel.

Empieza por **INSTRUCCIONES.md**. Lee **SECURITY.md** para los controles incluidos y lo que debes activar en tus proveedores.

- Instalación nueva: ejecutar solo supabase/01-schema.sql.
- Actualización desde la versión anterior: respaldo y supabase/03-security.sql. No ejecutar 01 otra vez ni el archivo histórico 02.
- .env.example: únicamente variables públicas.
- .env.admin.example: configuración privada exclusivamente local para crear admin; se usa como .env.admin y no se publica.
- El administrador debe activar y verificar su segundo factor para gestionar la tienda.

```bash
npm ci
npm run dev
```

Sin configuración de Supabase puedes ver el diseño vacío. Los servicios reales y el CAPTCHA deben configurarse para usar las cuentas. En Vercel producción se exigen las cuatro variables públicas detalladas en la guía.

Para verificar:

```bash
npm test
npm run audit:security
npm run build
```

VERIFICACION.md registra resultados y límites. PUESTA-EN-MARCHA.md incluye el recorrido de prueba real. El ZIP no representa un despliegue ya activo ni una garantía de seguridad absoluta.
