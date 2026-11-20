# Estado de GitHub y GitFlow

Actualizado el 18/11/2026. **El estado vigente de fase 3 está al final de este documento.** Las secciones de fase 2 conservan su contexto histórico y no describen el backend actual.

## Repositorio y alcance

- URL: https://github.com/Vasquezzz247/TiendaLab-SED
- **Público**, cuenta Vasquezzz247; verificado mediante API (`private=false`). La publicación pública fue autorizada anteriormente. No se cambió la visibilidad en este cierre.
- `origin`: https://github.com/Vasquezzz247/TiendaLab-SED.git
- Predeterminada/entrega: `main`. Integración: `develop`.
- Se reutilizó el mismo repositorio. Sin force push, rebase, squash, borrado de ramas ni pérdida de commits.
- Durante el cierre histórico de fase 2 no se inició fase 3 ni se modificó la aplicación. La fase 3 fue autorizada e integrada posteriormente; las vulnerabilidades siguen pendientes.

## Commits publicados e integraciones

| Commit | Contenido |
| --- | --- |
| 98b499d | Documentos originales y base de main |
| 81e2814 | Preparación de fase 0 |
| 5deaa9c, fcba528, bd88660 | Frontend, seguridad/evidencias y exclusiones |
| 207118d, 71d64e8 | Merges de PR #1 y #2 |
| c99732d, 006c6c2 | Documentación y merge PR #3 |
| 525f5de, 1d02941, 99dd827 | Cierre anterior y merge PR #4 |
| ebf814f | Corrección de rutas y observaciones de auditoría |
| da4e8b1 | MariaDB persistente, SQL, permisos y pruebas mysqli |
| 19adb714958a55547eb5e1d0950208bb7f8fc3e0 | Merge real PR #5, conserva ambos commits de fase 2 |

Los dos commits de fase 2 no estaban publicados al iniciar el cierre. Se publicó la rama existente y se integró el PR; no se reconstruyó el historial.

