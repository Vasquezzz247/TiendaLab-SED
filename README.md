# TiendaLab

Repositorio público (cambio autorizado posteriormente): https://github.com/Vasquezzz247/TiendaLab-SED. El frontend integrado está en `develop`; `main` se reserva para entrega estable. Ver [estado actualizado de GitFlow](REPORTES/ESTADO_GITFLOW.md). Las menciones a remoto pendiente más abajo corresponden al cierre histórico de fase 1.

Proyecto universitario de **Seguridad en Entornos de Desarrollo**. Tienda de tecnología con comprador, vendedor y administrador, según la definición oficial y la propuesta de los PDF de esta carpeta.

**Estado actual: fase 1 corregida y fase 2 implementada y probada en Windows/Docker Desktop.** MariaDB está disponible; todavía no hay autenticación, compra real, CRUD web persistente, despliegue Ubuntu ni vulnerabilidades. Los prototipos de roles son vistas aisladas; no son paneles finales sin autenticación. No avanzar a fase 3 sin autorización.

## Ver la interfaz en esta computadora

PHP portátil ya está disponible en `tools/php/php.exe` en esta copia local. No se instala como servicio ni cambia el PATH. Abre PowerShell y ejecuta:

```powershell
Set-Location 'C:\Users\aleja\Desktop\TiendaLab_Documentos_Codex'
.\scripts\iniciar-frontend.ps1
```

