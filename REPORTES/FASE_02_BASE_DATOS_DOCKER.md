# Fase 02 — Base de datos y Docker

Fecha: 18/11/2026. Rama: feature/fase-02-base-datos. Autorización: correcciones de auditoría de fase 1 y fase 2, sin iniciar fase 3.

## 1. Objetivo

Corregir el entorno HTTP del prototipo y preparar una base relacional reproducible, persistente y limitada al host para TiendaLab. Probar con Docker disponible sin conectar formularios ni construir backend web.

## 2. Requisitos cubiertos

Definición pp. 1-4: soporte de datos para roles/productos/facturas, stack permitido y documentación. Propuesta pp. 1-4: MariaDB Docker, mysqli desde host, conexión loopback; pp. 6-11: fixtures de usuarios/productos/facturas. Matriz R19 implementado, R20 binding local comprobado con red Ubuntu pendiente, R28 cuentas en base con login pendiente, R32 exportación de imagen con instalación offline pendiente, R35 guía actualizada. No se implementaron R08 (compra), R21/R22 (vulnerabilidades).

## 3. Archivos creados y modificados

- compose.yaml, .env.example; .env local ignorado con secretos no versionados.
- database/init/01-schema.sql, 02-seed.sql, 03-permisos.sql.
- scripts/preparar-entorno.php, generar-seed.php, verificar-base.ps1; tests/database.test.php.
- scripts/router.php; iniciar-frontend.ps1 y tests/http.test.cjs actualizados por auditoría.
- docs/BASE_DE_DATOS.md; matriz, alcance, guía de defensa, README y AGENTS actualizados.
- REPORTES/CORRECCIONES_FASE_01.md, este reporte y evidencias/fase02-frontend.txt, fase02-base.txt, fase02-final.txt, fase02-mariadb.log.txt.
- tmp/tiendalab-mariadb.tar: exportación local ignorada; no se sube a Git. PDF originales sin cambios.

## 4. Funcionalidades implementadas

Cuatro tablas InnoDB con PK/FK, correo único, roles, checks, dinero DECIMAL y columnas calculadas; propietario vendedor/comprador, snapshot de nombre/precio en líneas. 5 usuarios ficticios con bcrypt, 9 productos, 4 facturas y 7 detalles. IVA 13 %, total histórico 459.50. Ana tiene 1/3/4 y Luis 2. Usuario SQL de aplicación limitado a CRUD; root interno. Imagen oficial fijada por digest, healthcheck, volumen persistente y puerto 127.0.0.1:3306. Test CLI mysqli separado de la aplicación.

Router explícito de desarrollo: ruta inexistente=404, en lugar de aceptar como acceso un catálogo de respaldo HTTP 200. No se añadieron rutas finales ni servicios de diagnóstico.

## 5. Cómo ejecutar y comprobar

Desde la raíz, con Docker Desktop iniciado y PHP disponible:

```powershell
# Solo la primera vez; se niega a sobrescribir .env:
& .\tools\php\php.exe scripts/preparar-entorno.php
& 'C:\Program Files\Docker\Docker\resources\bin\docker.exe' compose up -d --wait
.\scripts\verificar-base.ps1
```

El generador ya se ejecutó en esta copia. No regenerar secretos sobre un volumen inicializado. Revisión frontend: scripts/iniciar-frontend.ps1 y segunda instancia -SinPrototipo -Port 8002, luego verificar-frontend.ps1. La alternativa PHP directa debe incluir `scripts/router.php`. Detener base con compose stop db, no eliminar volumen. Guía completa y comandos Linux recomendados en docs/BASE_DE_DATOS.md.

## 6. Pruebas reales y evidencias

