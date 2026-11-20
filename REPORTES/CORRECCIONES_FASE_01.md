# Correcciones solicitadas por auditoría — 18/11/2026

Se releyeron definición, propuesta, alcance y matriz. El resultado observado por la auditoría en Linux (HTTP 200 del catálogo para URL inexistente) es compatible con la búsqueda de index.php que hace el servidor integrado de PHP. No demuestra acceso a `/admin.php`, facturas o documentos internos. La prueba anterior realizada en Windows no garantizaba comportamiento equivalente en Linux; se conserva como registro histórico, no como evidencia universal.

Corrección: `scripts/router.php` usa rutas explícitas y únicamente entrega assets existentes dentro de su directorio real. Todo lo demás responde 404. `scripts/iniciar-frontend.ps1` y README incluyen el router al iniciar PHP. El test conserva la expectativa 404 y explica que debe usarse el entorno documentado; no se relajó a aceptar un catálogo 200. Apache tendrá su configuración propia en fase 5. Fuente: [servidor integrado PHP](https://www.php.net/manual/en/features.commandline.webserver.php).

Se ejecutaron los servidores locales 8000/8002 con el router en Windows y `scripts/verificar-frontend.ps1`: 53 comprobaciones HTTP aprobadas, además de 8 PHP y 3 tests JS. Evidencia: `evidencias/fase02-frontend.txt`. Los servidores se detuvieron. No se ejecutó esta suite con PHP sobre Linux ni Apache; quedan pendientes esas plataformas.

La matriz ahora referencia `app/components/product-form.php`. Se revisó el código de selección de JPG/PNG/WEBP hasta 2 MB, `createObjectURL`, `window.print()` y CSS de impresión. No se reejecutaron la selección de archivo ni la exportación visual; siguen pendientes (el intento anterior de archivo estaba limitado por permisos de extensión). No se fabricaron capturas ni se declaró aprobada una exportación PDF.

La corrección no habilita rutas finales ni modifica autenticación: las dos vulnerabilidades siguen sin implementarse.
