# Instalación de TiendaLab en Ubuntu Server 24.04 LTS (VirtualBox)

Guía paso a paso desde la creación de la máquina virtual hasta la tienda funcionando. Arquitectura de entrega: navegador → VM Ubuntu Server → Apache/PHP del sistema → MariaDB en Docker (solo `127.0.0.1:3306`). **Nada se despliega en la nube ni se expone a internet.**

> Lo marcado **(ejecutado)** se probó de verdad en una VM de VirtualBox con Ubuntu 24.04.5 el 19/11/2026; resultados en la sección 8 y en `REPORTES/evidencias/fase05-*.txt`. Lo marcado **(no ejecutado)** es una recomendación sin probar.

## 0. Qué necesitas

| Elemento | Detalle |
| --- | --- |
| Equipo anfitrión | VirtualBox 7.x, 4 GB de RAM libres, 30 GB de disco |
| ISO | `ubuntu-24.04.5-live-server-amd64.iso` (4,08 GB) de <https://releases.ubuntu.com/24.04/>; SHA-256 oficial `97f3d7ffb032c3eb3b23d2c8be9cc76e60c2c1f2c0146ba5ba9fe01cafae0fd8` |
| Proyecto | Clon de GitHub o el ZIP limpio (`scripts/exportar.ps1`, 2,6 MB) |
| **Kit sin internet (recomendado)** | Carpeta `offline/` con `debs/` (29 paquetes, 92 MB) y `tiendalab-mariadb.tar` (105 MB). Ver sección 6 |

## 1. Crear la máquina virtual

**Opción A, con el script (ejecutado)** (Windows): instalación desatendida con SSH y clave listos.

```powershell
.\scripts\vm\crear-vm.ps1 -Iso C:\ruta\ubuntu-24.04.5-live-server-amd64.iso -IsoSha256 97f3d7ffb032c3eb3b23d2c8be9cc76e60c2c1f2c0146ba5ba9fe01cafae0fd8
```

Crea la VM `TiendaLab-Ubuntu2404` (2 CPU, 3 GB, 30 GB), red NAT con reenvíos **solo a 127.0.0.1** (SSH 2222, web 8080, diagnóstico 18081) y red solo-anfitrión; genera contraseña y clave SSH en `Downloads\TiendaLab-VM` (fuera del repositorio). El usuario `tiendalab` recibe `sudo` sin contraseña: **solo es aceptable porque esta VM no tiene otro uso**.

> **Tiempo medido: la instalación del sistema tardó unos 25 minutos** en esta red, porque el instalador descarga las actualizaciones de seguridad desde servidores de Ubuntu que respondieron a ~50 kB/s. Es la parte más lenta de todo el proceso.
>
> **Estado del script:** la versión final de `crear-vm.ps1` (que instala `openssh-server` con `env DEBIAN_FRONTEND=...`) **no se ha ejecutado de principio a fin**; la VM de las pruebas se rescató a mano desde la consola del instalador (el SSH se instaló con un comando equivalente). Conviene repetir una instalación limpia con el script antes de depender de él.

**Opción B, a mano** (cualquier sistema, no ejecutada): VM Ubuntu 64-bit, 2 CPU, 3 GB, 30 GB; adaptador 1 NAT; instalar Ubuntu Server con el asistente, usuario `tiendalab`, **marcar «Install OpenSSH server»**.

## 2. Copiar el proyecto y el kit a la VM (ejecutado)

```powershell
$k="$HOME\Downloads\TiendaLab-VM\id_tiendalab"
scp -i $k -P 2222 dist\TiendaLab-<commit>-codigo.zip tiendalab@127.0.0.1:~/
ssh -i $k -p 2222 tiendalab@127.0.0.1 "python3 -m zipfile -e TiendaLab-<commit>-codigo.zip ."
scp -i $k -P 2222 -r offline\debs tiendalab@127.0.0.1:~/TiendaLab-SED/offline/
scp -i $k -P 2222 offline\tiendalab-mariadb.tar tiendalab@127.0.0.1:~/TiendaLab-SED/offline/
```

Copiar todo tardó 34 s. (En la VM también sirve `git clone https://github.com/Vasquezzz247/TiendaLab-SED.git`.)

## 3. Instalar con un solo comando (ejecutado)

```sh
cd ~/TiendaLab-SED && time sudo bash scripts/ubuntu/instalar.sh
```

**Medido: 4 min 54 s** sin internet. Instala Apache y PHP 8.3 del sistema (mysqli, mbstring, gd), Docker y UFW; despliega la tienda en `/var/www/tiendalab` con `public/` como raíz; crea el `.env` con secretos aleatorios; carga la imagen de MariaDB y la levanta publicada solo en loopback con el seed ficticio; publica el diagnóstico de laboratorio en el 8081; abre solo SSH, 80 y 8081; y ejecuta la verificación. Si la carpeta `offline/debs/` no existe, usa `apt` con internet (**ruta no completada en las pruebas**: se interrumpió porque el servidor de paquetes iba a 56 kB/s). Se puede repetir sin perder datos.

## 4. Verificar (ejecutado)

```sh
sudo bash scripts/ubuntu/verificar.sh      # 32 comprobaciones
sudo bash scripts/ubuntu/comprobar-red.sh  # puertos vistos desde la IP no-loopback de la VM
```

