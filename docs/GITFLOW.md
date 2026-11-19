# GitFlow local y GitHub

Estado al 18/11/2026. Repositorio **público**: https://github.com/Vasquezzz247/TiendaLab-SED. `origin` apunta al mismo repositorio con sufijo `.git`. La creación privada inicial pertenece al historial; la visibilidad cambió después por autorización expresa. Este cierre no la modifica. Los PDF originales incluyen nombres/carnets académicos accesibles públicamente.

## Ramas e integraciones reales

- `main`: predeterminada y reservada para entrega estable; sigue en `98b499d01169def30fe277f0771efbaff903f8c7`.
- `develop`: integración de fases 0, 1 y 2. El merge de fase 2 es `19adb714958a55547eb5e1d0950208bb7f8fc3e0`; el cierre documental se prepara desde ese commit en `feature/cierre-fase-02`.
- `feature/fase-00-preparacion` → `develop`: [PR #1](https://github.com/Vasquezzz247/TiendaLab-SED/pull/1), merge `207118d`.
- `feature/fase-01-frontend` → `develop`: [PR #2](https://github.com/Vasquezzz247/TiendaLab-SED/pull/2), merge `71d64e8`.
- `feature/gitflow-documentacion` → `develop`: [PR #3](https://github.com/Vasquezzz247/TiendaLab-SED/pull/3), merge `006c6c2`, y [PR #4](https://github.com/Vasquezzz247/TiendaLab-SED/pull/4), merge `99dd827`.
- `feature/fase-02-base-datos` → `develop`: [PR #5](https://github.com/Vasquezzz247/TiendaLab-SED/pull/5), fusionado. Conserva `ebf814f` y `da4e8b1`, publicados sin reescribirlos.

Frontend ya descendía de preparación: se respetó esa relación al integrar primero #1. La fase 2 partía del cierre anterior en `develop`. No se crearon commits para simular trabajo ni se eliminaron ramas antiguas.

## Procedimiento de trabajo

Una feature parte de `develop`, se publica, se revisa con un PR y se integra mediante merge commit para conservar los SHA. Después se sincroniza la rama local por `git fetch origin` y `git merge --ff-only origin/develop`. No se usa force push, rebase ni squash en estas integraciones.

`release/*`, el PR hacia `main` y `hotfix/*` se crean cuando corresponda una entrega o corrección real. Todavía no existe una versión completa de la tienda para integrar a `main`. No se configuraron reglas obligatorias de protección de ramas ni revisores automáticos; el uso de PR comprobado no implica esas protecciones.

Para inspeccionar el estado sin alterarlo:

```sh
git status --short --branch
git branch -vv
git log --oneline --all --graph
git remote -v
git ls-remote --heads origin
```

El [estado de GitFlow](../REPORTES/ESTADO_GITFLOW.md) y el [cierre de fase 2](../REPORTES/CIERRE_FASE_02_GITFLOW.md) registran referencias, pruebas y pendientes. Fase 3 requiere nueva autorización.
