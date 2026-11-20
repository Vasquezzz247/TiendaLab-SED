# Fase 7 — GitHub y entrega final

Fecha: 19/11/2026. Autorizada por el usuario en la conversación (sin prompt externo). No se cambiaron tecnologías, arquitectura ni las vulnerabilidades elegidas.

## 1. Objetivo

Dejar el repositorio listo para la entrega: README completo según la definición oficial, documentación de GitFlow, un kit de instalación sin internet, un ensayo de instalación desde cero y la integración estable hacia `main` mediante `release/*`.

## 2. Requisitos cubiertos

| Requisito de la definición | Estado |
| --- | --- |
| README: descripción y roles | Hecho (sección 1 del README) |
| README: arquitectura, tecnologías, base de datos, carpetas y diagrama | Hecho, con diagramas Mermaid |
| README: guía de instalación desde la creación de la VM | Hecho; pasos 2 a 5 ejecutados de verdad, paso 1 probado en parte (ver sección 8) |
| README: usuarios y credenciales de prueba por rol | Hecho |
| README: vulnerabilidades (cuáles, dónde, cómo se introdujeron) con reproducción y mitigación | Hecho |
| README: flujo de trabajo en GitHub | Hecho, más `docs/GITFLOW.md` con los 15 PR reales |
| Instalación en menos de 30 minutos, ensayada | **Parcial**: `instalar.sh` 4 min 54 s; el ensayo completo desde cero no terminó |
| `main` y `develop`, `feature/*`, `release/*`, PR | `feature/*` y PR a `develop` hechos; `release/*` y PR a `main`: ver sección 10 |

## 3. Archivos creados y modificados

`README.md` (reescrito), `docs/GITFLOW.md` (tabla real de PR y procedimiento de release), `scripts/exportar.ps1` (modo `-Kit`), `REPORTES/FASE_07_ENTREGA.md`.

## 4. Funcionalidades implementadas

- **README de entrega** con los seis apartados que exige la definición, diagramas de arquitectura y base de datos, y una sección final de límites sin maquillar.
- **`exportar.ps1 -Kit [-Iso <ruta>]`**: arma una carpeta con el ZIP limpio y auditado, los 29 `.deb`, la imagen de MariaDB, las sumas SHA-256 de todos los archivos, las instrucciones (`LEEME-KIT.txt`) y, si se indica, el ISO de Ubuntu verificado contra su hash oficial.

## 5. Instrucciones exactas de ejecución

```powershell
.\scripts\exportar.ps1 -Kit -Iso C:\ruta\ubuntu-24.04.5-live-server-amd64.iso   # kit completo en dist\TiendaLab-kit-<commit>
```

Requiere que `offline/debs/` (29 paquetes) exista; la forma de prepararlo está en `docs/INSTALACION_UBUNTU.md`, sección 6. La instalación está en el README, sección 3.

## 6. Pruebas y evidencias reales

| Prueba | Resultado |
| --- | --- |
| `exportar.ps1 -Kit` (sin ISO) | Kit de **199,4 MB** en 9 s; auditoría del ZIP sin hallazgos; **33 archivos con suma SHA-256 y 0 sumas que no coinciden** al recalcularlas |
| `crear-vm.ps1` con la versión final | Creó la VM `TiendaLab-Ensayo` sin errores en 16 s |
| Suite de 120 pruebas, `verificar.sh` 34/34, instalador | Sin cambios de código en esta fase; resultados de las fases 5 y 6 siguen vigentes |

## 7. Problemas encontrados y soluciones

1. **Ensayo desde cero interrumpido.** La VM de ensayo (creada con la versión final de `crear-vm.ps1`) no avanzó en el instalador de Ubuntu: a los 10 minutos su disco seguía en 2 MB y la consola mostraba trazas de kernel de tareas bloqueadas (el mismo síntoma visto antes en otra VM). Había otra VM encendida en el mismo equipo. Se apagó con normalidad y se eliminó. **El ensayo completo sigue pendiente.**
2. El `Write` de la herramienta exigía releer `README.md` antes de reemplazarlo; sin impacto.

## 8. Pendientes

- **Repetir el ensayo completo desde cero con una sola VM encendida** (crear VM, copiar kit, instalar, verificar) y registrar los tiempos reales. Hasta entonces, la instalación de Ubuntu con el script final sigue sin validarse de principio a fin.
- Añadir el ISO al kit para el USB (`-Iso`, 4 GB).
- Confirmar con el docente cómo se cuentan los 30 minutos (instalar Ubuntu tardó ~25 min en la red de pruebas).
- Probar desde otro equipo real del Laboratorio 4.
- VM exportada (`.ova`) e instantánea limpia, con la VM apagada.
- Opcionales: PDF de factura, HTTPS, tablas en móvil.

## 9. Desviaciones respecto de los PDF

Ninguna en tecnologías, vistas, roles ni vulnerabilidades. El repositorio es público por autorización previa y conserva los PDF originales con nombres y carnets.

## 10. Estado final y GitFlow

Rama `feature/fase-07-entrega` con commits de Samuel Garay (cuenta SrGaray, sin firma de Claude); PR hacia `develop` abierto al escribir este reporte (su número y merge quedan registrados en GitHub). La integración a `main` se hace con `release/1.0.0` y un PR, solo con autorización del equipo. Sin force push; `main` permanece en `98b499d` hasta entonces.
