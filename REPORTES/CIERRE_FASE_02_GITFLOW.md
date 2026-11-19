# Cierre de fase 2 — GitFlow y verificación

Fecha: 18/11/2026. Alcance: publicar e integrar lo ya implementado, verificar y documentar. **Fase 3 detenida hasta revisión del usuario.**

## 1. Resultado y repositorio

Repositorio [TiendaLab-SED](https://github.com/Vasquezzz247/TiendaLab-SED), **público** por autorización previa. No se modificó visibilidad. El código de fase 2 está integrado en `develop`; `main` no se modificó. El cierre solo cambia documentación, evidencias e incorpora un auxiliar de auditoría de exportación; no añade comportamiento a la tienda.

## 2. Commits conservados

| SHA | Trabajo |
| --- | --- |
| ebf814f | Rutas explícitas de preview y correcciones de auditoría |
| da4e8b1246950b8ce85a4c6185987743bfd70327 | MariaDB persistente, SQL y comprobaciones mysqli |
| 19adb714958a55547eb5e1d0950208bb7f8fc3e0 | Merge de fase 2 hacia develop |

Tras `git fetch origin`, los dos commits pedidos todavía aparecían en `origin/feature/fase-02-base-datos..feature/fase-02-base-datos`. Se publicaron con push normal. No hubo force push, rebase, squash, borrado ni reconstrucción del historial.

## 3. PR e integración

[PR #5: Fase 2: MariaDB persistente y correcciones de auditoría](https://github.com/Vasquezzz247/TiendaLab-SED/pull/5).

- Head real: `feature/fase-02-base-datos`, `da4e8b1246950b8ce85a4c6185987743bfd70327`.
- Base antes de integrar: `develop`, `99dd82747122ea234767ddf735416897f6b3bab5`.
- API devolvió `merged=true`; merge `19adb714958a55547eb5e1d0950208bb7f8fc3e0`.
- El merge mantiene los commits originales. Después se sincronizó develop con fast-forward.
- Se creó `feature/cierre-fase-02` desde develop para entregar este reporte y la evidencia posterior mediante un PR documental separado.

## 4. Ramas y estado de entrega

Ramas locales/remotas conservadas: `main` (`98b499d`), `develop` (merge de fase 2 `19adb71`), `feature/fase-00-preparacion` (`81e2814`), `feature/fase-01-frontend` (`bd88660`), `feature/gitflow-documentacion` (`1d02941`) y `feature/fase-02-base-datos` (`da4e8b1`). La rama de cierre parte de `19adb71`.

`main` sigue predeterminada y reservada para entrega, en `98b499d01169def30fe277f0771efbaff903f8c7`. No se abrió PR hacia ella. `develop` contiene fases 0–2; el PR documental adjunta estas observaciones sin modificar el código integrado. Los SHA del propio documento/merge se consultan en su PR para evitar autorreferencias imposibles.

## 5. Pruebas repetidas después de integrar

Entorno real: Windows, PHP portátil, Node y Docker Desktop con contenedor Linux MariaDB. Código comprobado: merge `19adb71`.

| Comprobación | Resultado observado | Evidencia |
| --- | --- | --- |
| Sintaxis PHP | 22 archivos app/demo/public aprobados | cierre02-frontend.txt |
| Escape, guardia y formato PHP | 8 aprobadas | cierre02-frontend.txt |
| Cálculo/cantidades JS | 3 aprobadas; 0 fallos | cierre02-frontend.txt |
| HTTP | 53 aprobadas; 11 pantallas y 13 assets | cierre02-frontend.txt |
| mysqli / datos / restricciones / permisos | 24 aprobadas antes y 24 después | cierre02-base.txt |
| Persistencia | Marcador modificado sobrevivió a restart y force-recreate; restaurado | cierre02-base.txt |
| Exposición de MariaDB | Solo 127.0.0.1:3306; volumen tiendalab_db_data | cierre02-base.txt |
| Salud final | Contenedor healthy | cierre02-base.txt |
| Publicación GitHub | Repo público, main predeterminada, ramas y PR #5 fusionado | cierre02-github.json |
| Exportaciones ZIP | PDF con nombres/bytes iguales, sin duplicados ni archivos excluidos | cierre02-exportacion.json |

Todas las evidencias están en `REPORTES/evidencias/`. Los intentos iniciales dentro del aislamiento de herramientas encontraron `EACCES` al conectar a localhost y acceso denegado al pipe de Docker. Se conservaron en `cierre02-frontend-intento-restringido.txt` y `cierre02-base-intento-restringido.txt`. Se repitieron los mismos verificadores con acceso autorizado y aprobaron. No se cambió el firewall, no se concedieron permisos extra a MariaDB ni se alteró el código para pasar las pruebas.

## 6. Exclusiones y secretos

`.gitignore` se mantiene: excluye `.env`, variantes locales salvo `.env.example`, PHP portátil, temporales, logs, claves, dependencias, backups y data. `git check-ignore` confirmó las rutas locales de `.env`, PHP, ZIP y tar de Docker. El árbol GitHub del merge no está truncado y coincide con las exclusiones verificadas.

El auxiliar `scripts/auditar-exportacion.py` recorre el árbol HEAD y todos los objetos alcanzables por las referencias locales/remotas disponibles. En el merge de fase 2 revisó 102 blobs y comparó los dos secretos actuales de `.env` solamente en memoria: ninguna coincidencia. También buscó patrones de tokens GitHub y cabeceras de claves privadas. No se publicaron los secretos, el token de acceso, los binarios PHP ni el tar Docker. `.env.example` contiene únicamente marcadores de reemplazo; las contraseñas ficticias de demo no son claves administrativas SQL. La revisión no garantiza detectar secretos desconocidos o con otros formatos.

## 7. Integridad de los PDF en ZIP

Se comprobaron dos exportaciones del commit `19adb71`: `git archive` local y descarga real desde codeload.github.com. ZIP y tar permanecen en `tmp`, ignorado. Se compararon nombres Unicode exactos, unicidad y bytes contra el árbol Git; para el ZIP local también contra los originales de la carpeta. `.gitattributes` ya marca los PDF como binarios y no fue alterado.

| Nombre exacto | SHA-256 |
| --- | --- |
| DefinicióndelProyecto(1).pdf | 4c13c5dd8ddc4e371dc6d6c4664c02afc3ff8424e9b864c77d37a1b534d02e50 |
| Propuesta_TiendaLab.pdf | a20a48ccbf99f0ee12b84a52fcedbc06583403c3b9b059c8ed15552215757d9b |

Una copia de cada PDF por archivo ZIP, sin renombrar originales, sin duplicados ni eliminaciones en Git. El nombre acentuado del ZIP local lleva indicador UTF-8; el nombre ASCII no necesita ese indicador. La primera captura JSON por consola mostró problemas de codificación; se reemplazó por escritura directa UTF-8 desde Python y se repitió la comprobación, sin modificar ningún PDF.

**Advertencia académica:** ambos PDF contienen nombres y carnets del equipo. El repositorio es público y esa información puede copiarse; también hay rutas locales en documentación. Se registra la exposición autorizada, sin cambiar visibilidad ni afirmar que esos datos sean secretos excluidos.

## 8. Documentación y archivos de cierre

Se actualizaron `README.md`, `docs/GITFLOW.md`, `docs/MATRIZ_REQUISITOS.md`, `REPORTES/ESTADO_GITFLOW.md`, `docs/GUIA_SEGURIDAD_Y_DEFENSA.md` y la instrucción vigente de `AGENTS.md`. Se añadieron este reporte, evidencias y `scripts/auditar-exportacion.py`. Los informes históricos conservan el contexto de su fecha, mientras los documentos vigentes aclaran publicación pública e integración real.

La guía explica qué protege el volumen, el binding, las restricciones SQL, los hashes, los permisos y `.gitignore`, con comandos realmente ejecutados y límites. Apache, sesiones, autenticación, roles de servidor, firewall y red Ubuntu siguen identificados como pendientes. Las dos vulnerabilidades previstas permanecen sin implementar.

## 9. Pendientes y límites

- Revisión del usuario antes de cualquier fase 3. No hay backend web conectado a la BD, sesiones, compras ni autorización real por rol.
- Ubuntu Server/Apache, configuración de red y firewall, prueba desde otro equipo autorizado y despliegue offline no ejecutados.
- No se cronometró una instalación limpia ni se probó `docker load` en Ubuntu.
- Selección visual de imagen y exportación/impresión de factura siguen pendientes.
- Release, PR hacia main y políticas obligatorias de protección/revisión no configuradas.

## 10. Explicación para la defensa

“La fase 2 está publicada con sus commits originales y se integró por un PR real. GitFlow permite ver qué se cambió y cuándo; no reemplaza las pruebas ni protege por sí solo una rama. La base guarda datos ficticios consistentes, con privilegios limitados y persistencia comprobada. El frontend todavía no usa esa base. Conservé los PDF originales y verifiqué que al descargar el proyecto sus nombres y contenido no cambian. Lo probado fue Windows/Docker Desktop; no presento como realizadas las pruebas de Ubuntu.”
