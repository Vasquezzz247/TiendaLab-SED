# TiendaLab

Tienda académica de tecnología con **PHP puro, mysqli y MariaDB**, sin frameworks, ORM, CDN ni servicios en nube. El diseño de fase 1 ahora permite operaciones reales de laboratorio.

**Estado: fase 3 implementada e integrada en develop mediante [PR #7](https://github.com/Vasquezzz247/TiendaLab-SED/pull/7); fases 4 y 5 no iniciadas.** Registro/login, sesiones, tres roles, carrito, compra transaccional, facturas y gestión funcionan contra MariaDB. Las facturas comprueban propietario; no existe el servicio 8081. La integración y las pruebas están en [FASE_03_BACKEND.md](REPORTES/FASE_03_BACKEND.md).

Repositorio [TiendaLab-SED](https://github.com/Vasquezzz247/TiendaLab-SED), **público por autorización previa**. Los PDF originales contienen nombres y carnets académicos; la documentación incluye rutas locales. Se conservan íntegros y su información es públicamente accesible. `.env`, sesiones, imágenes subidas, herramientas y temporales no se publican.

## Ejecutar en esta computadora

Requisitos disponibles y utilizados: Docker Desktop con Compose, PHP 8.3 portátil y extensiones **mysqli, mbstring, fileinfo y gd**. Node solo se necesita para las pruebas, no para servir la aplicación. No cambies ni regeneres el `.env` existente ni el volumen de MariaDB.

Desde PowerShell:

```powershell
Set-Location 'C:\Users\aleja\Desktop\TiendaLab_Documentos_Codex'
& 'C:\Program Files\Docker\Docker\resources\bin\docker.exe' compose up -d --wait --wait-timeout 180
.\scripts\iniciar-frontend.ps1
```

Abre [TiendaLab local](http://127.0.0.1:8000/). El nombre del script se conserva por compatibilidad: ahora inicia la aplicación real con las extensiones requeridas. Escucha solo en loopback. `Ctrl+C` detiene PHP. Si el puerto está ocupado usa `-Port 8015`. Detener la base sin borrar datos: `docker compose stop db`. **No usar `down -v`, `volume rm` ni volver a ejecutar el seed.**

En una copia nueva sin `.env`, ejecutar **una sola vez** antes de Compose:

```powershell
& .\tools\php\php.exe scripts/preparar-entorno.php
```

Genera dos secretos aleatorios locales y se niega a sobrescribir el archivo. PHP usa exclusivamente `DB_PASSWORD` para `tiendalab_app`, nunca la clave root. Las variables de inicialización no cambian contraseñas de un volumen existente. Consultar [base de datos](docs/BASE_DE_DATOS.md).

PHP portátil no está versionado. En otra instalación se necesita PHP 8.3 con mysqli, mbstring, fileinfo y gd; el directorio `storage/` fuera de `public/` debe ser escribible por PHP. Se crea localmente para sesiones, límites e imágenes. La instalación en Ubuntu/Apache se realizará en fase 5: no está ejecutada ni certificada todavía.

## Cuentas ficticias del seed

Contraseña pública de demostración para las cinco cuentas: `TiendaLab-Demo-2026!`. **No es una contraseña administrativa SQL.** Úsalas únicamente en el laboratorio; no introduzcas contraseñas personales.

| Correo | Rol |
| --- | --- |
| admin@tiendalab.test | Administrador |
| vendedor@tiendalab.test | Vendedor |
| ana@tiendalab.test | Comprador |
| luis@tiendalab.test | Comprador |
| carla@tiendalab.test | Comprador |

Los nuevos registros públicos siempre son compradores. La contraseña nueva admite 12–72 bytes. El login admite cinco intentos por correo y 60 por dirección de conexión en una ventana de 15 minutos; solo cuentan los intentos fallidos (un acceso correcto devuelve su intento y reinicia el contador del correo). El límite se comparte entre cookies y procesos locales. Una cuenta inactiva no puede entrar. Las sesiones caducan por 30 minutos de inactividad o a las 8 horas; logout las destruye.

## Uso y rutas reales

| Ruta | Acceso y operación |
| --- | --- |
| `/` | Catálogo de MariaDB y búsqueda pública; comprador puede agregar cantidades |
| `/register.php` | Registro comprador con correo único y hash |
| `/login.php`, `/logout.php` | Autenticación y salida por POST protegido |
| `/carrito.php` | Comprador: modificar/quitar y confirmar compra |
| `/historial.php` | Comprador: solo sus facturas |
| `/factura.php?id=...` | Comprador: autenticación **y propiedad**; impresión del documento |
| `/vendedor.php` | Alta, listado y edición solo de productos propios |
| `/admin-productos.php` | Administrador: métricas, alta/edición/baja de productos |
| `/admin-usuarios.php` | Administrador: altas/edición/roles/activación/baja de usuarios |
| `/imagen.php?id=...` | Sirve únicamente PNG procesados, sin ejecutar archivos |

Carrito en sesión PHP: solo ID/cantidad, hasta 20 productos y 999 unidades por producto. No reserva existencias. Al confirmar, una transacción bloquea las filas, relee precios y stock, descuenta, inserta factura y detalles y confirma todo o revierte todo. IVA 13 %, importes en centavos/DECIMAL. No hay procesamiento de pagos.

El vendedor no puede elegir otro propietario. Las imágenes nuevas son JPG/PNG/WEBP auténticas, hasta 2 MB, 4096 px por lado y 16 millones de píxeles; se recodifican a PNG y guardan fuera de la raíz web. En edición puede conservarse la imagen anterior.

Eliminar un usuario sin referencias lo borra; si tiene productos o facturas se desactiva. La baja de un producto conserva el nombre/precio histórico de sus detalles y deja `producto_id` NULL. El administrador no puede eliminarse ni quitarse su propio acceso. Un vendedor con productos activos no puede cambiar de rol: el administrador debe retirarlos o reasignarlos antes (los productos retirados conservan su dueño histórico). Las claves foráneas permanecen activas. No se añadió ninguna tabla ni migración.

## Pruebas reproducibles

Con MariaDB iniciada:

```powershell
.\scripts\verificar-backend.ps1
```

El script inicia sus propios servidores en 8010/8011 y uno de error controlado en 8012; exige puertos libres y los detiene al terminar. Crea datos ficticios con prefijo exclusivo, prueba por HTTP y SQL, verifica compra concurrente con dos procesos PHP, provoca rollback real y limpia solo sus fixtures. Compara SHA-256 de todas las filas previas antes/después, incluido el seed; no reinicia el volumen. Los autoincrementos pueden dejar huecos después de las pruebas: no se reinician para aparentar un historial sin pruebas.

Si una ejecución interrumpida deja `tmp/fase03-fixtures.json`, revisar primero su estado; no lanzar otra preparación encima. La limpieza recuperable está documentada en la guía. No ejecutar el verificador de fase 2 contra una base con compras propias esperando los conteos originales del seed.

Para revisar las maquetas históricas sin confundirlas con permisos reales, iniciar en dos terminales:

```powershell
.\scripts\iniciar-frontend.ps1 -Prototipo -Port 8000
.\scripts\iniciar-frontend.ps1 -SinPrototipo -Port 8002
```

Y en otra: `.\scripts\verificar-frontend.ps1`. Las maquetas solo se habilitan por opción explícita y loopback; sus POST siguen rechazados. La aplicación real funciona sin JavaScript salvo mejoras visuales e impresión.

## Arquitectura y carpetas

```text
Desarrollo comprobado: navegador → PHP Windows → mysqli → MariaDB Docker (127.0.0.1:3306)
Entrega prevista fase 5: navegador autorizado → VM Ubuntu Server 24.04 → Apache/PHP host
                                                              → MariaDB Docker loopback
Fase 4 pendiente: diagnóstico ficticio independiente en 8081
```

```text
public/                 Única raíz web; rutas reales y assets locales
app/web.php             Rutas, roles, POST/CSRF, redirecciones y errores controlados
app/database.php        Configuración mysqli y validación de entradas
app/auth.php            Sesiones, autenticación, registro y límites
app/shop.php            Carrito, compras transaccionales y propiedad de facturas
app/management.php      Gestión de productos y usuarios con integridad referencial
app/images.php          Validación, recodificación y rutas de imágenes
app/views/live/         Vistas reales con el diseño y componentes compartidos
app/views/, demo/       Maquetas históricas aisladas, sin participar en operaciones reales
storage/                Sesiones, límites e imágenes privadas del host; ignorado por Git
compose.yaml            Solo MariaDB: digest, salud, puerto local y volumen persistente
database/init/          Esquema, seed ficticio y privilegios del usuario SQL
scripts/, tests/        Inicio, comprobaciones y datos aislados de pruebas
REPORTES/, docs/        Evidencias, alcance, requisitos y defensa
```

## Documentación y próximos pasos

- [Guía de seguridad y defensa](docs/GUIA_SEGURIDAD_Y_DEFENSA.md): controles, comandos reales, pruebas y límites; fase 3 en secciones 16–17.
- [Matriz](docs/MATRIZ_REQUISITOS.md), [alcance](docs/ALCANCE.md), [base](docs/BASE_DE_DATOS.md).
- [GitFlow](docs/GITFLOW.md) y [estado del remoto](REPORTES/ESTADO_GITFLOW.md).
- [Reporte fase 3](REPORTES/FASE_03_BACKEND.md), [cierre fase 2](REPORTES/CIERRE_FASE_02_GITFLOW.md), reportes históricos de fases 0/1.

Detenerse para auditoría antes de fase 4. Pendientes: las dos vulnerabilidades aprobadas, Ubuntu/Apache/red/firewall, prueba desde otro equipo, instalación offline y cronometraje, impresión/PDF efectiva y revisión móvil completa. Nada de ello se presenta como ejecutado. `main` sigue reservada para entrega; esta fase se integra únicamente a `develop` mediante PR real.
