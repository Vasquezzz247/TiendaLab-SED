# GitFlow en TiendaLab

Repositorio público (por autorización previa): <https://github.com/Vasquezzz247/TiendaLab-SED>. Los PDF originales incluyen nombres y carnets académicos accesibles públicamente. No hay reglas de protección de ramas ni revisores automáticos configurados: el uso de Pull Request está comprobado, pero no impuesto por GitHub.

## Ramas

| Rama | Uso | Estado |
| --- | --- | --- |
| `main` | Entrega estable | Estuvo en `98b499d` (preparación inicial) hasta la entrega; recibe la versión 1.0.0 por PR desde `release/1.0.0` y se etiqueta `v1.0.0` |
| `develop` | Integración | Contiene las fases 0 a 7 |
| `feature/*` | Una por módulo o corrección, desde `develop` | Ver tabla; se conservan sin borrar |
| `release/*` | Preparación de la entrega | `release/1.0.0` (CHANGELOG), con PR hacia `main` y de vuelta hacia `develop` |
| `hotfix/*` | Correcciones urgentes sobre `main` | Aún no ha sido necesaria |

## Pull Requests reales hacia `develop`

| PR | Rama | Contenido | Merge |
| --- | --- | --- | --- |
| [#1](https://github.com/Vasquezzz247/TiendaLab-SED/pull/1) | `feature/fase-00-preparacion` | Análisis y preparación | `207118d` |
| [#2](https://github.com/Vasquezzz247/TiendaLab-SED/pull/2) | `feature/fase-01-frontend` | Frontend y prototipos aislados | `71d64e8` |
| [#3](https://github.com/Vasquezzz247/TiendaLab-SED/pull/3), [#4](https://github.com/Vasquezzz247/TiendaLab-SED/pull/4) | `feature/gitflow-documentacion` | Registro de GitFlow | `006c6c2`, `99dd827` |
| [#5](https://github.com/Vasquezzz247/TiendaLab-SED/pull/5) | `feature/fase-02-base-datos` | MariaDB en Docker, esquema, seed | `19adb71` |
| [#6](https://github.com/Vasquezzz247/TiendaLab-SED/pull/6) | `feature/cierre-fase-02` | Cierre documental de la fase 2 | `4b5bbd5` |
| [#7](https://github.com/Vasquezzz247/TiendaLab-SED/pull/7), [#8](https://github.com/Vasquezzz247/TiendaLab-SED/pull/8) | `feature/fase-03-backend` | Backend PHP y su cierre | `dc361c0`, `c4856db` |
| [#9](https://github.com/Vasquezzz247/TiendaLab-SED/pull/9) | `feature/fix-limite-login` | Observación A: el límite de login solo cuenta fallos | `1bbd54c` |
| [#10](https://github.com/Vasquezzz247/TiendaLab-SED/pull/10) | `feature/fix-rol-vendedor-productos` | Observación B: rol de vendedor con productos | `d232af7` |
| [#11](https://github.com/Vasquezzz247/TiendaLab-SED/pull/11) | `feature/exportacion-limpia` | Observación C: exportación limpia y auditoría de ZIP | `0af08d6` |
| [#12](https://github.com/Vasquezzz247/TiendaLab-SED/pull/12) | `feature/fase-04-idor-facturas` | Vulnerabilidad A (IDOR) | `4b475d6` |
| [#13](https://github.com/Vasquezzz247/TiendaLab-SED/pull/13) | `feature/fase-04-diagnostico-8081` | Vulnerabilidad B (diagnóstico 8081) y reporte de fase 4 | `bd19217` |
| [#14](https://github.com/Vasquezzz247/TiendaLab-SED/pull/14) | `feature/fase-05-despliegue-ubuntu` | Despliegue en Ubuntu y scripts | `6d2916e` |
| [#15](https://github.com/Vasquezzz247/TiendaLab-SED/pull/15) | `feature/fase-06-auditoria` | Auditoría final contra Ubuntu | `753cedf` |
| [#16](https://github.com/Vasquezzz247/TiendaLab-SED/pull/16) | `feature/fase-07-entrega` | README de entrega, GitFlow y kit | `d23e3bc` |

Los reportes `REPORTES/FASE_XX_*.md` registran las pruebas que precedieron a cada integración. Los commits y los Pull Requests de las fases 3 a 7 se hicieron con la cuenta SrGaray (Samuel Garay), sin force push, rebase ni squash.

## Procedimiento de trabajo

1. Una feature parte de `develop` actualizada (`git fetch origin` y `git checkout -b feature/<tema> develop`).
2. Commits pequeños con mensajes descriptivos, conforme se completa cada módulo.
3. Se ejecutan las pruebas (`scripts/verificar-backend.ps1` y, si cambia el despliegue, `scripts/verificar-ubuntu.ps1`) antes de abrir el Pull Request.
4. Se publica la rama y se abre un Pull Request hacia `develop` (con `gh pr create`).
5. Se integra con **merge commit** para conservar los SHA y se sincroniza la rama local con `git merge --ff-only origin/develop`.

## Entrega a `main` (fase 7)

```sh
git checkout -b release/1.0.0 develop        # congelar la versión en una rama release/*
# (solo correcciones de documentación o de última hora, con sus pruebas)
git push -u origin release/1.0.0
gh pr create --base main --head release/1.0.0 --title "release 1.0.0"
# tras revisar y fusionar el PR: etiquetar y devolver los cambios a develop
git tag -a v1.0.0 -m "TiendaLab 1.0.0" && git push origin v1.0.0
```

`main` no se modifica hasta que el equipo autoriza esa fusión (en la entrega 1.0.0 la autorizó el equipo en la conversación del proyecto). Si aparece un fallo urgente en `main`, se corrige en `hotfix/*` y se integra en `main` y en `develop`.

Para inspeccionar el estado sin alterarlo: `git status -sb`, `git branch -vv`, `git log --oneline --all --graph`, `git ls-remote --heads origin`.
