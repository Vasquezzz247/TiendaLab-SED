# Guía de seguridad y defensa de TiendaLab

Actualización: 18 de noviembre de 2026. Fases autorizadas y trabajadas: **0 y 1**. Esta guía se actualiza en cada fase; no presenta planes como implementaciones ni resultados futuros como pruebas realizadas.

## 1. Qué puedes afirmar hoy

“Ya tengo un frontend local en PHP puro, con datos ficticios separados. Revisé todas las páginas de los PDF y reproduje sus pantallas. La vista de comprador no inicia una sesión: es un prototipo aislado. Todavía no hay base de datos, autenticación real, compra, despliegue en Ubuntu ni vulnerabilidades implementadas.”

| Componente | Estado real | Lo que falta |
| --- | --- | --- |
| Escape HTML, rutas permitidas y cabeceras PHP | Implementados y comprobados en fase 1 | Repetir con datos reales en fase 3 |
| Prototipos locales y rechazo de POST | Implementados y comprobados | Sustituir por rutas autenticadas en fase 3 |
| Formularios, roles visuales y carrito | Demostración; sin cambios en servidor | Validación y autorización reales |
| Apache | No instalado/configurado por este trabajo | Fase 5 |
| Sesiones, autenticación, contraseñas y roles | No implementados | Fase 3 |
| MariaDB, mysqli, Docker y Compose | No implementados | Fases 2 y 3 |
| VM, firewall y red Ubuntu | No modificados ni probados | Fase 5 |
| IDOR y servicio TCP/8081 | No implementados; no se abrió 8081 | Fase 4 y prueba de red en fase 5 |
| Auditoría completa e instalación cronometrada | No ejecutadas | Fases 6 y 7 |

## 2. Cómo explicar la arquitectura y sus límites

El navegador solicita una página a Apache. PHP ejecuta la lógica en la VM. mysqli es el controlador con el que PHP consulta MariaDB. Docker mantiene la base en un contenedor con un volumen para sus datos. Compose describe cómo levantar ese contenedor de forma repetible. Apache y PHP **seguirán en Ubuntu**, fuera de Docker.

La VM separa el laboratorio del sistema anfitrión, pero por sí sola no garantiza aislamiento de red. El modo de su adaptador y las rutas importan. Una red puente puede conectar la VM a equipos que no forman parte del ejercicio: se debe usar la configuración indicada por el docente y comprobar sus límites, sin asumir que “estar en una VM” basta.

| Puerto | Destino final | Acceso previsto | Estado actual |
| --- | --- | --- | --- |
| TCP/80 | Apache, tienda | Equipos autorizados del laboratorio | No configurado |
| TCP/8081 | Apache, diagnóstico ficticio | Red autorizada; sin internet | No abierto por este trabajo |
| TCP/3306 | MariaDB en Docker | Solo 127.0.0.1 de la VM | No configurado |
| TCP/8000 | Vista previa PHP Windows | Solo 127.0.0.1 | Usado temporalmente para revisar fase 1 |
| TCP/8002 | Vista previa con prototipo desactivado | Solo 127.0.0.1 | Usado temporalmente para prueba negativa |

Los puertos 8000/8002 no forman parte de la entrega Ubuntu ni son vulnerabilidades elegidas. `127.0.0.1` significa el propio equipo; no es una IP para compartir con otro equipo.

## 3. Bitácora de comandos realmente ejecutados

Los comandos siguientes se ejecutaron en **PowerShell sobre Windows**, desde `C:\Users\aleja\Desktop\TiendaLab_Documentos_Codex`, salvo lectura del adjunto por ruta absoluta. Las rutas y datos de ejemplo no son secretos. Se omiten del texto las salidas de identidad Git para no duplicar información personal; no se cambiaron los valores. Los archivos de código se crearon mediante la herramienta de parches, no ejecutando comandos de configuración de Ubuntu.

### 3.1 Lectura y preparación, en orden

1. `Get-Content -LiteralPath 'C:\Users\aleja\.codex\attachments\29798d21-6494-441e-9182-f5c3746f89e3\Pasted text.txt' -Raw`: leyó las instrucciones autorizadas por el usuario.
2. `rg --files -g '!node_modules' -g '!vendor' -g '!dist' -g '!build' -g '!package-lock.json' -g '!yarn.lock' -g '!pnpm-lock.yaml' -g '!.git'`: inventarió los archivos; inicialmente solo estaban los dos PDF.
3. `Get-ChildItem -Force | Select-Object Name,Mode`: revisó contenido de la raíz. `Get-Command php,python,py,git,pdftoppm,pdftotext,node -ErrorAction SilentlyContinue | Select-Object Name,Source`: detectó herramientas. `git status --short --branch`: confirmó que todavía no existía un repositorio.
4. `python -c "import sys; print(sys.executable); import pypdf; print('pypdf OK'); import fitz; print('fitz OK')"`: falló en `pypdf` con el Python predeterminado. No es evidencia de haber usado fitz.
5. Se localizó el Python incluido mediante la herramienta de dependencias de Codex. Se ejecutó lo siguiente para extraer todas las páginas:

