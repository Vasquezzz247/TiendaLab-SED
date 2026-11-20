# Fase 6 — Auditoría final

Fecha: 19/11/2026. Autorizada por el usuario en la conversación (sin prompt externo). No se cambiaron tecnologías, arquitectura ni las vulnerabilidades elegidas. La fase 7 (entrega) no se inició.

## 1. Objetivo

Comprobar que todo lo implementado funciona en el despliegue real (Ubuntu + Apache + PHP + MariaDB en Docker), que solo existen las dos vulnerabilidades aprobadas, y corregir los problemas que aparezcan.

## 2. Requisitos cubiertos

| Requisito | Estado |
| --- | --- |
| Todas las vistas y los tres roles | Revisión visual (móvil y escritorio) + suite de 120 pruebas, en Windows y en Ubuntu |
| Registro, login, compras, stock, facturas, CRUD, autorizaciones | 120/120 contra la tienda en Ubuntu/Apache |
| Docker y MariaDB, Apache y Ubuntu, puertos | `verificar.sh` 34/34; puertos medidos en fase 5 |
| Las dos vulnerabilidades y ninguna otra deliberada | Auditoría estática + pruebas de acotamiento + auditoría dinámica de cabeceras |
| Instalación y reinicio | Repetición idempotente 3 min 39 s; reinicio con 32/32 (fase 5) |
| Consistencia PDF ↔ sistema | Sin desviaciones; ver sección 9 |

## 3. Archivos creados y modificados

`scripts/verificar-ubuntu.ps1` (nuevo); `tests/backend.test.cjs` (acepta 403/404 en rutas bloqueadas); `deploy/apache/tiendalab.conf` (nosniff en `/assets`); `scripts/ubuntu/verificar.sh` (34 comprobaciones); README, `docs/INSTALACION_UBUNTU.md`, matriz, guía (sección 23); evidencias `REPORTES/evidencias/fase06-*.txt`.

## 4. Funcionalidades implementadas

- **`verificar-ubuntu.ps1`**: ejecuta la suite de 120 pruebas contra la tienda de la VM (HTTP por el reenvío NAT, SQL de los datos de prueba por un túnel SSH que escucha solo en 127.0.0.1; la clave SQL se lee de la VM y no se imprime), con datos aislados y limpieza con SHA-256 del seed de la VM.
- **Corrección de Apache**: `X-Content-Type-Options: nosniff` en los archivos estáticos.

## 5. Instrucciones exactas de ejecución

Con la VM encendida (ver `docs/INSTALACION_UBUNTU.md`): `.\scripts\verificar-ubuntu.ps1`; en la VM: `sudo bash scripts/ubuntu/verificar.sh`. En Windows: `.\scripts\verificar-backend.ps1`.

## 6. Pruebas y evidencias reales

| Prueba | Resultado | Evidencia |
| --- | --- | --- |
| Suite HTTP/BD contra Ubuntu/Apache | **120/120**, rollbacks, limpieza con SHA-256 idéntico | fase06-suite-contra-ubuntu.txt |
| Suite en Windows | **120/120**, 8 PHP, 3 JS | fase06-regresion-windows.txt |
| `verificar.sh` en la VM (configuración final) | **34/34** | fase06-verificacion-final-ubuntu.txt |
| Auditoría estática | 2 marcas de debilidad (A y B); 0 SQL concatenado; 0 funciones peligrosas | fase06-auditoria-estatica.txt |
| Archivos estáticos en Apache | 15/15 con 200, tipos correctos, sin listado de directorios; `nosniff` único tras la corrección | (comandos en la guía, sección 23) |
| Repetición de `instalar.sh` | 3 min 39 s, `.env` y volumen idénticos | (registro de la VM) |
| Revisión visual en navegador (375 px y escritorio) | Sin errores de consola ni desbordes; 3 roles | (sin capturas versionadas) |

## 7. Problemas encontrados y soluciones

1. **Estáticos sin `nosniff`** (equivale a la debilidad «Content-Type» no elegida): corregido en `tiendalab.conf`.
2. **`nosniff` duplicado** en las páginas PHP al corregir lo anterior, detectado por la suite: el encabezado se limitó a `/assets` y `verificar.sh` exige una sola aparición.
3. **Pruebas ligadas al servidor de desarrollo** (404 en lugar del 403 de Apache): pruebas ajustadas a «bloqueado» (403 o 404) sin contenido sensible.
4. **Rutas de `curl` con barras invertidas** y otros detalles de PowerShell 5.1 ya corregidos en los scripts.
5. **Tablas en móvil** más anchas que la pantalla (UX menor): **no corregido**; se desplazan dentro de su contenedor.

## 8. Pendientes

- Prueba desde **otro equipo real** del Laboratorio 4 y confirmar cómo se conecta la VM a esa red.
- Confirmar con el docente si los 30 minutos cuentan desde la VM vacía (instalar Ubuntu tardó ~25 min en la red de pruebas).
- Impresión de una factura a PDF, otros navegadores, HTTPS, expiración de sesión a las 8 h.
- Ajustar las tablas móviles si se quiere.
- Fase 7: README final con diagrama, rama `release/*` y PR a `main`, kit de entrega (ZIP, `offline/`, imagen de MariaDB, ISO), ensayo completo cronometrado, `.ova` e instantánea limpia.

## 9. Desviaciones respecto de los PDF

Ninguna en tecnologías, vistas, roles ni vulnerabilidades. Las pruebas de este proyecto son pruebas propias, no una prueba de penetración independiente; la auditoría estática es por patrones.

## 10. Estado final y GitFlow

Rama `feature/fase-06-auditoria`; commits de Samuel Garay (cuenta SrGaray, sin firma de Claude); PR hacia `develop` abierto al escribir este reporte (su número y merge quedan registrados en GitHub). Sin force push; `main` permanece en `98b499d`. **Exactamente dos vulnerabilidades deliberadas (A y B).** Detenerse para la auditoría externa antes de la fase 7.
