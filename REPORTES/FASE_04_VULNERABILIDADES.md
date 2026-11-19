# Fase 4 — vulnerabilidades controladas

Fecha: 19/11/2026. Autorizada por el usuario en la conversación (no hubo un prompt externo de fase 4): siguió la propuesta aprobada, sin cambiar arquitectura, tecnologías ni vulnerabilidades elegidas. La fase 5 (Ubuntu/despliegue) no se inició.

## 1. Objetivo

Atender las observaciones A, B y C de la auditoría de fase 3, implementar **exclusivamente** las dos vulnerabilidades aprobadas (IDOR en `factura.php?id=` y diagnóstico ficticio en TCP/8081), conservar las demás protecciones, ejecutar regresión y documentar cada debilidad con su reproducción y su mitigación.

## 2. Requisitos cubiertos

| Requisito | Estado |
| --- | --- |
| Observación A (límite de login contaba accesos correctos) | Corregida, [PR #9](https://github.com/Vasquezzz247/TiendaLab-SED/pull/9) |
| Observación B (cambio de rol de vendedor con productos) | Corregida, [PR #10](https://github.com/Vasquezzz247/TiendaLab-SED/pull/10) |
| Observación C (exportaciones limpias) | Corregida, [PR #11](https://github.com/Vasquezzz247/TiendaLab-SED/pull/11) |
| R21 / vulnerabilidad A: IDOR solo en la propiedad de la factura, con sesión | Implementada y probada, [PR #12](https://github.com/Vasquezzz247/TiendaLab-SED/pull/12) |
| R22 / vulnerabilidad B: diagnóstico ficticio independiente en 8081 | Implementada y probada con Apache en contenedor, [PR #13](https://github.com/Vasquezzz247/TiendaLab-SED/pull/13) |
| R23: reproducibles, documentadas, con mitigación | Guía de seguridad, secciones 20 y 21 |
| Exactamente dos vulnerabilidades, sin otras deliberadas | Pruebas de acotamiento en ambas (ver sección 6) |

## 3. Archivos creados y modificados (solo fase 4; las observaciones A–C están en sus PR)

| Archivo | Cambio |
| --- | --- |
| `app/shop.php`, `app/web.php` | `buyer_invoice()` → `invoice_detail()` sin `AND comprador_id`; comentario `VULNERABILIDAD A` |
| `diagnostico/index.html` | Página estática del panel con datos inventados |
| `deploy/apache/tiendalab-diagnostico.conf` | VirtualHost 8081 (debilidad aprobada) con instalación y mitigación |
| `tests/backend.test.cjs` | Prueba de factura ajena invertida y 6 de acotamiento (120 en total) |
| `tests/diagnostico.test.cjs`, `tests/apache-harness.conf`, `scripts/verificar-diagnostico.ps1` | 24 comprobaciones contra Apache 2.4 en contenedor |
| `README.md`, `AGENTS.md`, `docs/ALCANCE.md`, `docs/MATRIZ_REQUISITOS.md`, `docs/GUIA_SEGURIDAD_Y_DEFENSA.md` | Estado, R21/R22, secciones 20 y 21 |
| `REPORTES/evidencias/fase04-idor-reproduccion.txt`, `fase04-diagnostico-8081.txt` | Evidencia real |

Sin cambios en el esquema, `database/init` ni `compose.yaml`. No se modificó `main`.

## 4. Funcionalidades implementadas

- **A. IDOR:** la consulta individual de facturas no comprueba propietario. Siguen intactos sesión y rol comprador, historial por usuario, id entero y consulta preparada (sin SQLi), permisos de productos/usuarios y compra transaccional.
- **B. Diagnóstico 8081:** sitio estático independiente (sin PHP/CGI/SSI, sin `.htaccess` ni listado, solo GET/HEAD/OPTIONS), escucha en todas las interfaces sin restricción por IP, sin enlace desde la tienda, con `nosniff`, `Content-Type` UTF-8 y `Server` sin versión. Todos los datos son ficticios, incluida la clave `Diag#Ficticia-2026` del anexo.

## 5. Instrucciones exactas de ejecución

Con MariaDB iniciada y `.env` presente (Windows, ya comprobado):

```powershell
.\scripts\verificar-backend.ps1        # 120 HTTP/BD + 8 PHP + 3 JS + rollbacks + concurrencia
.\scripts\verificar-diagnostico.ps1    # 24 comprobaciones; levanta Apache 2.4 en contenedor solo en 127.0.0.1:8081
```

Notas de entorno detectadas (Windows PowerShell 5.1 no interactivo): crear `tmp/` si falta; `Invoke-WebRequest` necesita `-UseBasicParsing` (se forzó con `$PSDefaultParameterValues`); el verificador del backend espera un PHP portátil en `tools/php/`; el límite de login se acumula 15 minutos por IP en `storage/limits`. La reproducción manual de A se hizo con un script HTTP (login como Ana, `GET /factura.php?id=2`). La instalación del diagnóstico en Ubuntu está descrita en el encabezado de `deploy/apache/tiendalab-diagnostico.conf` y **no se ejecutó**.

## 6. Pruebas y evidencias reales

Entorno: Windows 11, PHP 8.3, Node 26, MariaDB 11.4 en Docker Desktop, Apache 2.4.71 en contenedor `httpd:2.4`.

| Prueba | Resultado |
| --- | --- |
| `verificar-backend.ps1` (con A integrada) | **120 HTTP/BD aprobadas**, 8 PHP, 3 JS, 2 rollbacks (stock insuficiente y error SQL 1205 real), concurrencia, sintaxis de 52 archivos, limpieza con SHA-256 idéntico del seed |
| Regresión del frontend (`verificar-frontend.ps1`, servidores 8000/8002) | **55 HTTP**, 8 PHP, 3 JS aprobados |
| `verificar-diagnostico.ps1` | **24 aprobadas**, `httpd -t: Syntax OK` |
| Reproducción de A con el seed (`fase04-idor-reproduccion.txt`) | Ana ve en su historial las facturas 4, 3, 1; `factura.php?id=2` muestra «Luis Hernández, luis@tiendalab.test, $145.77» |
| Acotamiento de A | Sin sesión → 303; vendedor → 403; administrador → 403; id inexistente → 404; `OR 1=1` → 422 (no es SQLi); `comprador_id` forjado se ignora |
| Acotamiento de B | POST/PUT/DELETE → 403; `/index.php`, `/cgi-bin/test`, `/.htaccess`, `/phpinfo.php` → 404; recorridos `../` rechazados; sin listado; sin versión en `Server`; la página no contiene hostname, usuario, IP ni claves reales de esta máquina; la tienda no menciona el 8081 |

Estado de la base tras toda la regresión: 5 usuarios, 9 productos, 4 facturas, 7 detalles (seed intacto). No se repitió `verificar-base.ps1` de fase 2 (modifica temporalmente un dato del seed); se ejecutó al inicio de este trabajo, antes de cualquier prueba con compras, con 24 comprobaciones aprobadas y persistencia tras reinicio y recreación del contenedor. Tras cada corrida de la suite del backend la limpieza comprobó el SHA-256 idéntico de todas las filas previas.

## 7. Problemas encontrados y soluciones

1. **Charset ausente:** Apache devolvía `text/html` sin `charset`. La prueba lo detectó; se añadió `AddDefaultCharset UTF-8`.
2. **POST devolvía 200:** `Require all granted` y `<LimitExcept>` se mezclaban. Se puso cada permiso en su propio `<Limit>`/`<LimitExcept>`; ahora 403.
3. **Scripts de PowerShell 5.1:** `Mount` es un alias de `New-PSDrive` y tapaba mi función; el stderr de `docker run/inspect` y de `httpd -t` cortaba el script con `ErrorActionPreference=Stop`. Se renombró la función y se aisló cada llamada.
4. **Comando accidental:** una línea de mi comando de regresión invocó `verificar-base.ps1`, que modifica un dato del seed. Abortó en `compose up` antes de tocar la base; se verificó que Carla y los conteos están intactos.
5. **Tope del límite de login** acumulado entre corridas (resuelto antes con la observación A: solo cuentan los fallos).

## 8. Pendientes

- **Fase 5:** VM Ubuntu 24.04, Apache y PHP del sistema, Docker solo para MariaDB, instalación del diagnóstico en Apache real, firewall, comprobación del 8081 desde **otro equipo** de la red del laboratorio (`nmap`), MariaDB solo en loopback, cronometraje de instalación, paquetes offline de Ubuntu.
- Pruebas no ejecutadas: Ubuntu/Apache del sistema, red del laboratorio, impresión/PDF de facturas, compatibilidad móvil completa, HTTPS, expiración de sesión a las 8 h, `docker load` en máquina limpia.
- Fase 6 (auditoría final) y fase 7 (README final, release a `main`).
- Auditoría externa de esta fase antes de continuar.

## 9. Desviaciones respecto de los PDF

Ninguna en tecnologías, roles, vistas ni vulnerabilidades elegidas. Aclaraciones: (a) la fase 4 se autorizó por chat sin prompt escrito; (b) Apache 2.4 en contenedor se usó **solo como arnés de pruebas** de la configuración, la arquitectura de entrega sigue siendo Apache directo en Ubuntu y MariaDB como único contenedor; (c) el panel del 8081 se implementó como página estática, sin PHP, para garantizar que no ofrece operaciones ni lee datos reales; (d) la mala configuración de `Content-Type` es una opción de la definición oficial que **no** se eligió, por lo que no se introdujo.

## 10. Estado final y GitFlow

| Rama / PR | Contenido | Estado |
| --- | --- | --- |
| `feature/fase-04-idor-facturas` → [PR #12](https://github.com/Vasquezzz247/TiendaLab-SED/pull/12) | IDOR (commit `34fc58b`) | Fusionado en `develop`, merge `4b475d6` |
| `feature/fase-04-diagnostico-8081` → [PR #13](https://github.com/Vasquezzz247/TiendaLab-SED/pull/13) | Diagnóstico 8081 (commit `821154c`) y este reporte | Abierto al escribir este reporte; su merge queda registrado en la página del PR |

Commits y PR #9–#11 de las observaciones A–C: `00e562d`, `70c0e41`, `05e0621` y `85f9f4d`; merges `1bbd54c`, `d232af7`, `0af08d6`. Todos con identidad Samuel Garay (cuenta SrGaray), sin force push ni reescritura, y `main` permanece en `98b499d`. **No hay vulnerabilidades adicionales deliberadas.** Detenerse para la auditoría externa antes de la fase 5.
