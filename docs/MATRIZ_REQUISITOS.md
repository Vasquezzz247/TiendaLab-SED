# Matriz de cumplimiento

Fuentes: D = definición oficial, P = propuesta; numeración física. Estado vigente de fase 3: `REPORTES/FASE_03_BACKEND.md`. **V** = vista de prototipo implementada; no equivale a backend funcional. **P** = pendiente en fase indicada. **D** = documentado.

| ID | Fuente | Requisito | Implementación / destino | Prueba y evidencia esperada | Estado / fase |
| --- | --- | --- | --- | --- | --- |
| R01 | D1; P2,6 | Index público, catálogo, imágenes, precios, stock, buscador | public/index.php; app/shop.php; views/live/catalogo.php | Catálogo y búsqueda SQL literal; imágenes seed; HTTP real | Implementado/probado 3 |
| R02 | D1; P2,6 | Login correo/contraseña y cierre | app/auth.php; app/web.php; login.php/logout.php | Login correcto/incorrecto/inactivo, logout y cookie revocada | Implementado/probado 3 |
| R03 | D1; P2,7 | Registro siempre comprador | register_user; register.php | Alta real, hash, duplicado y rol manipulado ignorado | Implementado/probado 3 |
| R04 | D1; P2,3 | Autenticación y autorización por rol | require_role; current_user; rutas por rol | Acceso anónimo/rol incorrecto; cambio de rol e inactividad efectivos | Implementado/probado 3 |
| R05 | D1; P7 | Comprador selecciona cantidades y agrega | app/shop.php cart_change; sesión PHP | Agregar cantidades; IDs y stock validados por servidor | Implementado/probado 3 |
| R06 | P8 | Quitar, cantidades, carrito vacío y resumen | public/carrito.php; views/live/carrito.php | Modificar/quitar; precio enviado ignorado; subtotal correcto | Implementado/probado 3 |
| R07 | P8 | IVA 13 % y total | Centavos PHP y DECIMAL generado MariaDB | 73.99 + 9.62 = 83.61 confirmado en factura SQL | Implementado/probado 3 |
| R08 | D1; P7,8 | Confirmar, descontar stock, generar factura | app/shop.php purchase | Transacción, dos procesos concurrentes, stock y error SQL con rollback | Implementado/probado 3 |
| R09 | D1; P8 | Factura detallada e imprimir | factura.php; invoice_detail; vista real y CSS impresión | Factura persistida verificada (propiedad solo en historial; IDOR A en consulta individual); impresión/PDF pendiente | Datos comprobados 3 / impresión P6 |
| R10 | P9 | Historial de facturas del comprador | historial.php; consulta por comprador autenticado | Solo facturas propias; prueba cruzada entre compradores | Implementado/probado 3 |
| R11 | D1; P2,10 | Vendedor: alta y edición de productos propios | vendedor.php; app/management.php | Alta/edición propias; GET y POST ajenos rechazados | Implementado/probado 3 |
| R12 | P10 | Nombre, descripción, precio, stock e imagen | app/images.php; formulario de productos | Validación PHP; imagen auténtica recodificada; rechazo de falsa/extension/tamaño | Implementado/probado 3 |
| R13 | D1; P10 | Admin: CRUD de productos | admin-productos.php; save_product/delete_product | CRUD real; estado activo y detalle histórico preservado | Implementado/probado 3 |
| R14 | D1; P11 | Admin: CRUD de usuarios y roles | admin-usuarios.php; save_user/delete_user | CRUD, roles, baja lógica con referencias, sesión revocada | Implementado/probado 3 |
| R15 | P10,11 | Resumen general | Consulta SQL de métricas en app/web.php | Listados y métricas en HTTP/Edge; seed 459.50 preservado | Implementado/probado 3 |
| R16 | P6-11 | Estilo y navegación del anexo | CSS compartido; vistas reales en app/views/live | Inspección Edge escritorio; capturas; regresión de maquetas | Implementado 1–3 / móvil ampliado P6 |
| R17 | D1-3; P1,2,4 | Stack PHP puro/HTML/CSS/JS/mysqli, sin prohibidos | PHP puro, mysqli execute_query, HTML/CSS/JS sin paquetes web | Lectura de código y pruebas PHP/HTTP/BD reales | Implementado 3 / Ubuntu P5 |
| R18 | D1,2; P1,4 | VM Ubuntu Server 24.04 y Apache en host | configuración futura | Arranque VM y Apache real | P / 5 |
| R19 | P2,4 | MariaDB Docker, Compose, SQL, persistencia | compose.yaml; database/init; tests/database.test.php | 24 pruebas mysqli; marcador persiste tras reinicio/recreación | Implementado y probado Windows/Docker / 2 |
| R20 | D2; P4 | BD loopback 127.0.0.1:3306; sin internet/nube | Compose restringe publicación a loopback | Binding comprobado; otro equipo/red Ubuntu pendientes | Local comprobado 2 / P5 |
| R21 | D3; P3,9 | IDOR solo propiedad factura, manteniendo sesión | `invoice_detail()` en app/shop.php (sin `AND comprador_id`); ruta con sesión y rol comprador | Reproducción real Ana→factura 2 de Luis (REPORTES/evidencias/fase04-idor-reproduccion.txt); 6 pruebas de acotamiento (anónimo, vendedor, admin, inexistente, SQL, parámetro forjado) | Implementado/probado 4 |
| R22 | D3; P3,11 | HTTP 8081 diagnóstico ficticio separado sin enlaces | `diagnostico/index.html`; `deploy/apache/tiendalab-diagnostico.conf`; `tests/diagnostico.test.cjs`; `scripts/verificar-diagnostico.ps1` | 24 comprobaciones contra Apache 2.4.71 en contenedor (127.0.0.1:8081): datos ficticios, sin enlaces ni operaciones, solo GET/HEAD/OPTIONS, sin listado ni PHP; evidencia REPORTES/evidencias/fase04-diagnostico-8081.txt. Acceso desde otro equipo y Ubuntu pendientes | Implementado y probado en contenedor 4 / P5 |
| R23 | D3; P3 | Vulnerabilidades reproducibles y documentadas, mitigación | docs de seguridad futuras | Evidencias verificadas, exactamente dos elegidas | P / 4,6 |
| R24 | Prompt §4; D3 | Controles del resto: hash, SQL parametrizado, escape, CSRF, límites | auth.php/database.php/images.php; POST CSRF y escape | Pruebas de CSRF, sesiones, propiedad, consultas y errores; auditoría completa futura | Controles probados 3 / ampliar 6 |
| R25 | D3,4; P4 | GitFlow, commits y PR GitHub | main/develop/features; historial de módulos fase 3 | Pruebas antes de PR real hacia develop; main reservada | Fases 0–3 / entrega main P7 |
| R26 | D4; P4 | README: descripción, roles, arquitectura, carpetas | README.md y docs | Guía de inicio local, roles, seguridad y límites actualizados | D / 3; Ubuntu ampliar 5 |
| R27 | D4,5; P4 | Instalación reproducible y <=30 minutos | scripts Ubuntu futuros | VM limpia, reloj y registro real | P / 5,7 |
| R28 | D4; P4 | Cuentas y credenciales de prueba por rol | Seed ficticio conservado; registro y autenticación reales | Cuentas por rol probadas HTTP; hashes y seed comprobados | Implementado/probado 3 |
| R29 | D5 | Playbook real: reconocimiento, hallazgos, pasos, impacto, mitigaciones | documento futuro | Solo objetivos/horarios autorizados; no fabricar resultados | P / etapa de ataque |
| R30 | D5,6; P4 | Aprobación docente y explicación por estudiantes | aprobación declarada por usuario; guía de lectura | Validación administrativa externa | D / confirmación externa |
| R31 | D4-6; P4 | Fechas, red laboratorio, reglas de no daño | docs/ALCANCE.md | Comprobar entorno y calendario con docente | D / ejecución P5-7 |
| R32 | Prompt §5 | Dependencias e imágenes disponibles sin internet | `scripts/exportar.ps1 -Offline` (imagen MariaDB + SHA-256) y `scripts/exportar.ps1` (ZIP limpio auditado); guía sección 19 | Tar y ZIP generados y auditados; `docker load` en máquina limpia e instalación offline no ejecutados | Parcial 2 y exportación limpia / P5,7 |
| R33 | Prompt §6,7,9 y auditoría posterior | Reportes y revisión entre fases; detener antes de 3 | REPORTES/FASE_03_BACKEND.md | Reportes distinguen ejecución de recomendaciones; detener antes de 4/5 | D / 0–3 |
| R34 | Prompt §9 | Datos demo separados, sin altas/compras simuladas exitosas | demo/ y maquetas aisladas; app/views/live usa MariaDB | Operaciones reales sin fixtures estáticos; maquetas POST=405 | Implementado/probado 3 |
| R35 | Instrucción adicional del usuario | Guía técnica sencilla de seguridad y defensa, actualizada por fase | docs/GUIA_SEGURIDAD_Y_DEFENSA.md secciones 16–17 | Archivos, comandos, controles, pruebas, límites y explicación oral | D / 1–3; mantener 4–7 |

