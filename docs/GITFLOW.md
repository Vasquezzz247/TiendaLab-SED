# GitFlow local y continuación en GitHub

`main` se reserva para entrega estable; `develop` para integración. La preparación vive en `feature/fase-00-preparacion` y el frontend en `feature/fase-01-frontend`. No se integran cambios a las ramas permanentes mediante merges que aparenten un PR remoto. La rama de frontend parte del commit de preparación para permitir revisar el conjunto; al crear GitHub se abrirá primero el PR de preparación a develop y luego el de frontend.

No hay remoto suministrado. No se crea un repositorio público ni se inventan PR. Usar la identidad Git ya configurada, sin modificar configuración global. `release/*` y `hotfix/*` se crean cuando exista una entrega o corrección real, no como ramas vacías.

Revisión local:

```sh
git status --short --branch
git branch --list
git log --oneline --all --graph
git diff develop...feature/fase-01-frontend --stat
git remote -v
```

Fases posteriores: ramas por módulo, commits comprensibles, PR hacia develop, release probada hacia main y develop; hotfix desde main hacia ambas. La revisión del usuario al cerrar cada fase sigue siendo obligatoria.
