# Matriz de cumplimiento

Fuentes: D = definición oficial, P = propuesta; numeración física. Estado al cierre se amplía con `REPORTES/FASE_01_FRONTEND.md`. **V** = vista de prototipo implementada; no equivale a backend funcional. **P** = pendiente en fase indicada. **D** = documentado.

| ID | Fuente | Requisito | Implementación / destino | Prueba y evidencia esperada | Estado / fase |
| --- | --- | --- | --- | --- | --- |
| R01 | D1; P2,6 | Index público, catálogo, imágenes, precios, stock, buscador | public/index.php; catálogo compartido | HTTP 200, búsqueda con/sin resultados, navegación | V / 1 |
| R02 | D1; P2,6 | Login correo/contraseña y cierre | public/login.php; sesiones futuras | Validación visual; luego credenciales válidas/erróneas y logout | V / backend 3 |
| R03 | D1; P2,7 | Registro siempre comprador | public/register.php | Confirmación coincide, formato correo; luego rol en BD | V / backend 3 |
| R04 | D1; P2,3 | Autenticación y autorización por rol | Prototipos separados y guardia local; middleware futuro | Prototipo desactivado=404; posteriormente matriz de roles en servidor | Aislamiento 1 / P3 |
| R05 | D1; P7 | Comprador selecciona cantidades y agrega | prototipo comprador; JS nativo | 1..stock, contador y suma; no sesión fingida | V / 1 |
| R06 | P8 | Quitar, cantidades, carrito vacío y resumen | prototipo carrito | Vacío; eliminación; 39.99+34=73.99 | V / 1 |
| R07 | P8 | IVA 13 % y total | cálculo entero en centavos | 7399+962=8361; redondeo por total | V / cálculo servidor 3 |
| R08 | D1; P7,8 | Confirmar, descontar stock, generar factura | operación transaccional futura | Compra real, rollback, stock insuficiente/concurrencia | P / 3,6 |
| R09 | D1; P8 | Factura detallada e imprimir | prototipo factura con aviso | Líneas, totales y estilos de impresión | V / generación 3 |
| R10 | P9 | Historial de facturas del comprador | prototipo historial | Enlaces y totales consistentes; luego filtro por sesión | V / backend 3 |
| R11 | D1; P2,10 | Vendedor: alta y edición de productos propios | prototipo vendedor; formulario compartido | Abrir edición, validación, preview local; propiedad futura | V / backend 3 |
| R12 | P10 | Nombre, descripción, precio, stock e imagen | app/components/product-form.php | Obligatorios, precio >0, stock entero >=0, JPG/PNG/WEBP <=2 MB | V / servidor 3 |
| R13 | D1; P10 | Admin: CRUD de productos | prototipo admin-productos | Nuevo/editar/eliminar presentan borrador o aviso, sin éxito ficticio | V / backend 3 |
| R14 | D1; P11 | Admin: CRUD de usuarios y roles | prototipo admin-usuarios | Alta, edición de datos, roles, aviso de eliminación | V / backend 3 |
| R15 | P10,11 | Resumen general | tarjetas de métricas ficticias | Totales coherentes con datos demo | V / consulta 3 |
| R16 | P6-11 | Estilo y navegación del anexo | CSS y componentes locales | Revisión visual escritorio/móvil, enlaces y controles | V / 1 |
| R17 | D1-3; P1,2,4 | Stack PHP puro/HTML/CSS/JS/mysqli, sin prohibidos | estructura sin paquetes web | Inspección de código/dependencias | Parcial / 1-3 |
| R18 | D1,2; P1,4 | VM Ubuntu Server 24.04 y Apache en host | configuración futura | Arranque VM y Apache real | P / 5 |
| R19 | P2,4 | MariaDB Docker, Compose, SQL, persistencia | base futura | Reinicio conserva datos; consultas mysqli | P / 2,3 |
| R20 | D2; P4 | BD loopback 127.0.0.1:3306; sin internet/nube | Compose y red futura | Bind real y prueba desde otro equipo autorizado | P / 2,5 |
| R21 | D3; P3,9 | IDOR solo propiedad factura, manteniendo sesión | factura.php futura | Dos compradores ficticios, antes/después, evidencia real | P / 4 |
| R22 | D3; P3,11 | HTTP 8081 diagnóstico ficticio separado sin enlaces | vhost y sitio futuro | Acceso desde laboratorio; sin secretos/control del host | P / 4,5 |
| R23 | D3; P3 | Vulnerabilidades reproducibles y documentadas, mitigación | docs de seguridad futuras | Evidencias verificadas, exactamente dos elegidas | P / 4,6 |
| R24 | Prompt §4; D3 | Controles del resto: hash, SQL parametrizado, escape, CSRF, límites | escape en plantillas; controles restantes futuros | Sin SQLi/XSS/RCE accidental; matriz de seguridad | Parcial / 1,3,6 |
| R25 | D3,4; P4 | GitFlow, commits y PR GitHub | ramas locales, docs/GITFLOW.md | git log/branch; PR reales cuando exista remoto | Local 0,1 / remoto P7 |
| R26 | D4; P4 | README: descripción, roles, arquitectura, carpetas | README.md y docs/ALCANCE.md | Lectura y enlaces comprobados | D / 0,1; ampliar 7 |
| R27 | D4,5; P4 | Instalación reproducible y <=30 minutos | scripts Ubuntu futuros | VM limpia, reloj y registro real | P / 5,7 |
| R28 | D4; P4 | Cuentas y credenciales de prueba por rol | seed futuro | Acceso real con cada cuenta; no datos personales | P / 2,3,7 |
| R29 | D5 | Playbook real: reconocimiento, hallazgos, pasos, impacto, mitigaciones | documento futuro | Solo objetivos/horarios autorizados; no fabricar resultados | P / etapa de ataque |
| R30 | D5,6; P4 | Aprobación docente y explicación por estudiantes | aprobación declarada por usuario; guía de lectura | Validación administrativa externa | D / confirmación externa |
| R31 | D4-6; P4 | Fechas, red laboratorio, reglas de no daño | docs/ALCANCE.md | Comprobar entorno y calendario con docente | D / ejecución P5-7 |
| R32 | Prompt §5 | Dependencias e imágenes disponibles sin internet | procedimiento offline futuro | Instalar sin conectividad externa | P / 5,7 |
| R33 | Prompt §6,7,9 | Fases 0/1, reportes de 10 puntos, detener antes de 2 | REPORTES/ | Reportes distinguen implementado y ejecutado | D / 0,1 |
| R34 | Prompt §9 | Datos demo separados, sin altas/compras simuladas exitosas | demo/; formularios sin envío; prototipo local | POST rechazado, acciones informativas, sin base/sesión | V / 1 |
| R35 | Instrucción adicional del usuario | Guía técnica sencilla de seguridad y defensa, actualizada por fase | docs/GUIA_SEGURIDAD_Y_DEFENSA.md | Comandos ejecutados separados de Ubuntu recomendado, archivos, pruebas, controles y mitigaciones | D / 1; mantener 2-7 |

Las pruebas de fases futuras son criterios de aceptación, **no resultados ejecutados**. Las evidencias reales de fase 1 se enumeran en su reporte y archivos adjuntos.

## Actualización fase 2

Prevalece sobre los estados históricos de la tabla: R19 implementado y probado localmente (Compose/SQL/volumen, reinicio y recreación); R20 publicación loopback comprobada por Docker, red Ubuntu/segundo equipo pendiente; R28 cinco cuentas con hash verificadas en BD, login pendiente de fase 3; R32 imagen exportada, instalación offline Ubuntu pendiente; R25 GitHub público por autorización y PR 1-4 históricos, esta fase sin PR/integración; R35 guía actualizada. R01/R04/R34 usan router explícito en preview; suite Windows aprobada, Linux/Apache pendientes. R08, R21 y R22 no implementados. Evidencia en REPORTES/FASE_02_BASE_DATOS_DOCKER.md.