```powershell
& 'C:\Users\aleja\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -c "import pypdf; from pathlib import Path; out=Path('tmp/pdfs'); out.mkdir(parents=True,exist_ok=True); [(out.joinpath(p.stem+'.txt').write_text('\n'.join('\\n=== PAGINA '+str(i+1)+' ===\\n'+(x.extract_text() or '') for i,x in enumerate(pypdf.PdfReader(p).pages)),encoding='utf-8'),print(p.name,len(pypdf.PdfReader(p).pages))) for p in Path('.').glob('*.pdf')]"
Get-Content -LiteralPath 'tmp\pdfs\DefinicióndelProyecto(1).txt' -Raw
Get-Content -LiteralPath 'tmp\pdfs\Propuesta_TiendaLab.txt' -Raw
pdftoppm -scale-to 1500 -png 'Propuesta_TiendaLab.pdf' 'tmp/pdfs/propuesta'
pdftoppm -scale-to 1300 -png 'DefinicióndelProyecto(1).pdf' 'tmp/pdfs/definicion'
```

Resultado: 6 y 11 páginas; 17 PNG inspeccionados. Poppler avisó de cajas de algunos glifos Type 3; no se ocultó el aviso y la inspección visual fue legible. Los renderizados son material de revisión, no código de aplicación.

6. `git config --get user.name` y `git config --get user.email`: identidad disponible. No se modificó la configuración global. Se buscaron instalaciones PHP en rutas habituales con `Get-ChildItem`; ninguna utilizable apareció. Las lecturas de `SKILL.md` y guías de herramientas no configuraron servicios del equipo.

### 3.2 PHP portátil: descarga y alcance de los permisos

```powershell
New-Item -ItemType Directory -Force -Path 'tools/php' | Out-Null
Invoke-WebRequest -Uri 'https://www.php.net/~windows/releases/latest/php-8.3-nts-Win32-vs16-x64-latest.zip' -OutFile 'tools/php.zip'
Expand-Archive -LiteralPath 'tools/php.zip' -DestinationPath 'tools/php' -Force
& '.\tools\php\php.exe' -v
```