| PR real | Integración | Estado / merge |
| --- | --- | --- |
| [#1](https://github.com/Vasquezzz247/TiendaLab-SED/pull/1) | preparación → develop | Fusionado / 207118d |
| [#2](https://github.com/Vasquezzz247/TiendaLab-SED/pull/2) | frontend → develop | Fusionado / 71d64e8 |
| [#3](https://github.com/Vasquezzz247/TiendaLab-SED/pull/3) | documentación → develop | Fusionado / 006c6c2 |
| [#4](https://github.com/Vasquezzz247/TiendaLab-SED/pull/4) | cierre anterior → develop | Fusionado / 99dd827 |
| [#5](https://github.com/Vasquezzz247/TiendaLab-SED/pull/5) | fase 2 → develop | Fusionado / 19adb71 |
| [#6](https://github.com/Vasquezzz247/TiendaLab-SED/pull/6) | cierre documental → develop | PR real de este informe; SHA de su propio merge en el enlace |

## Ramas locales y remotas

Instantánea comprobada después de PR #5; las seis primeras tienen equivalente `origin/<rama>` con el mismo SHA:

| Rama | SHA / finalidad |
| --- | --- |
| main | 98b499d; sin cambios |
| develop | 19adb71; fases 0–2 integradas |
| feature/fase-00-preparacion | 81e2814 |
| feature/fase-01-frontend | bd88660 |
| feature/gitflow-documentacion | 1d02941 |
| feature/fase-02-base-datos | da4e8b1 |
| feature/cierre-fase-02 | Rama documental creada desde 19adb71; publicación mediante PR de cierre |

El commit inicial del cierre es `cf1f807627a16dc31b74f2abd6285a35fd9f5193`, publicado en `feature/cierre-fase-02` con seguimiento de origin. El [PR documental #6](https://github.com/Vasquezzz247/TiendaLab-SED/pull/6) incorpora ese commit y el enlace al propio PR. Al entregar, `develop` debe estar sincronizada con el merge remoto de #6 y contener código de fase 2 más este cierre; su SHA exacto se consulta en el PR para evitar una referencia circular al mismo documento. La verificación final comprueba esa condición antes de dar el cierre por terminado. `main` conserva el SHA completo `98b499d01169def30fe277f0771efbaff903f8c7`. No corresponde aún abrir `develop` → `main`.

## Seguridad de publicación y PDF

Se revisaron `.gitignore`, el árbol publicado de GitHub y los 102 blobs históricos disponibles tras PR #5. No se encontraron `.env`, herramientas PHP, dependencias locales, temporales, claves privadas ni imágenes Docker exportadas. Se compararon los dos secretos actuales de `.env` contra los blobs en memoria, sin imprimirlos, sin coincidencias; también se buscaron patrones de tokens GitHub/claves privadas. Es una revisión acotada, no garantía de detectar cualquier secreto posible. `.env.example` sí se publica y solo contiene ejemplos, no secretos locales.

**Los PDF originales contienen nombres/carnets del equipo y son públicos.** La documentación también contiene rutas de Windows. Se conservan por instrucción del usuario; esta advertencia no cambia la visibilidad ni elimina datos del historial. Las cuentas de la tienda son ficticias.

`scripts/auditar-exportacion.py` verificó el ZIP creado con `git archive`: nombres exactos, una copia por PDF, contenido idéntico al archivo local y al blob Git, sin cambios en el estado Git por exportar. El nombre con acento tiene indicador UTF-8; el nombre ASCII no lo necesita. Evidencia: `evidencias/cierre02-exportacion.json`.

GitHub CLI no estaba disponible. Se usaron Git Credential Manager y la API oficial con credencial exclusivamente en memoria. El auxiliar de conexión permanece en `tmp`, ignorado. No se guardaron tokens en los reportes.

Antes de publicar el cierre `cf1f807` se repitió el escaneo: 116 blobs históricos, cero archivos excluidos y cero coincidencias con los dos secretos locales. La evidencia `evidencias/cierre02-prepublicacion.json` conserva ese punto de control. La revisión del ZIP GitHub corresponde al merge de código #5; la exportación local se repite sobre el cierre.

## Pruebas y pendientes

Después del merge #5 aprobaron 53 comprobaciones HTTP, 8 PHP, 3 JS, sintaxis de 22 archivos PHP y 24 comprobaciones mysqli antes y después de reinicio/recreación. MariaDB quedó saludable en `127.0.0.1:3306`; el dato marcador persistió y fue restaurado. Los intentos iniciales con acceso restringido fallaron por EACCES/pipe Docker; sus salidas se conservan junto a las repeticiones exitosas con acceso autorizado.

Evidencia y detalle: [cierre de fase 2](CIERRE_FASE_02_GITFLOW.md). Pendientes: revisión del usuario, fase 3, despliegue real Ubuntu/Apache, red desde otro equipo autorizado, instalación offline y cronometraje, pruebas visuales de selección de imagen/impresión, release y PR hacia main. No se configuraron políticas obligatorias de protección de ramas.

## Actualización posterior: fase 3

El estado de las secciones anteriores corresponde al cierre de fase 2. El usuario autorizó después fase 3: backend PHP/mysqli completo, sin fases 4/5. Se creó `feature/fase-03-backend` desde develop sincronizada en `4b5bbd5`.

- Commits publicados: `edf2df6`, `930319b`, `942eb79`, `9fd70ce`, `4d28092`, `4edff06`.
- **[PR #7](https://github.com/Vasquezzz247/TiendaLab-SED/pull/7)**: feature/fase-03-backend → develop, fusionado. Merge: `dc361c05d7ee0b7931c1088a160fcee8741e8062`.
- `origin/develop` contiene el backend probado. El cierre documental continúa en la misma feature desde ese merge; develop local se sincroniza al terminar.
- `main` y `origin/main`: `98b499d01169def30fe277f0771efbaff903f8c7`; predeterminada y sin cambios. Visibilidad pública, sin modificación.
- Las ramas históricas locales/remotas permanecen: preparación `81e2814`, frontend `bd88660`, documentación `1d02941`, base de datos `da4e8b1`, cierre de fase 2 `f2ff93b`. No se borró ni reescribió ninguna.
- Evidencia previa a publicación: 189 blobs históricos y dos secretos locales comparados sin divulgar valores; PDF íntegros, nombres preservados, archivos excluidos ausentes. [JSON](evidencias/fase03-publicacion.json).

Pruebas reales: 107 HTTP/BD, 55 HTTP de regresión, 8 PHP, 3 JS y 24 de base original, con rollback, concurrencia y preservación de filas. Detalles y límites en [FASE_03_BACKEND.md](FASE_03_BACKEND.md). Pendientes vigentes: revisión externa de fase 3; fases 4/5/6, validaciones adicionales enumeradas allí y futura release hacia main. No hay protección obligatoria de ramas configurada.

Cierre documental: **[PR #8](https://github.com/Vasquezzz247/TiendaLab-SED/pull/8)**, desde la misma `feature/fase-03-backend` hacia `develop`, publica este registro después del merge funcional #7. Incluye `5ba3965` y el commit que incorpora este enlace. Su página es la referencia verificable para el estado y SHA de su propio merge; ese SHA se genera después de aprobar estos documentos. Al finalizar, develop local se sincroniza con origin/develop; main permanece en 98b499d. No se crea una rama de fase 4.