Resultado: **32 de 32** justo después de instalar y **32 de 32** después de reiniciar la VM (SSH de vuelta a los 83 s). Con la configuración final de Apache (nosniff también en los archivos estáticos) son **34 de 34**. Repetir `instalar.sh` sobre una VM ya instalada tardó **3 min 39 s**, conservó el `.env` y el volumen de MariaDB, y dio 34/34.

## 5. Usar la tienda

Desde el anfitrión: <http://127.0.0.1:8080/> (reenvío NAT). Cuentas ficticias (clave común `TiendaLab-Demo-2026!`): `admin@tiendalab.test`, `vendedor@tiendalab.test`, `ana@tiendalab.test`, `luis@tiendalab.test`, `carla@tiendalab.test`.

## 6. Cómo se preparó el kit sin internet (ejecutado manualmente)

Los servidores oficiales de Ubuntu respondieron a unos 50 kB/s desde esta red, pero un espejo (`mirror.us.leaseweb.net`) entregó 4,5 MB/s. Por eso los paquetes se descargaron en el anfitrión:

1. En la VM recién instalada (antes de instalar nada del proyecto): `sudo apt-get update` y `sudo apt-get install --print-uris -y -qq apache2 php8.3 libapache2-mod-php8.3 php8.3-mysql php8.3-mbstring php8.3-gd php8.3-cli docker.io docker-compose-v2 ufw curl rsync`. Da las 29 direcciones y su suma MD5 (calculada por `apt` desde un índice firmado).
2. En el anfitrión: descargar esas direcciones sustituyendo el servidor por el espejo rápido (`curl --parallel`, 92 MB en 13 s) y **verificar el MD5 de cada archivo** contra el de la VM (29 de 29 coinciden).
3. Copiar a la VM (sección 2). El instalador usa `dpkg -i ./*.deb` en esa carpeta.
4. La imagen de MariaDB: `scripts/exportar.ps1 -Offline` genera `tiendalab-mariadb.tar` con su SHA-256.

`scripts/ubuntu/preparar-offline.sh` automatiza una variante dentro de una Ubuntu con internet, pero **no se ha ejecutado**. Los `.deb` descargados corresponden al estado del archivo de Ubuntu del 19/11/2026: si el archivo cambia, hay que regenerar el kit.

## 7. Puertos y seguridad

| Puerto | Servicio | Alcance |
| --- | --- | --- |
| TCP/80 | Tienda (Apache) | Red del laboratorio |
| TCP/8081 | Diagnóstico ficticio (**vulnerabilidad B**) | Red del laboratorio, a propósito |
| TCP/3306 | MariaDB (Docker) | Solo `127.0.0.1` |
| TCP/22 | SSH | Administración |

Todo lo demás está denegado por UFW. **La VM nunca debe publicarse en internet ni abrirse puertos en el router.**

## 8. Resultados reales de esta guía (19/11/2026)

| Qué | Resultado |
| --- | --- |
| Sistema operativo | Ubuntu 24.04.5 LTS, kernel 6.8, Apache 2.4.58, PHP 8.3.6, Docker 29.1.3 (paquetes de Ubuntu) |
| Instalación del sistema con `crear-vm.ps1` | ~25 min (descarga de actualizaciones lenta) |
| `instalar.sh` sin internet | **4 min 54 s** |
| `verificar.sh` tras instalar / tras reiniciar / configuración final | **32/32**, **32/32** y **34/34** |
| Suite de 120 pruebas HTTP/BD (`scripts/verificar-ubuntu.ps1`) contra la tienda en Ubuntu | **120/120**: compra, concurrencia, rollback, imágenes, IDOR, CSRF, permisos; seed de la VM idéntico por SHA-256 |
| Repetir `instalar.sh` (idempotencia) | 3 min 39 s; `.env` y volumen idénticos |
| Reinicio de la VM | SSH de vuelta a los 83 s; Apache, Docker y MariaDB arrancan solos |
| Puertos vistos desde `10.0.2.15` (IP no-loopback de la VM) | 22, 80 y 8081 abiertos; 3306 cerrado |
| Desde el anfitrión por los reenvíos | `/login.php` 200 y diagnóstico 200, `Server: Apache` sin versión |

**No se probó:** acceso desde otro equipo real de la red del laboratorio (la prueba de puertos se hizo dentro de la VM), instalación con internet de principio a fin, impresión de facturas a PDF, otros navegadores, HTTPS. La compra completa, la edición de productos con imágenes y los permisos sí se ejercitaron en Ubuntu con la suite de 120 pruebas (fase 6).

## 9. Riesgos para el día de la entrega (30 minutos)

- **Instalar Ubuntu consume ~25 de los 30 minutos** si el instalador descarga actualizaciones por una red lenta. `instalar.sh` solo necesita ~5 min con el kit offline. Antes del viernes hay que confirmar con el docente si los 30 minutos empiezan con la VM vacía o con Ubuntu ya instalado, y considerar llevar la VM exportada (`.ova`, **no creada todavía**) o instalar Ubuntu sin actualizaciones.
- El kit sin internet debe viajar completo: ZIP del proyecto, `offline/debs/`, `tiendalab-mariadb.tar` y el ISO.