El primer intento falló por resolución de nombre en el entorno restringido; por ello tampoco pudo extraerse ni ejecutarse el archivo inexistente. Se repitió con `$ErrorActionPreference = 'Stop'` y permiso de ejecución de la herramienta fuera de esa restricción. El segundo intento descargó, extrajo y ejecutó **PHP 8.3.36 CLI NTS**. No fue una elevación administrativa de Windows, no se cambió el firewall ni se instaló un servicio. El intérprete está dentro del proyecto y excluido de Git. NTS es suficiente para esta CLI; no es el módulo Apache de la entrega. Fuente: [descarga oficial de PHP para Windows](https://www.php.net/downloads.php?os=windows&version=8.3).

```powershell
Get-FileHash tools/php.zip -Algorithm SHA256
(Get-FileHash -LiteralPath 'tools/php.zip' -Algorithm SHA256).Hash
```

Huella local observada: `1A097D52B7A68622CDC723073B61CC70CAF79C941218FF65B2D8441DBC6B10D4`. Sirve para identificar este archivo descargado. **No se comparó con una firma o un hash publicado independiente**; no afirmar verificación criptográfica de origen. El enlace `latest` puede entregar otra revisión en el futuro.

### 3.3 Git local

```powershell
git init -b main
git add .gitignore .gitattributes '*.pdf'
git commit -m 'chore: preservar documentos oficiales y preparar repositorio'
git branch develop
git switch -c feature/fase-00-preparacion develop
git add docs REPORTES
git commit -m 'docs: analizar requisitos y completar fase 0'
git switch -c feature/fase-01-frontend
```

Se preservaron los PDF, se crearon las ramas permanentes y dos ramas de trabajo. `.gitignore` excluye temporales, PHP portátil y `.env`. Ignorar `.env` no borra secretos ya versionados: por eso no se crearon secretos. Los comandos posteriores de revisión `git remote -v`, `git branch --list` y `git status --short` confirmaron ausencia de remoto y trabajo en la rama de frontend. El cierre de esta fase se registra en el reporte 01 y en `git log`; no se inventa un PR.

### 3.4 Sintaxis, servidores de prueba y comprobaciones

```powershell
Get-ChildItem -Path app,demo,public -Filter '*.php' -Recurse |
  ForEach-Object { & '.\tools\php\php.exe' -l $_.FullName }
node --check public/assets/js/app.js
node --check public/assets/js/carrito.js
```

`php -l` analiza sintaxis, sin ejecutar una compra ni conectarse a una base. `node --check` comprueba sintaxis JavaScript; Node es una herramienta de pruebas, no el servidor ni una dependencia de la tienda.

Se ejecutaron estos dos arranques en procesos separados:

```powershell
$env:TIENDALAB_PROTOTIPO='1'
& '.\tools\php\php.exe' -S 127.0.0.1:8000 -t public
```

```powershell
$env:TIENDALAB_PROTOTIPO='0'
& '.\tools\php\php.exe' -S 127.0.0.1:8002 -t public
```

`-S` inicia el servidor de desarrollo de PHP. `-t public` limita la raíz de documentos servidos: `demo/`, `app/`, `docs/` y `.git/` quedan fuera. La variable habilita o bloquea el prototipo; no autentica a nadie.

```powershell
& '.\scripts\verificar-frontend.ps1' 2>&1 |
  Tee-Object -FilePath 'tmp/verificacion-frontend.txt'
```

La primera ejecución pasó sintaxis y cálculos, pero falló HTTP con `EACCES 127.0.0.1:8000`. Los primeros procesos se detuvieron con Ctrl+C y se volvieron a iniciar con permiso de la herramienta para acceder a loopback. Se repitió el mismo comando: **22 PHP válidos, 3 pruebas de cálculo aprobadas y 53 comprobaciones HTTP aprobadas**. No se desactivaron controles del sistema.

El script ejecuta, en orden: sintaxis PHP, `node --check public/assets/js/app.js`, `node --test tests/frontend.test.cjs` y `node tests/http.test.cjs 8000 8002`. `Tee-Object` muestra y guarda la salida. El archivo de evidencia estable se conserva en `REPORTES/evidencias/verificacion-frontend.txt`.

Después se añadió `tests/security.test.php` y su ejecución, entre sintaxis PHP y JavaScript, al script de verificación. Se ejecutó `& '.\scripts\verificar-frontend.ps1' 2>&1 | Tee-Object -FilePath 'REPORTES/evidencias/verificacion-frontend.txt'`: los resultados finales incluyen **8 comprobaciones PHP** (escape, IP local/externa/cabecera de proxy, ausencia de IP, bandera desactivada/ausente, moneda), las 3 pruebas JS y las 53 HTTP, todas aprobadas. La IP externa de esa prueba se simula dentro del proceso PHP; **no equivale a una prueba desde otra máquina**.

La revisión posterior `rg -n 'https?://|fetch\(|XMLHttpRequest|innerHTML|session_start|mysqli|password_hash' app public demo` encontró solamente los namespaces SVG `http://www.w3.org/2000/svg`; estos son identificadores XML, no descargas de red. `git diff --check` no reportó errores. Los ficheros SVG se generaron localmente con iniciales y gradientes, sin descargar imágenes.

Se ejecutó también `Get-NetTCPConnection -State Listen -LocalPort 8000,8002 -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,OwningProcess`; no produjo registros útiles en la salida capturada. **No se utiliza como prueba de sockets o firewall**. La evidencia de loopback es el parámetro de arranque, la guardia PHP y las peticiones locales, no una prueba desde otro equipo.

La comprobación en Edge se hizo por la herramienta de navegador, no por comandos de Ubuntu. Se revisaron DOM, capturas y acciones de búsqueda, formularios, carrito, factura, vendedor y usuarios. La adaptación móvil se revisó con viewport de 390×844; tras corregir el contenedor de la tabla, el ancho de documento y el disponible coincidieron en 375 px (resto reservado por scrollbar). Hay capturas reales en `REPORTES/evidencias/`.

Se comprobó además el ancho de las otras diez pantallas; todos los resultados fueron correctos y quedaron en `REPORTES/evidencias/responsive.json`. La inspección de consola al final devolvió una lista vacía de errores/avisos capturados. Dos intentos de captura de registro agotaron el tiempo de la herramienta; se volvió a esa pantalla y la captura final sí se guardó. La selección automatizada de un JPG local no pudo completarse porque la extensión de Edge no tenía permiso de acceso a URLs de archivo. No se cambió ese permiso ni se afirmó que la previsualización de archivo quedara probada. Las imágenes de fixtures y la previsualización de un producto existente sí se observaron.

## 4. Controles realmente implementados: archivos, motivo y defensa

### 4.1 Raíz pública pequeña

- **Qué:** el servidor recibe `-t public`. El código reutilizable y datos de demostración viven fuera de esa raíz.
- **Archivos:** `scripts/iniciar-frontend.ps1`, `app/`, `demo/`, `public/`.
- **Cómo protege:** una petición HTTP no obtiene directamente fuentes, documentos internos o el repositorio. Esto no sirve si alguien cambia DocumentRoot a la raíz del proyecto: hay que conservarlo en Apache.
- **Prueba ejecutada:** peticiones a `/app/bootstrap.php`, `/demo/datos.php`, `/docs/ALCANCE.md` y `/.git/config`: HTTP 404.
- **Explicación oral:** “Solo `public` es el escaparate. El resto del código queda detrás del mostrador.”

### 4.2 Prototipos desactivados por defecto y rutas permitidas

- **Qué:** `prototype_enabled()` exige `TIENDALAB_PROTOTIPO=1` y `REMOTE_ADDR` loopback. No confía en `X-Forwarded-For`. `public/prototipo/index.php` usa una lista cerrada de vistas, comprueba tipos y acepta solo ejemplos de factura 1, 3 y 4.
- **Cómo protege:** no se forman rutas de archivos con texto arbitrario; una consulta desconocida o un parámetro en forma de arreglo recibe 404. Los paneles son maquetas locales, no rutas finales sin protección.
- **Prueba ejecutada:** prototipo desactivado=404; vista desconocida/arreglo/ruta de archivo=404; ejemplo 2/arreglo=404; rutas finales `/admin.php` y `/factura.php?id=2`=404.
- **Límite:** la lista de ejemplos no es autorización por propietario. La autorización real se implementará con sesión; aquí no hay usuarios autenticados. La guardia no es adecuada detrás de un proxy que convierta toda conexión en loopback: el prototipo no debe desplegarse habilitado.
- **Explicación oral:** “Para revisar el diseño abrí una puerta local de demostración, cerrada por defecto; todavía no es el panel de producción.”

### 4.3 Escape de salida y DOM sin HTML de usuario

- **Qué:** `e()` en `app/bootstrap.php` usa `htmlspecialchars` con `ENT_QUOTES | ENT_SUBSTITUTE` y UTF-8. Las plantillas escapan textos y atributos. `public/assets/js/app.js` usa `textContent`, `createElement` y asignación de valores, no inserta la búsqueda como HTML.
- **Para qué:** caracteres especiales se muestran como datos dentro del contexto HTML esperado. No cambia ni valida el significado comercial de un dato. [Referencia oficial de htmlspecialchars](https://www.php.net/manual/en/function.htmlspecialchars.php).
- **Comprobación:** revisión de plantillas y prueba HTTP sin errores; buscador sin coincidencias funciona. La auditoría con entradas persistidas queda pendiente porque no existe backend.
- **Prueba específica adicional:** `tests/security.test.php` comprobó el escape de etiquetas, comillas simples/dobles y ampersand. Fue ejecutada y pasó; no sustituye una auditoría completa de todos los contextos.
- **Explicación oral:** “Un nombre que contiene símbolos debe mostrarse como nombre, no convertirse en una etiqueta que el navegador ejecute.”

### 4.4 Cabeceras y bloqueo de envíos

Archivo: `app/bootstrap.php`. Aplicadas a respuestas PHP:

| Control | Función | Comprobación real |
| --- | --- | --- |
| `Content-Type: text/html; charset=UTF-8` | Define formato y codificación de la página | Páginas renderizadas con acentos |
| `X-Content-Type-Options: nosniff` | Evita reinterpretaciones de tipo de contenido en contextos relevantes | Cabecera presente en las 11 pantallas |
| `Referrer-Policy: no-referrer` | Evita enviar la URL de origen como Referer | Inspección de código; no captura de tráfico externa |
| `Cache-Control: no-store` | Indica no almacenar la respuesta en caché | Cabecera comprobada en HTTP |
| CSP `default-src 'self'` | Recursos propios como regla base | Recursos locales comprobados |
| CSP `script-src/style-src 'self'` | JS/CSS locales, sin inline | Sin handlers inline en las respuestas comprobadas |
| CSP `img-src 'self' blob:` | Imágenes locales y previsualización temporal | Imágenes del catálogo cargadas |
| CSP `connect-src 'none'` | No permite fetch/XHR/conexiones de la interfaz | Se inspeccionó la política; el código no hace peticiones |
| CSP `form-action 'none'` | Bloquea envío de formularios en esta fase | Cabecera HTTP comprobada; botones solo validan |
| CSP `object-src/base-uri/frame-ancestors 'none'` | Evita objetos incrustados, cambio de base y enmarcado | Código inspeccionado; no prueba específica de iframe |
| GET/HEAD únicamente | Rechaza operaciones de escritura | POST a login devuelve 405 y Allow GET, HEAD |

Estas cabeceras no son un WAF, no comprueban dueños de facturas y no cierran puertos. Por tanto, no anulan las dos vulnerabilidades elegidas. La política `form-action 'none'` y el rechazo global de POST son específicos del prototipo: **deberán cambiar en fase 3** por POST permitido solo en acciones previstas con validación y CSRF. No se prometerá que la política actual sirva sin cambios para el backend.

Explicación oral: “El navegador recibe reglas para cargar solo nuestros recursos. El servidor también rechaza envíos; no depende solo del botón desactivado.”

### 4.5 Datos ficticios, carrito y archivos

- `demo/datos.php`: ejemplos sin hashes ni contraseñas; dominios `.test`. El resumen administrativo reproduce cuatro facturas y $459.50 del anexo; el comprador solo visualiza tres ejemplos de Ana. El cuarto total del anexo corresponde a $145.77; no hay endpoint para esa factura ajena.
- `app.js`: sessionStorage guarda únicamente ID y cantidad del carrito de muestra. No guarda nombres, correos, contraseñas, roles, tokens ni precios. Se recalcula con los fixtures y se validan cantidades enteras y límites. No es una fuente confiable para una compra futura: el servidor deberá volver a calcular todo con la base.
- `carrito.js`: dinero en centavos enteros; IVA redondeado una vez sobre subtotal. El caso del anexo y casos vacío/límites pasaron.
- Formularios: validan en navegador, no tienen nombres de parámetros para enviar datos y sus botones son `type="button"`. La política CSP y el rechazo de POST refuerzan la separación. Al revisar un formulario válido se limpian las contraseñas de prueba; no se crean cuentas.
- Imagen: `accept`, tipo declarado JPG/PNG/WEBP y máximo 2 MB limitan la previsualización. `URL.createObjectURL` crea una URL temporal local que se revoca al reemplazarla. **Esto no es validación segura de una subida real**: en fase 3 se comprobará el archivo en servidor y se impedirá ejecutar contenido subido.
- Borrar/guardar/confirmar muestran avisos explícitos sin alterar fixtures o existencias. El carrito sí cambia temporalmente, porque es una interacción visual autorizada.

Explicación oral: “En fase 1 pruebo cómo se usa la tienda. Los precios del navegador nunca serán la autoridad para cobrar o descontar inventario.”

## 5. Autenticación, sesiones y roles: plan, todavía no implementado

### Autenticación y contraseñas

Autenticar es comprobar quién es el usuario. El backend buscará su correo con mysqli parametrizado y verificará la contraseña frente a un hash con las funciones nativas de PHP. Un hash no se descifra para recuperar la contraseña; se verifica la candidata. No usar MD5, SHA simple ni guardar texto plano. El registro impondrá comprador desde el servidor, aunque se manipule el formulario. [Funciones de hash de PHP](https://www.php.net/manual/en/function.password-hash.php).

Archivos previstos: módulo de autenticación y acciones de login/registro, aún no creados. Pruebas futuras: contraseña correcta/incorrecta, correo duplicado, registro con rol manipulado, respuesta genérica, límite de intentos. La ausencia de límites no será una tercera vulnerabilidad deliberada.

Explicación oral: “La contraseña demuestra identidad. El servidor decide el rol; el navegador no puede nombrarse administrador.”

### Sesiones

Una sesión permitirá relacionar varias peticiones con un usuario ya autenticado. Se planifica modo estricto, ID regenerado tras login, cookie HttpOnly, SameSite, expiración e invalidación al salir. No habrá IDs de sesión en la URL. El atributo Secure requiere HTTPS: como la arquitectura aprobada usa HTTP en laboratorio, no debe activarse ciegamente y luego fingir que las sesiones funcionan. Tampoco se declarará cifrado del tráfico HTTP. Solo se usarán credenciales ficticias del laboratorio. [Configuración de seguridad de sesiones PHP](https://www.php.net/manual/en/session.security.ini.php).

Pruebas futuras: no entrar a paneles sin cookie; comprobar regeneración, expiración, logout e inaccesibilidad de la sesión cerrada. Actualmente las respuestas no emiten `Set-Cookie`; eso se verificó en los tests HTTP. sessionStorage del carrito **no** es una sesión de autenticación.

Explicación oral: “La cookie es un identificador de sesión; los permisos viven en el servidor, no en un selector de la pantalla.”

### Autorización, CSRF y datos

Autorizar es decidir qué puede hacer una identidad. Se comprobarán roles y propiedad en cada operación: vendedor sobre sus productos, comprador sobre su historial, administrador sobre productos/usuarios. Solo la propiedad de una factura concreta se omitirá deliberadamente en fase 4. Ocultar botones no sustituye estas comprobaciones.

Los cambios usarán POST y un token CSRF ligado a la sesión. SameSite ayuda, pero no reemplaza el token. Las cantidades, existencias y totales se validarán de nuevo en el servidor. La compra deberá ser transaccional para que factura, detalle y descuento de stock se confirmen juntos o no se aplique ninguno.

Pruebas futuras: comprador solicitando una acción administrativa, vendedor editando producto ajeno, POST sin token, compra con stock insuficiente, concurrencia y rollback. No ejecutadas en fase 1.

## 6. MariaDB, mysqli y Docker: plan

- MariaDB almacenará usuarios, productos, facturas y detalles. Su usuario de aplicación tendrá los permisos mínimos necesarios; la aplicación no usará root. Las credenciales reales de instalación no entrarán a Git, capturas ni esta guía.
- mysqli enviará consultas preparadas con parámetros; separar estructura SQL y valores evita tratar un dato como parte de la consulta. Parametrizar no comprueba permisos ni propiedad: una consulta preparada puede seguir teniendo IDOR. [Consultas preparadas mysqli](https://www.php.net/manual/en/mysqli.quickstart.prepared-statements.php).
- Compose publicará MariaDB en `127.0.0.1:3306` del host de la VM y usará un volumen persistente. Publicar simplemente `3306:3306` puede escuchar en interfaces externas; se evitará. También se comprobará que la red de Docker no cree una ruta externa inesperada. Las versiones y modos de Docker importan: la documentación advierte sobre diferencias de aislamiento, por lo que se verificará desde otro equipo autorizado. [Publicación de puertos de Docker](https://docs.docker.com/engine/network/port-publishing/).
- El volumen conserva datos después de recrear el contenedor; no es por sí solo una copia de seguridad. No ejecutar `down -v` sobre datos que se deban conservar.

Archivos futuros: Compose, SQL y configuración de conexión; no existen todavía. Pruebas futuras: levantar, consultar con mysqli, reiniciar y comprobar persistencia, acceso a 3306 desde la VM y rechazo desde otro equipo. No se ha hecho ninguna de ellas.

Explicación oral: “Docker hace repetible la base. mysqli es el puente desde PHP. El puerto de la base queda en el interior de la VM, no en el mostrador de la red.”

## 7. Apache, PHP, firewall y red Ubuntu: plan

Apache tendrá un VirtualHost para la tienda con DocumentRoot apuntando a `public/`, sin listados de directorios. La configuración del diagnóstico usará otra raíz. Se limitará la escritura del usuario de Apache a los directorios que de verdad la necesiten; no se usará `chmod 777`. PHP tendrá errores registrados fuera de la raíz pública y mensajes genéricos para usuarios; no se publicará `phpinfo()`. No se han creado vhosts ni modificado php.ini del sistema. [DocumentRoot y opciones de Apache](https://httpd.apache.org/docs/2.4/mod/core.html#documentroot).

El firewall filtrará conexiones de acuerdo con la red autorizada, manteniendo 80 y 8081 disponibles desde los equipos del ejercicio. No se abrirá 3306 a la LAN ni se añadirá SSH como requisito nuevo. Si la VM se administra por SSH, cualquier cambio deberá evitar perder ese acceso y considerar las indicaciones del docente. Docker administra reglas de red propias: comprobar UFW es necesario pero no suficiente para demostrar aislamiento de contenedores. [Firewall en Ubuntu Server](https://documentation.ubuntu.com/server/how-to/security/firewalls/).

La IP, interfaz y subred reales se documentarán en fase 5 después de observarlas y recibir las instrucciones del laboratorio. No se adivinan aquí ni se crean reglas de firewall generales como “permitir desde cualquier lugar”.

Explicación oral: “Apache decide qué sitio responde; PHP ejecuta la aplicación; el firewall decide desde dónde se puede llegar. Cada capa tiene una tarea distinta.”

## 8. Comandos de Ubuntu recomendados, NO ejecutados

Esta es una lista de lectura y verificación para la fase correspondiente, **no un instalador ya probado**. Ejecutarlos solo en la VM propia. El orden permite conocer el entorno antes de cambiarlo. No se ofrecen cambios de red automáticos hasta conocer interfaz, subred y acceso de administración.

| Orden | Comando previsto | Qué comprueba | Fase |
| --- | --- | --- | --- |
| 1 | `cat /etc/os-release` | Distribución y versión real | 5 |
| 2 | `ip -br address` | Interfaces y direcciones asignadas | 5 |
| 3 | `ip route` | Rutas, puerta de enlace y posible salida externa | 5 |
| 4 | `sudo ss -lntp` | Sockets TCP en escucha y procesos | 5 |
| 5 | `sudo ufw status verbose` | Estado y política del firewall | 5 |
| 6 | `apache2ctl -v` | Versión de Apache instalado | 5 |
| 7 | `sudo apache2ctl configtest` | Sintaxis del servidor antes de recargarlo | 5 |
| 8 | `sudo apache2ctl -S` | VirtualHosts efectivos | 5 |
| 9 | `systemctl is-active apache2` | Servicio activo o no | 5 |
| 10 | `php -v` | Versión CLI; no demuestra por sí sola versión del módulo Apache | 3/5 |
| 11 | `php -m` | Extensiones CLI, incluida mysqli; comprobar aparte SAPI web | 3/5 |
| 12 | `docker version` | Versiones cliente/servidor del motor | 2/5 |
| 13 | `docker compose version` | Disponibilidad de Compose | 2/5 |
| 14 | `docker compose config --quiet` | Validez de Compose sin volcar variables o secretos | 2/5 |
| 15 | `docker compose ps` | Estado de servicios del proyecto | 2/5 |
| 16 | `curl -I http://127.0.0.1/` | Estado y cabeceras de la tienda | 5/6 |

No se ejecutaron `apt install`, `ufw enable`, reglas `ufw allow`, `netplan apply`, `a2ensite`, `systemctl reload`, `docker compose up` ni cambios SQL. Sus comandos exactos se añadirán cuando se implementen y prueben en sus fases, junto con salidas y archivos reales. Esto evita documentar un despliegue inventado.

## 9. Las dos vulnerabilidades intencionales

### A. IDOR de factura (prevista para fase 4)

- **Qué significa:** referencia directa a un objeto sin comprobar si pertenece al solicitante. Identificar un objeto por número no es el fallo; omitir autorización sobre ese objeto sí.
- **Ubicación prevista:** `factura.php?id=`, detrás de autenticación real. La fase 1 no crea esa ruta.
- **Por qué existirá:** demostrar una falla de autorización sobre datos ficticios en el ejercicio aprobado. No se omitirá la sesión ni se extenderá a historial o productos.
- **Impacto acotado:** un comprador de laboratorio podría leer un documento ficticio ajeno; no debe modificarlo, borrar datos ni obtener control del equipo.
- **Cómo corregir:** exigir en servidor que la factura pertenezca al comprador autenticado o que exista un permiso explícito para esa operación. Validar el ID o usar una consulta preparada no basta para corregir propiedad.
- **Cómo comprobar en fase 4:** preparar dos cuentas ficticias con facturas conocidas, verificar primero que sin sesión no hay acceso, comprobar la lectura propia y después la lectura ajena prevista por el ejercicio; guardar evidencia con identidades ficticias. En una variante corregida, la lectura ajena debe denegarse. No se ha ejecutado esta prueba.
- **Defensa sencilla:** “La puerta reconoce quién entró, pero en esa única consulta olvidamos comprobar de quién es el documento. El arreglo es autorizar el documento, no quitar números de la URL.”

### B. Diagnóstico expuesto en TCP/8081 (previsto para fase 4)

- **Qué significa:** un servicio interno de diagnóstico accesible desde la red autorizada cuando no debería estar disponible para compradores.
- **Ubicación prevista:** Apache en 8081, raíz independiente, sin enlaces desde la tienda. No existe servicio en esta fase.
- **Por qué existirá:** representar una mala configuración del servidor sin utilizar secretos ni comandos reales. La página mostrará valores estáticos inventados, no información tomada del sistema.
- **Impacto acotado:** exposición de información ficticia. No tendrá consola, shell, archivos reales, contraseñas reales ni administración del sistema.
- **Cómo corregir:** retirar el listener y sitio cuando no sea necesario, o restringir el acceso a una interfaz/origen administrativo autorizado. Quitar un enlace no cierra un servicio. La mitigación se documentará sin cerrar accidentalmente el ejercicio antes de su evaluación.
- **Cómo comprobar en fase 4/5:** desde el segundo equipo expresamente autorizado, verificar disponibilidad de 8081 en la VM del proyecto y lectura de la página; confirmar que sus datos son ficticios y que la tienda no la enlaza. Luego comprobar el cierre o restricción en la variante corregida. No hay resultados todavía.
- **Defensa sencilla:** “La aplicación puede controlar bien sus roles y aun así el servidor dejar otra puerta abierta. El fallo está en exponer ese servicio, aunque no tenga enlace.”

El entorno se limita a VM y red del laboratorio. No se prueban otros equipos, infraestructura institucional o internet. No se introducen SQLi, XSS, RCE ni un login deliberadamente sin límites. La ausencia absoluta de defectos no se garantiza por declaración: se audita.

## 10. Cómo practicar la explicación y las comprobaciones actuales

1. Inicia la vista previa siguiendo README y abre el catálogo. Explica que las tarjetas son HTML generado por PHP con datos de `demo/datos.php`.
2. Muestra el aviso de fase 1. Recorre comprador/vendedor/admin desde “Revisar pantallas”, explicando que no has iniciado sesión.
3. Carga el carrito del anexo. Explica centavos, subtotal 7399, IVA 962 y total 8361. Al confirmar se informa que no existe una compra.
4. Abre factura de ejemplo e historial. No afirmes que se generaron al pulsar confirmar.
5. Muestra `app/bootstrap.php`: escape, cabeceras y rechazo de POST. Luego `public/prototipo/index.php`: habilitación y lista cerrada de rutas.
6. Explica cómo la futura autenticación será distinta de una maqueta. Usa el cuadro de estado al principio de esta guía.
7. Para repetir pruebas, arranca también el servidor con `-SinPrototipo -Port 8002` y ejecuta el script de verificación. Es necesario Node para los tests, pero no para ver la tienda.
8. Cierra ambos procesos con Ctrl+C después de practicar.

Preguntas útiles: “¿Una consulta preparada corrige IDOR?” No, corrige separación de consulta/datos, no propiedad. “¿Un rol en JavaScript protege al servidor?” No. “¿El diagnóstico está protegido por no tener enlace?” No. “¿Docker protege automáticamente la base de la LAN?” No, hay que publicar correctamente y probar. “¿La instalación tarda menos de 30 minutos?” Todavía no se ha medido en una VM limpia.

## 11. Regla para actualizar esta guía en fases posteriores

Cada nuevo control tendrá fecha, objetivo, comandos exactos en orden, archivos modificados, explicación de funcionamiento, evidencia real, límites y explicación oral. Mover de “plan” a “implementado” solamente después de crear el componente; mover a “comprobado” solamente después de ejecutarlo. Registrar fallos y correcciones, sin reemplazarlos por un resultado ideal. No incluir secretos, tokens, cookies activas, contraseñas reales ni datos de terceros.

La matriz de requisitos y los reportes por fase deben actualizarse al mismo tiempo. Las fuentes oficiales enlazadas orientan los controles; no sustituyen la definición del docente ni autorizan nuevas tecnologías o fases.

## 12. Cierre verificado de fase 1

Actualización posterior: el usuario autorizó publicación privada y organización GitFlow, sin iniciar fase 2. El estado vigente del remoto está en `REPORTES/ESTADO_GITFLOW.md`; las menciones anteriores a ausencia de remoto son históricas.

Se comprobaron los dos scripts PowerShell con `System.Management.Automation.Language.Parser.ParseFile`: ambos sin errores de sintaxis. Un script de Python recorrió enlaces Markdown locales de README, docs y reportes: ninguno apuntaba a un archivo inexistente. Estas comprobaciones no configuran seguridad del sistema.

El intento inicial de `git add app demo public scripts tests` y commit falló al crear `.git/index.lock` por permisos del entorno. No se borró ningún lock ni se cambiaron ACL. Se repitió con autorización de la herramienta y se ejecutó esta secuencia:

```powershell
git add app demo public scripts tests
git diff --cached --check
git commit -m 'feat: construir frontend local de TiendaLab con prototipos aislados'
```

Resultado: commit local `5deaa9c`, 41 archivos de código, assets, scripts y tests; chequeo de espacios sin errores. Los avisos de conversión CRLF/LF son de finales de línea entre Windows/Linux, no fallos de la aplicación.

Los dos servidores de prueba se detuvieron enviando Ctrl+C a sus procesos. El código de salida 1 corresponde a esa interrupción voluntaria, no a un error funcional de la tienda. Para practicar se deben iniciar de nuevo según README. No quedaron servicios de base de datos o diagnóstico creados por esta fase.

La documentación y evidencias se guardan en un segundo commit local de cierre, sin push. Su identificador exacto puede consultarse con `git log --oneline -4`; no se incluye dentro del archivo para evitar una referencia circular al propio commit.