| Prueba | Resultado |
| --- | --- |
| Compose config --quiet | Correcto antes y después de fijar digest |
| Inicialización automática | Contenedor Healthy, base/seed/permisos cargados |
| Tablas y datos | 4 tablas, 4 FK, 5 usuarios, 9 productos, 4 facturas, 7 detalles |
| Hashes y relaciones | Cinco password_verify correctos; Ana 1/3/4 y Luis 2 |
| Importes | Detalles coinciden con subtotales; factura 4=83.61; total=459.50 |
| Restricciones y permisos | Siete cambios inválidos rechazados y CREATE TABLE denegado a app |
| mysqli desde host | Conexión real PHP Windows; prepare/bind/execute/get_result y UTF-8 correctos |
| Reinicio y recreación | Marcador modificado sobrevivió a ambos; luego restaurado |
| Publicación del puerto | Docker inspect/compose port: solo 127.0.0.1:3306; Get-NetTCPConnection confirma escucha local |
| Suite BD | 24 comprobaciones aprobadas en cada ejecución, incluida última con digest fijado |
| HTTP con router en Windows | 53 comprobaciones aprobadas, 8 PHP y 3 tests JS |
| Sintaxis PHP nuevos | Sin errores en scripts/tests nuevos |
| Offline | Exportación tar real de imagen, 105682432 bytes, SHA256 en fase02-final.txt |

Docker Engine 28.3.0 / Compose 2.38.1 / MariaDB 11.4.13. Digest: sha256:5e73baf8179b29f115101bb102763a47a017361f3e9792daccba6646c3ab1532. Las salidas completas y logs limitados se conservan en los cuatro archivos de evidencia. La guía de seguridad enumera comandos exactos en orden; tests/database.test.php conserva el SQL de las comprobaciones.

No se ejecutaron PHP sobre Ubuntu/Linux, Apache, conexiones desde otra computadora, docker load en VM ni instalación sin internet. MariaDB corre en contenedor Linux de Docker Desktop; eso no acredita la VM Ubuntu de entrega. No se ejecutó nueva prueba visual de archivos o impresión.

## 7. Problemas y soluciones

La auditoría detectó fallback del servidor PHP integrado en Linux. Se documentó su causa, añadió router explícito y conservó el test 404; no se confundió catálogo con recurso restringido. Corregida referencia a product-form.php en matriz.

Docker no estaba en PATH, pero sí disponible en ruta de Docker Desktop. Se usó esa ruta sin instalar otro motor. La imagen emitió avisos de memory.pressure no escribible e io_uring deshabilitado; usa libaio y queda Healthy. No se cambiaron permisos del host ni se ocultaron avisos. Se sustituyó el tag flotante inicial por el digest realmente descargado para reproducibilidad.

## 8. Pendientes o bloqueos

Login/roles web, sesiones, operaciones mysqli de la aplicación, transacciones comerciales, subida segura de imágenes y todas las funcionalidades de fase 3 esperan autorización. La coherencia entre subtotal y líneas y la validez del rol del propietario requerirán lógica de servidor; las pruebas del seed no sustituyen esa implementación.

Selección/previsualización de archivo nuevo y exportación PDF siguen pendientes de revisión visual; se revisó código y se mantuvo la limitación previa. Pruebas Linux del router y Apache pendientes. Configuración de red/VM y paquetes para laboratorio offline quedan en fase 5. No se creó ni integró PR remoto de esta fase.

## 9. Posibles incumplimientos

Ninguna sustitución del stack: solo MariaDB en Docker; tests PHP CLI no son backend. Credenciales administrativas aleatorias locales; cuentas de demo públicas y separadas. .env y tar ignorados. No IDOR, diagnóstico 8081, SQLi u otra vulnerabilidad deliberada añadida. Los campos activo y snapshots soportan historial sin borrado accidental; la política del CRUD debe respetar FK en fase 3.

La inspección local de puertos no garantiza por sí sola aislamiento de una VM futura. No se declara instalación menor a 30 minutos. No se afirma exportación de factura probada.

## 10. Estado final

**COMPLETADA para fase 2 en Windows/Docker Desktop**, con límites de plataforma y pruebas visuales pendientes expresamente registrados. Correcciones de fase 1 implementadas y comprobadas por HTTP local. Detenido antes de fase 3. Rama local existente conservada; cambios preparados mediante commits reales, sin integración remota de esta fase. La base y el volumen permanecen disponibles localmente para revisión; el frontend continúa usando fixtures.
