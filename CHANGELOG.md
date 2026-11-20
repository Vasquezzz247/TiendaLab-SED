# Changelog

## 1.0.0 — entrega (20/11/2026)

Primera versión completa de TiendaLab: tienda con tres roles en PHP puro y MariaDB, desplegable en Ubuntu Server 24.04 LTS, con exactamente dos vulnerabilidades deliberadas y documentadas.

### Funcionalidad
- Registro (siempre comprador), login/logout con sesiones, roles verificados en el servidor.
- Comprador: catálogo con búsqueda, carrito, IVA 13 %, compra transaccional con descuento de stock, facturas e historial.
- Vendedor: alta y edición de sus productos con imágenes validadas y re-codificadas.
- Administrador: métricas, CRUD de productos y usuarios, cambio de roles, desactivación lógica.

### Seguridad y correcciones
- Contraseñas con `password_hash`, sesiones regeneradas, CSRF, consultas preparadas, escape de salida, límites de acceso.
- Límite de intentos de login que solo cuenta fallos (PR #9).
- Un vendedor con productos activos no cambia de rol (PR #10).
- Exportación limpia con auditoría de ZIP y kit de entrega (PR #11, #16).
- Apache envía `nosniff` también en los archivos estáticos, sin duplicarlo (PR #15).

### Vulnerabilidades deliberadas (exactamente dos)
- **A. IDOR en `factura.php?id=`** (PR #12).
- **B. Servicio de diagnóstico ficticio expuesto en TCP/8081** (PR #13).

### Despliegue y pruebas
- Instalación en Ubuntu con un comando (`scripts/ubuntu/instalar.sh`), verificación de 34 comprobaciones y kit sin internet (PR #14, #16).
- Suite de 120 pruebas HTTP/BD que pasa en Windows y contra la tienda instalada en Ubuntu (PR #15).

### Límites conocidos
- Ensayo de instalación desde cero con la versión final de `crear-vm.ps1` sin completar (el instalador de Ubuntu se bloqueó en VirtualBox).
- Sin prueba desde otro equipo real del laboratorio, sin PDF de factura generado, sin HTTPS.
- Detalle en `README.md` (sección 9) y `REPORTES/FASE_07_ENTREGA.md`.
