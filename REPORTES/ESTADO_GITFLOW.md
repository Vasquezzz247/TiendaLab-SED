# Estado de GitHub y GitFlow

Fecha: 18/11/2026. Trabajo limitado a publicación, control de versiones y documentación; no se inició fase 2 ni se modificó el funcionamiento de la aplicación.

## Repositorio

- URL: https://github.com/Vasquezzz247/TiendaLab-SED
- Privado, cuenta Vasquezzz247. Creado sin README automático para no introducir una raíz de historial distinta.
- origin: https://github.com/Vasquezzz247/TiendaLab-SED.git
- Rama predeterminada: main. Rama de integración: develop.
- Se reutilizó el repositorio local existente. Sin force push, rebase, squash, eliminación de ramas ni pérdida de commits.

## Commits publicados

| Commit | Contenido |
| --- | --- |
| 98b499d | Documentos originales y repositorio |
| 81e2814 | Análisis y preparación de fase 0 |
| 5deaa9c | Frontend y pruebas |
| fcba528 | Seguridad, defensa y evidencias |
| bd88660 | Exclusiones de secretos y dependencias |
| 207118d | Merge real de PR #1 |
| 71d64e8 | Merge real de PR #2 |

El commit que contiene este reporte y su merge documental también se publican; sus SHA se consultan en el historial, evitando una referencia circular al propio commit.

## Pull Requests reales

1. [PR #1: preparación → develop](https://github.com/Vasquezzz247/TiendaLab-SED/pull/1): fusionado, merge 207118d.
2. [PR #2: frontend → develop](https://github.com/Vasquezzz247/TiendaLab-SED/pull/2): fusionado, merge 71d64e8.
3. El reporte y actualización de instrucciones se integran desde `feature/gitflow-documentacion` mediante un PR documental adicional, enlazado en la sección de cierre.

La rama frontend ya descendía de preparación. Por ello se fusionó primero PR #1 y después PR #2. No se reconstruyó ni inventó el historial. Las integraciones utilizan merge commits para conservar los SHA originales.

## Ramas locales y remotas

Todas se conservan localmente y se publican bajo origin:

- main: 98b499d, base original; predeterminada y reservada para entrega.
- develop: fases 0 y 1 integradas, más el reporte documental al cierre.
- feature/fase-00-preparacion: 81e2814.
- feature/fase-01-frontend: bd88660.
- feature/gitflow-documentacion: reporte y actualización de instrucciones.
- feature/fase-02-base-datos: se crea desde develop tras integrar el reporte, sin commits de implementación ni SQL/Compose.

No se abre develop → main todavía: no existe una versión estable completa de la tienda. Ese PR corresponde a la preparación de entrega después de las fases y pruebas necesarias. No se crearon ramas release/hotfix vacías para aparentar trabajo.

## Revisión de publicación y seguridad

Se revisaron archivos versionados y `.gitignore`. PHP portátil, ZIP, tmp, logs y .env ya estaban ignorados. Se añadieron .env.*, excepcion .env.example, claves .pem/.key, node_modules, vendor, configuración local del editor, backups y data. No se encontraron archivos versionados con los patrones de credenciales inspeccionados ni coincidencias de tokens GitHub/claves privadas en el escaneo textual. Esto es una revisión acotada, no un certificado de ausencia absoluta de secretos.

Los PDF académicos originales contienen los nombres/carnets del equipo y la documentación incluye rutas locales del equipo. Se conservan como fuentes del proyecto autorizado dentro del repositorio **privado**; no deben hacerse públicos sin revisar esos datos. Las capturas de la tienda contienen datos ficticios. No se subieron credenciales de Git/GitHub ni PHP portátil.

GitHub CLI no estaba instalado. Se usaron Git Credential Manager y la API oficial de GitHub con la credencial existente exclusivamente en memoria; nunca se imprimió ni se guardó el token. El auxiliar de publicación vive en tmp, ignorado, y no contiene credenciales literales.

## Verificación y pendientes

Verificación: estado limpio antes de publicar; historial de cuatro commits originales; push de ramas; respuestas reales de creación y fusión de PR; consulta API de privacidad, rama predeterminada, ramas y PR; fetch y comparación con referencias remotas al cierre. Los comandos quedan en la guía de seguridad.

Pendientes: autorización para implementar fase 2; futuras release y PR hacia main; pruebas Ubuntu y cronometraje. No se configuraron revisores obligatorios ni reglas de protección de ramas: GitFlow se organizó con ramas y PR reales, sin afirmar políticas adicionales no verificadas.
