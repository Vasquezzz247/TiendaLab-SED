#!/usr/bin/env bash
# Comprueba una instalacion de TiendaLab en Ubuntu (se ejecuta dentro de la VM, con sudo).
# Imprime PASS/FAIL por comprobacion y termina con codigo 1 si alguna falla. No modifica datos de forma permanente.
set -uo pipefail
APP=/var/www/tiendalab
BASE=http://127.0.0.1
FALLOS=0
TOTAL=0
ok()   { TOTAL=$((TOTAL+1)); echo "PASS: $TOTAL $1"; }
fallo(){ TOTAL=$((TOTAL+1)); FALLOS=$((FALLOS+1)); echo "FAIL: $TOTAL $1"; }
comprueba() { if eval "$2"; then ok "$1"; else fallo "$1"; fi; }
codigo() { curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$@"; }

comprueba "Apache activo" "systemctl is-active --quiet apache2"
comprueba "Docker activo" "systemctl is-active --quiet docker"
comprueba "contenedor MariaDB saludable" "[ \"\$(docker inspect -f '{{.State.Health.Status}}' tiendalab-db-1 2>/dev/null)\" = healthy ]"

# Puertos: 80 y 8081 en todas las interfaces; 3306 solo en loopback.
ESCUCHA=$(ss -ltnH)
comprueba "TCP/80 escucha en todas las interfaces" "echo \"\$ESCUCHA\" | grep -qE '(^|[[:space:]])(\\*|0\\.0\\.0\\.0|\\[::\\]):80[[:space:]]'"
comprueba "TCP/8081 escucha en todas las interfaces (vulnerabilidad B)" "echo \"\$ESCUCHA\" | grep -qE '(^|[[:space:]])(\\*|0\\.0\\.0\\.0|\\[::\\]):8081[[:space:]]'"
comprueba "TCP/3306 escucha solo en 127.0.0.1" "echo \"\$ESCUCHA\" | grep -E ':3306[[:space:]]' | grep -q '127\\.0\\.0\\.1:3306' && ! echo \"\$ESCUCHA\" | grep -E ':3306[[:space:]]' | grep -qE '(\\*|0\\.0\\.0\\.0|\\[::\\]):3306'"
comprueba "firewall activo y sin regla para 3306" "ufw status | grep -q 'Status: active' && ! ufw status | grep -q '3306'"

# Tienda
comprueba "catalogo (/) responde 200" "[ \"\$(codigo $BASE/)\" = 200 ]"
comprueba "login responde 200" "[ \"\$(codigo $BASE/login.php)\" = 200 ]"
# OJO: no usar "curl | grep -q" con pipefail: grep -q sale en la primera coincidencia, curl recibe SIGPIPE y la tuberia
# cuenta como fallo aunque el texto este (fallaba ~2 de cada 10 veces). Con <(curl ...) el estado de curl no cuenta.
comprueba "catalogo muestra productos de MariaDB" "grep -q 'Audífonos' <(curl -s $BASE/)"
comprueba "sin sesion /carrito.php redirige al login" "[ \"\$(codigo $BASE/carrito.php)\" = 303 ]"
comprueba "sin sesion /admin-usuarios.php redirige al login" "[ \"\$(codigo $BASE/admin-usuarios.php)\" = 303 ]"
for ruta in /prototipo/index.php /app/web.php /storage/ /database/init/01-schema.sql /.env /compose.yaml; do
  comprueba "no se sirve $ruta" "c=\$(codigo $BASE$ruta); [ \"\$c\" = 404 ] || [ \"\$c\" = 403 ]"
done
CAB=$(curl -sI $BASE/login.php)
comprueba "cabecera Server sin version" "echo \"\$CAB\" | grep -i '^server:' | grep -qiv '[0-9]'"
comprueba "sin cabecera X-Powered-By" "! echo \"\$CAB\" | grep -qi '^x-powered-by'"
comprueba "cabecera nosniff presente una sola vez (sin duplicar)" "[ \"\$(echo \"\$CAB\" | grep -ci '^x-content-type-options:')\" = 1 ] && echo \"\$CAB\" | grep -qi '^x-content-type-options: nosniff'"
comprueba "archivos estaticos (CSS/JS) con nosniff y tipo correcto" "h=\$(curl -sI $BASE/assets/css/styles.css); echo \"\$h\" | grep -qi '^x-content-type-options: nosniff' && echo \"\$h\" | grep -qi '^content-type: text/css'"
comprueba "sin listado de directorios en /assets/" "c=\$(codigo $BASE/assets/); [ \"\$c\" = 403 ] || [ \"\$c\" = 404 ]"

# Login real con una cuenta ficticia del seed (solo lecturas) y CSRF.
JAR=$(mktemp); trap 'rm -f "$JAR"' EXIT
TOKEN=$(curl -s -c "$JAR" $BASE/login.php | grep -o 'name="csrf" value="[a-f0-9]*"' | head -1 | sed 's/.*value="//;s/"//')
comprueba "token CSRF presente en el formulario de login" "[ -n \"\$TOKEN\" ]"
comprueba "login con CSRF invalido rechazado (403)" "[ \"\$(codigo -b $JAR -c $JAR -d 'correo=ana@tiendalab.test&password=x&csrf=malo' $BASE/login.php)\" = 403 ]"
comprueba "login de Ana (comprador) correcto: 303 a /" "[ \"\$(codigo -b $JAR -c $JAR --data-urlencode 'correo=ana@tiendalab.test' --data-urlencode 'password=TiendaLab-Demo-2026!' -d \"csrf=\$TOKEN\" $BASE/login.php)\" = 303 ]"
comprueba "historial de Ana accesible con sesion" "[ \"\$(codigo -b $JAR $BASE/historial.php)\" = 200 ]"
comprueba "vendedor.php rechazado para un comprador (403)" "[ \"\$(codigo -b $JAR $BASE/vendedor.php)\" = 403 ]"

# PHP como www-data usando solo el usuario SQL de la aplicacion.
CUENTA=$(sudo -u www-data php -r "require '$APP/app/database.php'; echo row('SELECT CURRENT_USER() AS u')['u'];" 2>/dev/null)
comprueba "PHP (www-data) consulta MariaDB con el usuario tiendalab_app (${CUENTA:-sin conexion})" "echo \"\$CUENTA\" | grep -q '^tiendalab_app@'"
comprueba ".env legible solo por root y www-data (640)" "[ \"\$(stat -c '%a %U:%G' $APP/.env)\" = '640 root:www-data' ]"
comprueba "storage/ escribible por www-data y fuera de public" "sudo -u www-data test -w $APP/storage && [ ! -e $APP/public/storage ]"

# Diagnostico ficticio (vulnerabilidad B)
comprueba "diagnostico (8081) responde 200 con datos ficticios" "grep -q 'todos los datos de esta página son ficticios' <(curl -s http://127.0.0.1:8081/)"
comprueba "diagnostico rechaza POST (403)" "[ \"\$(codigo -X POST -d a=b http://127.0.0.1:8081/)\" = 403 ]"
comprueba "la tienda no enlaza el 8081" "! grep -q '8081' <(curl -s $BASE/)"

echo
echo "TOTAL: $((TOTAL-FALLOS)) de $TOTAL comprobaciones aprobadas en Ubuntu."
[ "$FALLOS" -eq 0 ]