Abre [TiendaLab local](http://127.0.0.1:8000/) en Edge u otro navegador. “Revisar pantallas” abre el índice de prototipos. Deja la terminal abierta mientras revisas; **Ctrl+C** detiene el servidor. Si 8000 ya está ocupado, usa `-Port 8010` y abre esa dirección.

Alternativa equivalente, sin ejecutar un archivo `.ps1` ni cambiar políticas de PowerShell:

```powershell
Set-Location 'C:\Users\aleja\Desktop\TiendaLab_Documentos_Codex'
$env:TIENDALAB_PROTOTIPO = '1'
& '.\tools\php\php.exe' -S 127.0.0.1:8000 -t public scripts/router.php
```

No abras los `.php` con doble clic ni uses la raíz del proyecto como DocumentRoot. El servidor integrado es solo para revisar el frontend local; Apache sigue siendo el servidor de entrega.

Si copias el repositorio a otro equipo, el intérprete portátil no estará incluido porque es una herramienta local ignorada por Git. Puedes usar PHP 8.3 instalado y accesible como `php`, o descargar la versión x64 NTS desde la [fuente oficial de PHP](https://www.php.net/downloads.php?os=windows&version=8.3), extraerla en `tools/php/` y comprobar `php.exe -v`. Las dependencias de ejecución de Windows se detallan en esa página. El sitio no usa dependencias externas una vez iniciado.

## Pantallas y funcionamiento actual

| Ruta local | Qué puedes revisar |
| --- | --- |
| `/` | Catálogo, 9 productos, buscador y acceso público |
| `/login.php` | Correo y contraseña; aviso de autenticación pendiente |
| `/register.php` | Nombre, correo, contraseña y confirmación; comprador fijo |
| `/prototipo/` | Índice de revisión, no selector de sesión |
| `/prototipo/?vista=comprador` | Cantidades, agregar al carrito de muestra |
| `/prototipo/?vista=carrito` | Cambiar/quitar, subtotal, IVA 13 %, total |
| `/prototipo/?vista=factura` | Documento ficticio, detalle e imprimir/PDF |
| `/prototipo/?vista=historial` | Tres facturas ficticias de Ana |
| `/prototipo/?vista=vendedor` | Alta y edición visual, formulario de imagen |
| `/prototipo/?vista=admin-productos` | Resumen, tabla, nuevo/editar/eliminar con avisos |
| `/prototipo/?vista=admin-usuarios` | Alta/edición visual, selección de rol y avisos |

El carrito se guarda temporalmente en la pestaña con sessionStorage; no crea sesión de usuario ni reserva stock. “Cargar ejemplo del anexo” coloca audífonos y cámara: $73.99 + $9.62 = **$83.61**. Confirmar explica que no se realizó la compra; no genera la factura. Los formularios validan datos ficticios y no envían información al servidor. Los cambios de roles y edición son borradores, sin permisos ni persistencia.

Los prototipos requieren `TIENDALAB_PROTOTIPO=1` y una conexión loopback. Para probar su cierre:

```powershell
.\scripts\iniciar-frontend.ps1 -SinPrototipo -Port 8002
```

Con ese servidor, `/prototipo/` debe responder **404**. Las páginas públicas continúan disponibles. No hay cuentas ni contraseñas válidas de prueba en fase 1.

## Comprobar el resultado

Necesitas PHP y Node para las pruebas; Node no se usa al servir la tienda. Inicia las dos instancias anteriores (8000 con prototipos y 8002 sin ellos) en terminales separadas y, en una tercera terminal en la raíz, ejecuta:

```powershell
.\scripts\verificar-frontend.ps1
```

Comprueba sintaxis de las 22 plantillas/archivos PHP de aplicación, escape y guardia local en PHP, cantidades y centavos en JavaScript, 11 pantallas, enlaces, recursos locales, cabeceras y rutas negativas por HTTP. Las pruebas reales y sus límites están en el [reporte de fase 1](REPORTES/FASE_01_FRONTEND.md); las capturas y salida de pruebas están en `REPORTES/evidencias/`.

La selección de archivos desde la automatización del navegador no pudo completarse por el permiso de acceso a archivos de la extensión. Se puede revisar manualmente seleccionando una imagen ficticia JPG/PNG/WEBP de hasta 2 MB; la previsualización no sube el archivo. La impresión está implementada con CSS y `window.print`; aún no se exportó un PDF ni se verificó una impresora.

## Arquitectura final y estructura

```text
Navegador autorizado → red del laboratorio → VM Ubuntu Server 24.04
  Apache :80 → PHP puro / mysqli → MariaDB Docker (127.0.0.1:3306)
  Apache :8081 → diagnóstico ficticio independiente (fase 4)
```

Apache y PHP estarán instalados en Ubuntu; solo la base se ejecutará en Docker. No se desplegará en nube. El sitio usa HTML5, CSS3 y JavaScript nativo, sin framework, librerías web, ORM, CDN ni llamadas externas.

```text
app/bootstrap.php         Cabeceras, escape y renderizado común
app/components/          Cabecera, pie, tarjetas, tablas y formularios
app/views/               Contenido de cada pantalla
demo/datos.php           Fixtures ficticios, separados del futuro backend
public/                  Única raíz web
public/prototipo/        Punto de entrada de maquetas locales
public/assets/           CSS, JS y SVG de iniciales como en el anexo
scripts/                 Inicio y verificación de frontend Windows
tests/                   Pruebas PHP, JS y HTTP sin librerías adicionales
docs/                    Alcance, matriz, GitFlow y seguridad/defensa
REPORTES/                Reportes por fase y evidencia real
tmp/                     Extracciones PDF y temporales ignorados
tools/php/               Intérprete local ignorado por Git
```

## Documentación y defensa

- [Alcance y análisis de las capturas](docs/ALCANCE.md).
- [Matriz de requisitos](docs/MATRIZ_REQUISITOS.md).
- [Guía de seguridad y defensa](docs/GUIA_SEGURIDAD_Y_DEFENSA.md): controles actuales, comandos ejecutados, Apache/PHP/sesiones/roles/BD/Docker/red previstos y cómo explicarlos.
- [GitFlow](docs/GITFLOW.md): `main`, `develop` y ramas feature locales; sin remoto ni PR aún.
- [Reporte fase 0](REPORTES/FASE_00_PREPARACION.md) y [reporte fase 1](REPORTES/FASE_01_FRONTEND.md).

## Pendiente para la entrega final

Fase 2 completada localmente: SQL, MariaDB/Compose y volumen; ver documentación de base. Fase 3: sesiones, autenticación, roles, mysqli, CRUD, transacciones, stock y facturas reales. Fase 4: únicamente IDOR de propiedad en factura autenticada y diagnóstico ficticio 8081. Fase 5: instalación Ubuntu/Apache, red autorizada, scripts de servicio y alternativa offline. Fase 6: pruebas funcionales y auditoría. Fase 7: README final, GitHub/PR, evidencias y simulación de instalación cronometrada.

Entrega prevista: **27/11/2026**, Laboratorio 4, máximo 30 minutos de instalación. No se ha medido una instalación real ni se afirma cumplir ese tiempo. Pruebas del ejercicio: 30/11 y 01/12/2026, únicamente en los objetivos y horarios autorizados. Red de la VM y posibilidad de llevarla preconfigurada siguen pendientes de instrucciones del docente.

## Base de datos (fase 2)

Ver [modelo, cuentas ficticias, comandos y traslado offline](docs/BASE_DE_DATOS.md), [reporte fase 2](REPORTES/FASE_02_BASE_DATOS_DOCKER.md) y [correcciones de auditoría](REPORTES/CORRECCIONES_FASE_01.md). No conectar todavía el frontend a la base.

En PowerShell, desde esta carpeta:

```powershell
# Solo si .env no existe:
& .\tools\php\php.exe scripts/preparar-entorno.php
& 'C:\Program Files\Docker\Docker\resources\bin\docker.exe' compose up -d --wait
.\scripts\verificar-base.ps1
```

La base usa 127.0.0.1:3306 y el volumen tiendalab_db_data. Detener sin borrar datos: `docker compose stop db`; iniciar: `docker compose start db`. El seed solo se aplica al volumen nuevo. No ejecutar down -v. Las menciones anteriores a BD pendiente son históricas de fase 1; prevalece este estado y el reporte 02.
