# Fase 5 — Ubuntu Server, Apache y despliegue

Fecha: 19/11/2026. Autorizada por el usuario en la conversación (sin prompt externo), siguiendo la propuesta aprobada: VM Ubuntu Server 24.04 LTS, Apache y PHP del sistema, MariaDB en Docker solo en loopback. No se contenerizó la aplicación ni se cambió ninguna tecnología. Las fases 6 y 7 no se iniciaron.

## 1. Objetivo

Preparar y **probar en una VM real** el despliegue de entrega: instalación con un solo comando, Apache y PHP del sistema, MariaDB en Docker (loopback), firewall, diagnóstico del 8081, verificación automática, reinicio, y medir el tiempo de instalación.

## 2. Requisitos cubiertos

| Requisito | Estado |
| --- | --- |
| R18: VM Ubuntu Server 24.04 y Apache en el host | Probado en VM real de VirtualBox (Ubuntu 24.04.5, Apache 2.4.58, PHP 8.3.6) |
| R19/R20: MariaDB en Docker, solo `127.0.0.1:3306` | Probado: `ss`, `docker port` y puerto 3306 cerrado desde la IP no-loopback |
| R22: diagnóstico 8081 en Apache | Instalado y respondiendo en Apache real (sección 6); **desde otro equipo: no probado** |
| R27: instalación reproducible | `instalar.sh` sin internet: **4 min 54 s**; ver el riesgo de los 30 minutos (sección 8) |
| R32: dependencias sin internet | Kit de 29 `.deb` + imagen de MariaDB: instalación sin internet comprobada |
| README con instalación paso a paso | README y `docs/INSTALACION_UBUNTU.md` |

## 3. Archivos creados y modificados

`scripts/vm/crear-vm.ps1`, `scripts/ubuntu/instalar.sh`, `verificar.sh`, `comprobar-red.sh`, `preparar-offline.sh`; `deploy/apache/tiendalab.conf`, `tiendalab-seguridad.conf`; `deploy/php/99-tiendalab.ini`; `docs/INSTALACION_UBUNTU.md`; README, matriz (R18, R20, R27, R32), guía de seguridad (sección 22); `.gitignore` (`/offline/`); evidencias `REPORTES/evidencias/fase05-*.txt`. No se tocaron el esquema, `compose.yaml` ni el código de la aplicación.

## 4. Funcionalidades implementadas

- **Instalador de un comando**, idempotente: paquetes (con o sin internet), aplicación en `/var/www/tiendalab` con raíz `public/`, `.env` aleatorio 640 `root:www-data`, `storage/` de `www-data`, MariaDB en Docker con la imagen del kit, Apache (tienda en 80, diagnóstico en 8081), UFW (22, 80, 8081), verificación.
- **`verificar.sh`**: 32 comprobaciones (servicios, puertos, cabeceras, rutas ocultas, login con CSRF, permisos, conexión PHP→MariaDB).
- **`crear-vm.ps1`**: VM de VirtualBox con instalación desatendida, NAT con reenvíos a 127.0.0.1 y clave SSH fuera del repositorio.

## 5. Instrucciones exactas de ejecución

Ver `docs/INSTALACION_UBUNTU.md`. En síntesis (Windows → VM): copiar el ZIP (`scripts/exportar.ps1`) y el kit `offline/` a `~/TiendaLab-SED` y ejecutar `sudo bash scripts/ubuntu/instalar.sh`, luego `sudo bash scripts/ubuntu/verificar.sh`.

## 6. Pruebas y evidencias reales

Entorno: VirtualBox 7.2.8 sobre Windows 11; VM Ubuntu 24.04.5 (2 CPU, 3 GB, 30 GB, NAT). Datos y cuentas ficticios.

| Prueba | Resultado | Evidencia |
| --- | --- | --- |
| `instalar.sh` sin internet (29 `.deb` + imagen) | **4 min 54 s**, 32/32 | fase05-instalacion-sin-internet.txt |
| Reinicio de la VM + `verificar.sh` | SSH a los 83 s; **32/32**; datos de MariaDB conservados | fase05-verificacion-tras-reinicio.txt |
| Puertos desde `10.0.2.15` (IP no-loopback) | 22, 80, 8081 abiertos; 3306 cerrado; MariaDB solo en 127.0.0.1 | fase05-red.txt |
| Desde Windows por reenvíos NAT | `/login.php` 200; diagnóstico 200; `Server: Apache` sin versión | fase05-red.txt |
| Descarga de 29 paquetes en el anfitrión | 91,8 MB en 13 s; **29/29 MD5 verificados** | (sección 7 de INSTALACION_UBUNTU.md) |
| Intento fallido conservado | apt con `--no-download` rechaza `.deb` locales | fase05-intento-fallido-apt.txt |

