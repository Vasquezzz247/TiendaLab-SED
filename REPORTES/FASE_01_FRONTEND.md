# Fase 01: frontend de TiendaLab

Fecha: 18/11/2026, zona del usuario America/El_Salvador. Se trabajó después de completar el análisis de las 17 páginas de las fuentes. No se inició fase 2.

## 1. Objetivo

Construir todas las interfaces de la tienda con PHP puro, HTML, CSS y JavaScript nativo, reproduciendo el anexo aprobado, con navegación y comportamiento visual comprobables. Separar claramente frontend de demostración y operaciones que requieren backend. Incorporar la guía de seguridad solicitada durante la fase.

## 2. Requisitos de los PDF cubiertos

- Definición p. 1: vistas pública, login, registro, comprador, vendedor y administrador; se implementaron **vistas**, no operaciones autenticadas reales.
- Propuesta pp. 6-11: catálogo con buscador, acceso dividido, registro, controles de cantidad, carrito con IVA 13 %, factura, historial, vendedor, resumen administrativo, productos y usuarios.
- Definición pp. 2-3 y propuesta pp. 1-4: stack sin frameworks/ORM/CMS ni nube; PHP puro, recursos locales. MariaDB y mysqli están previstos, no implementados anticipadamente.
- Definición p. 1: las rutas finales restringidas no se expusieron como funcionales. Las maquetas están en `/prototipo/`, cerradas por defecto y limitadas a loopback.
- Definición pp. 3-4 y propuesta p. 4: ramas GitFlow y documentación preparadas localmente; GitHub/PR quedan pendientes.
- Matriz R01-R17, R24-R26 y R33-R35: cobertura parcial o visual según cada fila. R08 no está implementado: no hay compra real, stock transaccional ni creación de facturas.
- Capturas 8 y 12 del anexo: se analizaron, pero sus vulnerabilidades no se implementaron en esta fase.

## 3. Archivos creados y modificados

### Aplicación

- `app/bootstrap.php`: cabeceras, escape, guardia local y renderizado.
- `app/components/header.php`, `footer.php`, `product-card.php`, `product-form.php`, `product-table.php`, `admin-summary.php`: componentes compartidos.
- `app/views/catalogo.php`, `login.php`, `register.php`, `prototipo.php`, `carrito.php`, `factura.php`, `historial.php`, `vendedor.php`, `admin-productos.php`, `admin-usuarios.php`: diez plantillas, con catálogo compartido entre público y comprador.
- `demo/datos.php`: 9 productos, 5 identidades ficticias y 3 ejemplos de facturas propias; sin credenciales.
- `public/index.php`, `login.php`, `register.php`, `prototipo/index.php`: cuatro puntos de entrada; este último usa una lista de rutas.
- `public/assets/css/styles.css`: diseño, responsive y reglas de impresión.
- `public/assets/js/app.js`, `carrito.js`: navegación interactiva, validación y cálculo en centavos.
- `public/assets/img/`: nueve SVG de productos con gradientes e iniciales, `marca.svg` y `chevron.svg` (11 archivos locales).

### Herramientas, pruebas y documentación

- `scripts/iniciar-frontend.ps1`, `scripts/verificar-frontend.ps1`.
- `tests/frontend.test.cjs`, `tests/http.test.cjs`, `tests/security.test.php`.
- `README.md`, `AGENTS.md`, `docs/GUIA_SEGURIDAD_Y_DEFENSA.md`; matriz actualizada con R35 por instrucción adicional.
- Este reporte y `REPORTES/evidencias/`: capturas JPG, `responsive.json`, `verificacion-frontend.txt` y registro de revisión visual.
- `tools/php/` y `tools/php.zip`: intérprete portátil PHP 8.3.36 solo en la copia local, ignorado por Git. `tmp/` contiene evidencia temporal del análisis y primer intento de pruebas.
- Los PDF originales no se modificaron.

## 4. Funcionalidades implementadas

### Funciona en el frontend

1. Catálogo público de 9 productos, imágenes SVG locales, descripciones, precios, stock y buscador sin distinguir tildes/mayúsculas; estado sin resultados y restablecer búsqueda.
2. Login y registro con validación local, confirmación de contraseña y aviso honesto de backend pendiente. Registro muestra comprador fijo. No reciben ni almacenan credenciales.
3. Índice local de prototipos, navegación por vistas y salida al catálogo; no inicia/cierra una sesión real.
4. Catálogo de comprador con controles +/−, entrada de cantidad, límites y agregar; contador de unidades.
5. Carrito temporal en sessionStorage de la pestaña, cambios de cantidad, eliminar, vacío, reinicio y ejemplo del anexo; subtotal/IVA/total en centavos.
6. Confirmar compra muestra explicación de operación no disponible y no modifica existencias ni genera facturas.
7. Factura de ejemplo con líneas, totales y marca sin validez fiscal; botón de impresión y CSS de impresión implementados. Historial con enlaces a tres documentos ficticios propios.
8. Vendedor: formulario, tabla de nueve productos y carga del producto existente en el borrador. Imagen elegida: tipo/tamaño y vista previa implementados, sin subida.
9. Administración: cuatro métricas del anexo, pestañas, formulario nuevo/editar producto, avisos de eliminación, formulario nuevo/editar usuario incluyendo nombre/correo/rol y selector de rol visual.
10. Cabecera/pie reutilizables, etiquetas de formulario, navegación por enlaces, foco visible, estados anunciados, diseño adaptable y tablas con desplazamiento propio.

