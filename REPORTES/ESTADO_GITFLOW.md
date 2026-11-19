# Estado de GitHub y GitFlow

Actualizado el 18/11/2026 para el cierre de fase 2. Este documento sustituye el estado anterior de preparación; los reportes antiguos conservan su contexto histórico.

## Repositorio y alcance

- URL: https://github.com/Vasquezzz247/TiendaLab-SED
- **Público**, cuenta Vasquezzz247; verificado mediante API (`private=false`). La publicación pública fue autorizada anteriormente. No se cambió la visibilidad en este cierre.
- `origin`: https://github.com/Vasquezzz247/TiendaLab-SED.git
- Predeterminada/entrega: `main`. Integración: `develop`.
- Se reutilizó el mismo repositorio. Sin force push, rebase, squash, borrado de ramas ni pérdida de commits.
- No se inició fase 3, no se implementaron vulnerabilidades ni se modificó la aplicación durante el cierre.

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

El commit de estos documentos y su propio merge se consultan en el PR documental y en el historial para evitar una referencia circular a su SHA. `main` conserva el SHA completo `98b499d01169def30fe277f0771efbaff903f8c7`. No corresponde aún abrir `develop` → `main`.

## Seguridad de publicación y PDF

Se revisaron `.gitignore`, el árbol publicado de GitHub y los 102 blobs históricos disponibles tras PR #5. No se encontraron `.env`, herramientas PHP, dependencias locales, temporales, claves privadas ni imágenes Docker exportadas. Se compararon los dos secretos actuales de `.env` contra los blobs en memoria, sin imprimirlos, sin coincidencias; también se buscaron patrones de tokens GitHub/claves privadas. Es una revisión acotada, no garantía de detectar cualquier secreto posible. `.env.example` sí se publica y solo contiene ejemplos, no secretos locales.

**Los PDF originales contienen nombres/carnets del equipo y son públicos.** La documentación también contiene rutas de Windows. Se conservan por instrucción del usuario; esta advertencia no cambia la visibilidad ni elimina datos del historial. Las cuentas de la tienda son ficticias.

`scripts/auditar-exportacion.py` verificó el ZIP creado con `git archive`: nombres exactos, una copia por PDF, contenido idéntico al archivo local y al blob Git, sin cambios en el estado Git por exportar. El nombre con acento tiene indicador UTF-8; el nombre ASCII no lo necesita. Evidencia: `evidencias/cierre02-exportacion.json`.

GitHub CLI no estaba disponible. Se usaron Git Credential Manager y la API oficial con credencial exclusivamente en memoria. El auxiliar de conexión permanece en `tmp`, ignorado. No se guardaron tokens en los reportes.

## Pruebas y pendientes

Después del merge #5 aprobaron 53 comprobaciones HTTP, 8 PHP, 3 JS, sintaxis de 22 archivos PHP y 24 comprobaciones mysqli antes y después de reinicio/recreación. MariaDB quedó saludable en `127.0.0.1:3306`; el dato marcador persistió y fue restaurado. Los intentos iniciales con acceso restringido fallaron por EACCES/pipe Docker; sus salidas se conservan junto a las repeticiones exitosas con acceso autorizado.

Evidencia y detalle: [cierre de fase 2](CIERRE_FASE_02_GITFLOW.md). Pendientes: revisión del usuario, fase 3, despliegue real Ubuntu/Apache, red desde otro equipo autorizado, instalación offline y cronometraje, pruebas visuales de selección de imagen/impresión, release y PR hacia main. No se configuraron políticas obligatorias de protección de ramas.
