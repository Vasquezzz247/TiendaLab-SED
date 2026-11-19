#!/usr/bin/env bash
# Instala TiendaLab en Ubuntu Server 24.04 LTS: Apache + PHP del sistema y MariaDB en Docker (solo loopback).
# Uso (desde la carpeta del proyecto ya descomprimida):   sudo bash scripts/ubuntu/instalar.sh
# Sin internet: coloca los .deb en offline/debs/ y la imagen en offline/tiendalab-mariadb.tar (ver README).
# Se puede ejecutar de nuevo sin perder datos: conserva .env, storage/ y el volumen de MariaDB.
set -euo pipefail

INICIO=$(date +%s)
[ "$(id -u)" -eq 0 ] || { echo "Ejecuta con sudo: sudo bash scripts/ubuntu/instalar.sh" >&2; exit 1; }
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP=/var/www/tiendalab
DIAG=/var/www/tiendalab-diagnostico
LOG=/var/log/tiendalab-instalacion.log
IMAGEN_OFFLINE_TAG="tiendalab-mariadb:11.4.13"
DEBS_DIR="${DEBS_DIR:-$SRC/offline/debs}"
TAR_OFFLINE="${TAR_OFFLINE:-$SRC/offline/tiendalab-mariadb.tar}"
export DEBIAN_FRONTEND=noninteractive

exec > >(tee -a "$LOG") 2>&1
paso() { echo; echo "[$(( $(date +%s) - INICIO )) s] $*"; }

. /etc/os-release
[ "${VERSION_ID:-}" = "24.04" ] || echo "AVISO: el proyecto se probo en Ubuntu 24.04; esta maquina es ${VERSION_ID:-desconocida}."
for f in app public database compose.yaml diagnostico deploy scripts/preparar-entorno.php; do
  [ -e "$SRC/$f" ] || { echo "Falta $f en $SRC: ejecuta el script desde el proyecto completo." >&2; exit 1; }
done

paso "1/7 Paquetes (Apache, PHP 8.3 con mysqli/mbstring/gd, Docker, UFW)"
if compgen -G "$DEBS_DIR/*.deb" > /dev/null; then
  echo "Modo sin internet: instalando desde $DEBS_DIR"
  (cd "$DEBS_DIR" && apt-get install -y --no-download ./*.deb)
else
  apt-get update -y
  apt-get install -y apache2 php8.3 libapache2-mod-php8.3 php8.3-mysql php8.3-mbstring php8.3-gd php8.3-cli \
    docker.io docker-compose-v2 ufw curl rsync
fi
systemctl enable --now docker

paso "2/7 Archivos de la aplicacion en $APP (raiz publica: public/)"
install -d -m 755 "$APP" "$APP/scripts" "$DIAG"
for dir in app public database; do rsync -a --delete "$SRC/$dir/" "$APP/$dir/"; done
install -m 644 "$SRC/compose.yaml" "$APP/compose.yaml"
install -m 644 "$SRC/scripts/preparar-entorno.php" "$APP/scripts/preparar-entorno.php"
install -m 644 "$SRC/diagnostico/index.html" "$DIAG/index.html"
chown -R root:root "$APP/app" "$APP/public" "$APP/database" "$APP/scripts" "$DIAG"
find "$APP/app" "$APP/public" "$APP/database" -type d -exec chmod 755 {} +
find "$APP/app" "$APP/public" "$APP/database" -type f -exec chmod 644 {} +
# storage/ (sesiones, limites de acceso e imagenes subidas) queda fuera de public/ y solo lo escribe www-data.
install -d -m 750 -o www-data -g www-data "$APP/storage" "$APP/storage/sessions" "$APP/storage/limits"

paso "3/7 Credenciales locales (.env con secretos aleatorios; nunca se sobrescribe)"
if [ -f "$APP/.env" ]; then
  echo ".env ya existe: se conserva."
else
  (cd "$APP" && php scripts/preparar-entorno.php)
fi
chown root:www-data "$APP/.env"
chmod 640 "$APP/.env"

paso "4/7 MariaDB en Docker (publicada solo en 127.0.0.1:3306)"
if [ -f "$TAR_OFFLINE" ] && ! docker image inspect "$IMAGEN_OFFLINE_TAG" > /dev/null 2>&1; then
  echo "Cargando la imagen desde $TAR_OFFLINE"
  docker load -i "$TAR_OFFLINE"
fi
if docker image inspect "$IMAGEN_OFFLINE_TAG" > /dev/null 2>&1; then
  grep -q '^MARIADB_IMAGE=' "$APP/.env" || echo "MARIADB_IMAGE=$IMAGEN_OFFLINE_TAG" >> "$APP/.env"
  PULL=never
else
  PULL=missing
fi
(cd "$APP" && docker compose up -d --pull "$PULL" --wait --wait-timeout 240)

paso "5/7 Apache: tienda (80) y diagnostico ficticio de laboratorio (8081)"
install -m 644 "$SRC/deploy/php/99-tiendalab.ini" /etc/php/8.3/apache2/conf.d/99-tiendalab.ini
install -m 644 "$SRC/deploy/php/99-tiendalab.ini" /etc/php/8.3/cli/conf.d/99-tiendalab.ini
install -m 644 "$SRC/deploy/apache/tiendalab-seguridad.conf" /etc/apache2/conf-available/tiendalab-seguridad.conf
install -m 644 "$SRC/deploy/apache/tiendalab.conf" /etc/apache2/sites-available/tiendalab.conf
install -m 644 "$SRC/deploy/apache/tiendalab-diagnostico.conf" /etc/apache2/sites-available/tiendalab-diagnostico.conf
a2enmod headers > /dev/null
a2enconf tiendalab-seguridad > /dev/null
a2dissite 000-default > /dev/null 2>&1 || true
a2ensite tiendalab tiendalab-diagnostico > /dev/null
apache2ctl configtest
systemctl enable apache2
systemctl restart apache2

paso "6/7 Firewall (UFW): solo SSH, 80 y 8081; el 3306 no se abre"
ufw default deny incoming > /dev/null
ufw default allow outgoing > /dev/null
ufw allow 22/tcp > /dev/null
ufw allow 80/tcp > /dev/null
ufw allow 8081/tcp > /dev/null
ufw --force enable > /dev/null
ufw status | sed -n '1,12p'

paso "7/7 Verificacion"
if [ -x "$SRC/scripts/ubuntu/verificar.sh" ] || [ -f "$SRC/scripts/ubuntu/verificar.sh" ]; then
  bash "$SRC/scripts/ubuntu/verificar.sh" || { echo "ATENCION: la verificacion fallo; revisa $LOG" >&2; exit 2; }
fi

TOTAL=$(( $(date +%s) - INICIO ))
echo
echo "Instalacion completada en $(( TOTAL / 60 )) min $(( TOTAL % 60 )) s."
echo "Tienda: http://<IP de la VM>/   Cuentas de prueba: README.md   Registro: $LOG"
