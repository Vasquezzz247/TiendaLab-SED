# Fase 3 — backend PHP e integración completa

Fecha: 18/11/2026. Arquitectura aprobada conservada. Fases 4 y 5 no iniciadas.

## 1. Objetivo

Convertir las vistas de TiendaLab en operaciones reales con PHP puro, mysqli y MariaDB, conservando diseño, esquema, datos ficticios iniciales y volumen. Autenticar y autorizar todas las rutas restringidas; facturas con control normal de propiedad antes de la futura fase 4.

Se releyeron los dos PDF completos, AGENTS, alcance, matriz, base, guía de seguridad y reportes previos. La rama `feature/fase-03-backend` partió de `develop` limpia y sincronizada en `4b5bbd57a11fcfac874f7dd231416e60eeb5eaa8` (PR #6).

## 2. Requisitos cubiertos

Registro comprador obligatorio, correo duplicado, hash/verificación de contraseñas, login/logout, sesiones e inactividad, autorización por roles y propiedad; catálogo y búsqueda SQL; carrito de sesión; IVA 13 %; compra transaccional, stock, factura y detalle; historial propio; alta/edición de productos propios e imágenes; métricas y CRUD administrativo de productos/usuarios, roles y bajas lógicas. Escape, consultas preparadas, CSRF y errores controlados aplicados en servidor.

La [matriz](../docs/MATRIZ_REQUISITOS.md) relaciona R01–R35 con implementaciones y límites. IDOR y diagnóstico 8081 siguen pendientes; `main` se mantiene como rama de entrega sin cambios.

## 3. Archivos creados y modificados

| Grupo | Rutas y finalidad |
| --- | --- |
| Configuración/seguridad | app/database.php, app/auth.php, app/bootstrap.php; mysqli, validación, sesiones, CSRF y cabeceras |
| Servicios | app/shop.php, app/management.php, app/images.php; compras, gestión e imágenes |
| Coordinación web | app/web.php; rutas fijas, roles, POST, redirecciones y errores |
| Rutas reales | public/index.php, login.php, register.php, logout.php, carrito.php, factura.php, historial.php, vendedor.php, admin-productos.php, admin-usuarios.php, imagen.php |
| Interfaz | app/views/live/*.php; app/components/live-*.php; cabecera/pie compartidos; public/assets/js/live.js y ajustes mínimos de CSS |
| Ejecución | scripts/router.php, scripts/iniciar-frontend.ps1; extensiones PHP y maquetas por opción explícita |
| Pruebas | tests/backend.test.cjs, tests/backend-fixtures.php, tests/http.test.cjs, scripts/verificar-backend.ps1 |
| Publicación | .gitignore excluye storage/; scripts/auditar-exportacion.py revisa también esa ruta |
| Documentación | README, AGENTS, alcance, matriz, base, GitFlow, estado y guía de seguridad; este reporte y REPORTES/evidencias/fase03-* |

Sin cambios en `database/init`, `compose.yaml` ni los PDF originales. No hubo migración ni recreación del volumen. Las maquetas antiguas permanecen separadas y no alimentan operaciones reales.

## 4. Funcionalidades implementadas

- **Público/autenticación:** catálogo real, búsqueda literal preparada, registro siempre comprador, duplicado controlado, sesiones con ID regenerado, cookies HttpOnly/SameSite, expiración y salida por POST. Cuenta inactiva rechazada y sesiones existentes revocadas por baja o cambio de contraseña. Rol consultado en cada petición.
- **Comprador:** IDs/cantidades en sesión, actualización/eliminación, totales servidor, compra con FOR UPDATE y orden de bloqueo, descuento y factura/detalles atómicos; comprobación de propietario en consulta e historial. POST repetido tras compra no duplica factura.
- **Vendedor:** listado propio, alta y edición con propietario tomado del servidor; validación de nombre/descripcion/precio/stock. Imágenes auténticas hasta 2 MB y límites de dimensiones, recodificadas a PNG fuera de public.
- **Administrador:** métricas reales, CRUD de productos y usuarios, roles/estado y contraseñas nuevas con hash. Usuario referenciado se desactiva; producto eliminado conserva los detalles históricos vía FK SET NULL. No puede quitarse su propio acceso administrativo.
- **Protecciones:** mysqli parametrizado, escape HTML, CSRF en todo POST, rutas explícitas, raíz pública, errores 4xx/503 controlados, límites de acceso compartidos entre procesos, secretos/sesiones/subidas excluidos de Git.

Límites de validación documentados: contraseña nueva 12–72 bytes, carrito hasta 20 productos distintos/999 unidades por producto, precio hasta 999999.99, stock hasta 999999; imágenes <=4096 px por lado y <=16 millones de píxeles. No se agregaron pagos, envíos ni módulos ajenos al alcance.

## 5. Instrucciones exactas de ejecución

En la copia local existente, con `.env` y volumen conservados:

```powershell
Set-Location 'C:\Users\aleja\Desktop\TiendaLab_Documentos_Codex'
& 'C:\Program Files\Docker\Docker\resources\bin\docker.exe' compose up -d --wait --wait-timeout 180
.\scripts\iniciar-frontend.ps1
```

Abrir http://127.0.0.1:8000/. PHP necesita mysqli, mbstring, fileinfo y gd; el launcher habilita las DLL del PHP portátil local. Credenciales ficticias de seed en README/BASE_DE_DATOS: cinco cuentas con `TiendaLab-Demo-2026!`, distinta de las claves SQL locales. Ctrl+C detiene PHP. No ejecutar de nuevo preparar-entorno.php si ya existe .env; no borrar volumen.

Suite reproducible:

```powershell
.\scripts\verificar-backend.ps1
```

Inicia y detiene sus propios procesos: 8010/8011 para concurrencia, 8012 con conexión SQL deliberadamente no disponible. Usa la base existente mediante el usuario app, crea fixtures con prefijo aleatorio, captura estado previo por hash y limpia solo esos registros. Si hay manifest pendiente aborta antes de crear otros datos. Los comandos de recuperación están distinguidos como recomendaciones en la guía.

Regresión visual histórica: iniciar `iniciar-frontend.ps1 -Prototipo -Port 8000` y `-SinPrototipo -Port 8002` en terminales separadas; luego `verificar-frontend.ps1`. Los resultados de Ubuntu no están incluidos: no se ejecutó allí.

## 6. Pruebas y evidencias reales

Entorno: Windows, PHP 8.3 portátil y Node, MariaDB 11.4.13 en Docker Desktop con bind 127.0.0.1:3306. Todas las pruebas son locales, con cuentas/datos ficticios.

| Evidencia en REPORTES/evidencias/ | Resultado observado |
| --- | --- |
| fase03-sesiones-y-backend.txt | **107 HTTP/BD aprobadas**, 8 PHP, 3 JS, sintaxis de 52 archivos PHP, dos rollback y limpieza con SHA-256 idéntico |
| fase03-backend-final.txt | Ejecución previa: 106 HTTP/BD, antes de añadir el rechazo explícito de ID de sesión no inicializado |
| fase03-primer-intento.txt | Primera implementación: 104 HTTP/BD y rollback/limpieza aprobados |
| fase03-regresion-frontend.txt | **55 HTTP**, 11 pantallas, 14 assets, enlaces, cabeceras, rutas negativas y factura de maqueta; también 8 PHP y 3 JS |
| fase03-regresion-contrato-anterior.txt | Fallo conservado por expectativa demasiado estricta de Cache-Control; corregida sin debilitar la aplicación |
| fase03-base-preservada.txt | **24 comprobaciones originales** de cuentas, hashes, relaciones, totales, restricciones y privilegios SQL aprobadas después de operaciones backend |
| fase03-*.jpg | Revisión visual Edge: catálogo, login, comprador, carrito, factura real del seed, vendedor y administración |

La suite HTTP no se limita a códigos de respuesta: consulta MariaDB para comprobar rol/hash de registro, stock, dueño real, precio/IVA/total, cantidad de líneas, eliminación/desactivación y preservación de referencias. Ejecuta accesos cruzados entre compradores y vendedores, token CSRF incorrecto, parámetros manipulados, cambio de contraseña/rol/inactividad sobre sesiones ya abiertas, archivos falsos/grandes y un error SQL de conexión controlado.

**Concurrencia:** dos sesiones en dos procesos PHP intentaron la última unidad; una obtuvo factura y otra stock insuficiente. Stock final cero y un único detalle para esa unidad.

**Rollback:** una compra modificó el primer producto y falló por existencias del segundo; otra encontró un bloqueo SQL real y produjo error MariaDB 1205 después del primer UPDATE. Se comprobó stock restaurado y número de facturas sin cambios. No se añadió ningún modo de fallo accesible desde HTTP a la aplicación.

**Preservación:** cleanup comparó SHA-256 de todas las filas previas antes/después, incluido seed, y aprobó. Los autoincrementos pueden tener huecos por pruebas y rollback; no se reiniciaron. La revisión visual no confirmó compras del seed: solo agregó al carrito de sesión, consultó factura 4 y cerró sesión.

## 7. Problemas encontrados y soluciones

1. La prueba antigua exigía Cache-Control exactamente no-store. session_start añade no-cache/must-revalidate: se cambió el test para exigir la presencia de no-store, sin retirar las otras protecciones. Fallo original conservado.
2. Las imágenes del seed contienen /assets/img/...; el primer adaptador esperaba solo basename y mostraba la marca genérica. Se observó en Edge, se corrigió la lista de rutas aceptadas y se añadió una prueba, sin modificar los productos.
3. Una comprobación de cookies usaba every() y podía pasar con lista vacía. Se sustituyó por verificación de una cookie realmente emitida a un cliente nuevo y una prueba adicional de strict mode. La última suite tiene 107 comprobaciones.
4. El servidor PHP integrado de Windows atiende una solicitud a la vez por proceso. Para una prueba concurrente real se usaron dos procesos independientes contra la misma MariaDB, además de un proceso CLI que mantuvo un bloqueo SQL.

## 8. Pendientes

- Auditoría externa de esta fase antes de autorizar fase 4.
- Introducir únicamente las dos debilidades aprobadas en fase 4; actualmente factura protegida y 8081 inexistente.
- Ubuntu/Apache, red y firewall de VM, conexiones desde otro equipo y despliegue offline en fase 5.
- Cronometraje de instalación limpia, impresión/exportación PDF efectiva, diálogo nativo de selección de imagen y revisión móvil completa.
- HTTPS y comportamiento de Secure bajo HTTPS, expiración tras esperar 8 horas y pruebas de carga/seguridad más amplias no ejecutadas. Los controles temporales y Secure condicionado están implementados, sin atribuirles resultados no observados.

No quedan funciones básicas de fase 3 declaradas como simulaciones: las escrituras requeridas se probaron por HTTP y SQL. Los pendientes anteriores corresponden a validación adicional o fases posteriores.

## 9. Desviaciones respecto de los PDF

No se cambian tecnologías, arquitectura, roles, funcionalidades ni las dos vulnerabilidades elegidas. No fue necesario alterar el esquema. El backend conserva la disposición y recursos visuales originales, sustituyendo avisos/borradores por formularios reales.

Las imágenes subidas se guardan como PNG recodificado fuera de public para evitar ejecución; el límite y formatos de entrada aprobados se mantienen. Las bajas lógicas respetan las FK existentes. Los límites de tamaño/cantidad y protección del acceso administrativo son controles de validación, no módulos nuevos. El encabezado de factura consulta nombre/correo actuales del comprador; los detalles sí conservan nombre/precio de producto históricos, como permite el modelo existente.

El uso temporal de PHP integrado en Windows es la comprobación local, no sustituye el despliegue Apache/Ubuntu pendiente.

## 10. Estado final y GitFlow

Implementación y comprobaciones completas en `feature/fase-03-backend`, desde develop actualizada. Commits descriptivos conservados:

| Commit | Módulo |
| --- | --- |
| edf2df6 | Conexión mysqli, sesiones, autenticación y controles |
| 930319b | Transacciones, gestión y tratamiento de imágenes |
| 942eb79 | Rutas/vistas/formularios reales, estilos y launcher |
| 9fd70ce | Pruebas, fixtures aislados, evidencias y regresión |
| 4d28092 | Cookie nueva, strict mode y suite final de 107 comprobaciones |

La documentación y la mejora final del test de sesiones se añaden en commits posteriores. La rama se publica y se integra mediante PR real hacia develop después de las pruebas; el enlace y merge se registran en el cierre de publicación. Sin force push ni cambios en main o visibilidad. **Detenerse al completar esta entrega; no iniciar fases 4 ni 5.**