Medidas de velocidad hacia servidores de Ubuntu desde esta red: `sv.archive.ubuntu.com` ~56 kB/s; `archive.ubuntu.com` ~50 kB/s; `mirror.us.leaseweb.net` ~4,5 MB/s; `mirrors.edge.kernel.org` ~1,6 MB/s.

## 7. Problemas encontrados y soluciones

1. **Sin SSH tras la instalación desatendida**: el `user-data` de VirtualBox no incluye `ssh:`. Se añadió `openssh-server` al post-instalación.
2. **Post-instalación fallida**: la plantilla ejecuta `log_command <texto>`; un primer comando `VAR=valor` devuelve 127. Corregido con `env VAR=valor`. La VM de pruebas se rescató a mano desde la consola del instalador (sin contraseñas).
3. **Contraseña de la VM**: se comprobó que la generada coincide con el hash guardado por el instalador; el `Login incorrect` venía del teclado. Se resolvió con SSH por clave y `sudo` sin contraseña (solo aceptable por ser una VM de laboratorio).
4. **Servidores de Ubuntu muy lentos desde esta red** (~50 kB/s): paquetes descargados en el anfitrión desde un espejo rápido y verificados por MD5.
5. **`apt` ignoraba los `.deb` locales** (con y sin `--no-download`): el instalador usa `dpkg -i`.
6. **Instantánea en vivo colgó la VM**: hubo que terminar los procesos de VBoxHeadless y reiniciar VBoxSVC/VBoxSDS (con autorización del usuario). **No se tomó ninguna instantánea.** Un servidor de otro proyecto del usuario se levantó brevemente por error (puerto 8765) y se detuvo de inmediato.
7. Errores de PowerShell 5.1 (progreso de VBoxManage por stderr, comillas y barras invertidas en los argumentos) corregidos en los scripts.

## 8. Pendientes

- **Riesgo de los 30 minutos**: la instalación de Ubuntu tardó ~25 min en esta red (descarga de actualizaciones) y el instalador ~5 min. Confirmar con el docente si el tiempo cuenta desde la VM vacía; considerar llevar una VM exportada (`.ova`, no creada) o instalar Ubuntu sin actualizaciones.
- Prueba desde **otro equipo real** de la red del Laboratorio 4 (`nmap`), y cómo se conecta la VM a esa red.
- Instalación **con internet** de principio a fin; `crear-vm.ps1` final y `preparar-offline.sh` sin ejecutar completos; `.ova` e instantánea limpia.
- Flujo completo de compra, edición de productos e imágenes **sobre Ubuntu** (solo login, permisos y lectura se verificaron allí; el flujo completo está cubierto por las 120 pruebas en Windows).
- Impresión de facturas, HTTPS y expiración de sesión a las 8 h.
- Fase 6 (auditoría final) y fase 7 (README final, release a `main`).

## 9. Desviaciones respecto de los PDF

Ninguna en tecnologías, arquitectura ni vulnerabilidades. Aclaraciones: ISO de **Ubuntu 24.04.5** (descargado; el 26.04 que había en el equipo no se usó); la VM de pruebas usa `sudo` sin contraseña y huellas SSH no fijadas solo para el reenvío a `127.0.0.1` de esa VM; el kit sin internet se descargó de un espejo distinto del oficial por velocidad y se verificó por MD5 contra el índice de la VM.

## 10. Estado final y GitFlow

Rama `feature/fase-05-despliegue-ubuntu`, con commits de Samuel Garay (cuenta SrGaray, sin firma de Claude): `fa50ed8`, `9ec01d3`, `2bccbcb`, `7282bb3`, `fd951a7` y el de documentación y evidencias de este reporte. PR hacia `develop` abierto al escribir este reporte; su número y merge quedan registrados en GitHub. Sin force push; `main` permanece en `98b499d`. **No hay vulnerabilidades adicionales deliberadas.** Detenerse para la auditoría externa antes de la fase 6.