Las pruebas de fases futuras son criterios de aceptación, **no resultados ejecutados**. Las evidencias reales de fase 1 se enumeran en su reporte y archivos adjuntos.

## Registro histórico del cierre de fase 2

PR #5 integrado en develop mediante 19adb71, conservando ebf814f/da4e8b1. Tras integrar se repitieron 53 pruebas HTTP, 8 PHP, 3 JS y 24 mysqli antes/después de persistencia. R01/R04/R34 usan router explícito en preview; el frontend continúa con fixtures, sin conectar sus formularios a MariaDB. Linux/Apache y red externa siguen pendientes. R08, R21 y R22 no implementados. Evidencia en REPORTES/CIERRE_FASE_02_GITFLOW.md. Repositorio público: los PDF académicos con nombres/carnets se conservan por autorización; exportarlos no cambia esa exposición.

## Fase 3 vigente

Frontend conectado a MariaDB, autenticación/sesiones/roles, compras transaccionales y gestión implementados e integrados mediante [PR #7](https://github.com/Vasquezzz247/TiendaLab-SED/pull/7), merge dc361c05d7ee0b7931c1088a160fcee8741e8062. Pruebas en Windows/PHP y Docker Desktop: 107 HTTP/BD, 55 HTTP de regresión, 8 PHP, 3 JS y 24 de base original; ver reporte 03 y evidencia reproducible. No se alteraron esquema ni volumen. R21/R22/R23 siguen pendientes de fase 4: la propiedad de facturas se protege y no existe diagnóstico 8081. R18/R20 en Ubuntu, firewall/red y despliegue siguen pendientes de fase 5. No se modificó main ni la visibilidad pública.