### Requiere backend y sigue pendiente

Autenticación, sesiones, autorización por rol, registro, hashes de contraseña, limitación de intentos, CSRF real, mysqli, SQL/Compose, usuarios/productos persistentes, validación/subida de imágenes en servidor, cambio de roles, propiedad de productos, compra transaccional, descuento de stock, creación e historial consultado desde BD. El prototipo no demuestra ninguno de estos controles futuros.

## 5. Cómo ejecutar y comprobar

En PowerShell:

```powershell
Set-Location 'C:\Users\aleja\Desktop\TiendaLab_Documentos_Codex'
.\scripts\iniciar-frontend.ps1
```

Abrir `http://127.0.0.1:8000/`. Usar “Revisar pantallas” para vistas de roles. Mantener la terminal abierta; Ctrl+C detiene el servidor. PHP portátil está preparado en esta computadora; en una nueva copia se necesita PHP instalado o portátil. README incluye la alternativa sin `.ps1` y no requiere modificar políticas de PowerShell.

Para repetir las pruebas, iniciar en otra terminal `scripts/iniciar-frontend.ps1 -SinPrototipo -Port 8002`; luego ejecutar `scripts/verificar-frontend.ps1` desde la raíz. El script necesita Node solo para las pruebas, no para ejecutar la tienda. Se comprobarán ambas instancias.

El DocumentRoot siempre es `public/`. No usar `0.0.0.0` para este prototipo ni poner la raíz completa del proyecto en un servidor web.

## 6. Pruebas realizadas: comandos, resultados y evidencias

### Comprobaciones de código y HTTP

Comando final ejecutado en PowerShell:

```powershell
& '.\scripts\verificar-frontend.ps1' 2>&1 |
  Tee-Object -FilePath 'REPORTES/evidencias/verificacion-frontend.txt'
```

| Prueba ejecutada | Resultado real |
| --- | --- |
| `php -l` sobre 22 archivos de aplicación | 22 sin errores de sintaxis |
| `node --check` app.js y carrito.js (revisión inicial) | Sin errores |
| `php tests/security.test.php` | 8 comprobaciones aprobadas: escape, guardia loopback/bandera/cabecera y moneda |
| `node --test tests/frontend.test.cjs` | 3 tests aprobados: referencia del anexo, vacío/redondeo, límites de cantidad |
| `node tests/http.test.cjs 8000 8002` | 53 comprobaciones aprobadas |
| Pantallas HTTP | 11: públicas 3, índice y vistas de prototipo 8 |
| Assets de HTML y enlaces | 13 assets únicos y enlaces internos respondieron 200; el chevron de CSS se observó en selectores |
| Factura de referencia | Subtotal $73.99, IVA $9.62, total $83.61 presentes |
| POST a login | 405; no operación ni sesión |
| Prototipo desactivado | 404 en servidor 8002 |
| Vista desconocida/parámetro arreglo/ruta de archivos | 404 |
| Ejemplo de factura 2 o parámetro arreglo | 404; no IDOR implementado |
| Rutas finales admin/factura e internas app/demo/docs/.git | 404 |
| Cabeceras de respuestas PHP | nosniff, no-store y CSP form-action none presentes; ninguna cookie de sesión |
| Inspección estática de llamadas/recursos | Solo namespaces XML SVG en búsqueda de URLs; sin fetch, innerHTML ni conexiones de aplicación |
| Parser de PowerShell y enlaces Markdown | Dos scripts válidos; ningún enlace local roto |

La prueba PHP de IP externa es una simulación de `REMOTE_ADDR` dentro del proceso; no es prueba de red desde un segundo equipo. Se documenta así expresamente.

### Navegador Edge real

