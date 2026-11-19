#!/usr/bin/env bash
# Prepara los archivos para instalar TiendaLab SIN internet. Se ejecuta UNA VEZ en una Ubuntu 24.04 con internet
# (la VM de pruebas sirve). Genera, dentro del proyecto (carpeta offline/, ignorada por Git):
#   offline/debs/                 los .deb de Apache, PHP, Docker, UFW... con TODAS sus dependencias
#   offline/tiendalab-mariadb.tar la imagen de MariaDB (si ya esta descargada en Docker)
#   offline/SHA256SUMS.txt        sumas de comprobacion
# Despues copia el proyecto completo (con offline/) a la maquina sin internet y ejecuta scripts/ubuntu/instalar.sh.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecuta con sudo." >&2; exit 1; }
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DESTINO="$SRC/offline"
PAQUETES="apache2 php8.3 libapache2-mod-php8.3 php8.3-mysql php8.3-mbstring php8.3-gd php8.3-cli docker.io docker-compose-v2 ufw curl rsync"
export DEBIAN_FRONTEND=noninteractive

install -d "$DESTINO/debs"
rm -f "$DESTINO"/debs/*.deb
apt-get update -y
# Cierre de dependencias (sin recomendados) de cada paquete; --reinstall obliga a descargar tambien los ya instalados.
CIERRE=$(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances $PAQUETES \
  | grep '^[a-z0-9]' | sort -u)
# shellcheck disable=SC2086
apt-get install -y --reinstall --download-only -o Dir::Cache::archives="$DESTINO/debs" $CIERRE 2>&1 | tail -3 || true
rm -f "$DESTINO/debs/lock"; rm -rf "$DESTINO/debs/partial"

if docker image inspect tiendalab-mariadb:11.4.13 > /dev/null 2>&1; then
  docker save --output "$DESTINO/tiendalab-mariadb.tar" tiendalab-mariadb:11.4.13
elif [ -f "$SRC/compose.yaml" ] && docker image ls --format '{{.Repository}}@{{.Digest}}' | grep -q '^mariadb@'; then
  IMG=$(grep -o 'mariadb@sha256:[0-9a-f]\{64\}' "$SRC/compose.yaml" | head -1)
  docker tag "$IMG" tiendalab-mariadb:11.4.13
  docker save --output "$DESTINO/tiendalab-mariadb.tar" tiendalab-mariadb:11.4.13
else
  echo "AVISO: no hay imagen de MariaDB en Docker; genera el tar con scripts/exportar.ps1 -Offline en el anfitrion."
fi

(cd "$DESTINO" && find . -type f \( -name '*.deb' -o -name '*.tar' \) -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS.txt)
echo "Listo: $(ls "$DESTINO/debs" | wc -l) paquetes .deb, $(du -sh "$DESTINO" | cut -f1) en $DESTINO"