- Búsqueda `audifonos`: un producto. Búsqueda sin coincidencias: estado vacío; botón restablece catálogo.
- Login con datos inventados: aviso “no se ha autenticado a ningún usuario”. Registro válido: aviso “no se ha creado ninguna cuenta”. Se intentó confirmación no coincidente; la lectura automatizada del mensaje nativo no proporcionó evidencia suficiente, por lo que se deja ese caso como pendiente de revisión manual explícita.
- Agregar 2 audífonos y navegar al carrito: 2 unidades, subtotal $79.98, IVA $10.40, total $90.38. Reducir a 1: total $45.19. Eliminar: carrito vacío.
- Cargar ejemplo: $83.61. Confirmar: modal informa que no se cobró, descontó stock ni generó factura. Cerrar modal funciona.
- Factura y tres filas del historial: totales $83.61, $156.79 y $73.33; navegación observada.
- Vendedor: editar audífonos rellena nombre/precio/stock e imagen de fixture; guardar informa que no publicó ni modificó el producto.
- Admin productos: eliminar muestra aviso sin cambios; Nuevo producto abre el formulario.
- Admin usuarios: editar Ana, seleccionar Vendedor en el borrador y guardar muestra aviso sin cambios reales; eliminar Luis muestra aviso sin eliminarlo.
- Revisión visual en escritorio de catálogo, registro, factura, carrito, vendedor y usuarios; login y administración de productos también capturados.
- Viewport 390×844: catálogo, login, registro, índice de prototipos, comprador, carrito, factura, historial, vendedor, admin productos y admin usuarios sin desbordamiento horizontal del documento tras la corrección. `responsive.json` registra diez rutas; catálogo se verificó por separado.
- Consulta final de consola de la pestaña: lista vacía de errores/avisos capturados. Esto no equivale a una auditoría completa de cada interacción posible.

### Evidencia disponible

`catalogo.jpg`, `login.jpg`, `registro.jpg`, `carrito.jpg`, `factura.jpg`, `vendedor.jpg`, `admin-productos.jpg`, `admin-usuarios.jpg`, `catalogo-movil.jpg`, `usuarios-movil.jpg`, `carrito-movil.jpg`, `vista-previa.jpg`, `responsive.json`, `verificacion-frontend.txt` y `REVISION_VISUAL.md`, todos bajo `REPORTES/evidencias/`.

## 7. Problemas encontrados y soluciones

- PHP no estaba en PATH: se preparó PHP portátil desde php.net dentro de `tools/`, sin instalar servicios ni cambiar configuración global.
- Descarga inicial sin resolución DNS y HTTP local bloqueado por el entorno restringido (`EACCES`): se usó la aprobación de la herramienta para descarga/pruebas locales. Se detuvieron los primeros servidores y se reiniciaron limitados a 127.0.0.1. No se modificó el firewall.
- En móvil, textos accesibles absolutos de la tabla contribuían a un ancho de documento de 592 frente a 375 px disponibles. Se añadió `position:relative` al contenedor `.table-scroll`. Después se midieron 375/375 y la tabla mantiene su desplazamiento interno.
- Dos capturas de registro agotaron tiempo de la herramienta; se volvió a la página limpia y la captura posterior funcionó.
- La selección automatizada de una imagen local fue rechazada por falta de permiso de archivos en la extensión Edge. Se mantuvo la implementación y se dejó la comprobación manual documentada; no se modificó la seguridad del navegador.

## 8. Requisitos pendientes o bloqueados

Todas las fases 2-7, despliegue real, red de laboratorio, cronometraje e integración GitHub/PR están pendientes de autorización o información correspondiente. No se pidió aprobación por cada archivo.

Límites de verificación de fase 1: selección/previsualización de archivo nuevo pendiente por permiso de extensión; exportación PDF/impresora no probada; mensaje nativo de confirmación de contraseña no acreditado visualmente. Los controles están implementados, pero no se reportan como comprobados. No hay pruebas Apache, Ubuntu, MariaDB, Docker ni segundo equipo.

## 9. Posibles incumplimientos de la propuesta

No se identificó una sustitución del stack ni una función comercial adicional. SVG locales de iniciales reproducen los bloques de imagen del anexo; la previsualización PHP en Windows no sustituye Apache de entrega. El hero usa texto de exploración y el sitio muestra rótulos de demostración para no prometer compra/descarga automática inexistentes. Son adaptaciones explícitas de fase 1.

Los datos de stock usan una instantánea consistente, ya que las capturas muestran momentos distintos. El resumen administrativo conserva valores ficticios del anexo, no consultas realizadas a una BD. El listado del comprador incluye solo tres facturas propias; no se habilita el ejemplo ajeno del anexo antes de fase 4.

El proyecto completo todavía **no** cumple los requisitos de backend, vulnerabilidades, despliegue ni GitHub; quedan registrados como pendientes. No debe entregarse este frontend como la tienda final.

## 10. Estado final

**COMPLETADA — fase 1 de frontend**, con los límites de verificación expresamente indicados. Fases 0 y 1 listas para auditoría del usuario. **Desarrollo detenido antes de fase 2.** Guía de seguridad creada e instrucción de actualizarla incorporada a `AGENTS.md`.

No se publicó código ni se creó remoto/PR. Los cambios se conservan en `feature/fase-01-frontend`, pendiente de revisión e integración mediante GitHub cuando el usuario proporcione el destino. Los servidores temporales de comprobación se detienen al cerrar el trabajo; README permite volver a iniciarlos.

El frontend, scripts y pruebas están en el commit local `5deaa9c`; el cierre documental queda en el commit siguiente de la misma rama. Se comprobaron cambios preparados con `git diff --cached --check`. `main` y `develop` permanecen en la base de documentos originales, sin fingir una integración revisada por PR.
