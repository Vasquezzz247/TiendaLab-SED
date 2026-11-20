# Fase 00: lectura, análisis y preparación

Fecha: 18/11/2026.

## 1. Objetivo

Leer íntegramente las fuentes y transformar requisitos en alcance, arquitectura y matriz trazable antes de programar.

## 2. Requisitos cubiertos

D1-6 y P1-11 leídos completos: roles, restricciones, despliegue, GitFlow, documentación, calendario y playbook. R01-R34 identificados en la matriz. Esta fase documenta; no implementa esos requisitos funcionales.

## 3. Archivos creados y modificados

`docs/ALCANCE.md`, `docs/MATRIZ_REQUISITOS.md`, `docs/GITFLOW.md`, `.gitignore`, `.gitattributes` y este reporte. Los PDF originales permanecen sin cambios. Extracciones y 17 PNG en `tmp/pdfs/`, ignorados por Git.

## 4. Funcionalidades implementadas

Ninguna funcionalidad de tienda en fase 0. Estructura prevista, precedencia documental y separación del prototipo definidas. Preparación de ramas locales descrita en GitFlow; sin remoto ni PR.

## 5. Cómo comprobar

Leer alcance y matriz comparándolos con los PDF. Revisar la tabla de las 12 capturas del anexo. Usar los comandos de `docs/GITFLOW.md` para inspeccionar las ramas y commits preparados.

## 6. Pruebas y evidencias

- `rg --files`: inicialmente solo los dos PDF, sin código ni repositorio.
- `pypdf.PdfReader`: definición 6 páginas, propuesta 11 páginas; extracción completa en `tmp/pdfs/` con Python del runtime local.
- `pdftoppm -scale-to 1500 -png Propuesta_TiendaLab.pdf tmp/pdfs/propuesta` y equivalente de definición a 1300: 17 páginas renderizadas e inspeccionadas visualmente.
- Se examinaron todas las tablas de requisitos/prohibiciones, el diagrama de P3 y las 12 capturas de P6-11.
- `git config --get user.name` y `user.email`: identidad local disponible, no modificada.
- `Get-Command php`: no había PHP en PATH. Se inició preparación de un intérprete portátil local para la siguiente fase; su disponibilidad se documentará en el reporte 01.

## 7. Problemas y soluciones

El Python predeterminado no incluía pypdf; se usó el Python del runtime incluido. Poppler emitió avisos de bounding box en glifos Type 3; las páginas renderizadas fueron legibles y se inspeccionaron. La propuesta numera su cuerpo como 5 páginas, pero contiene 11 páginas físicas: se usó numeración física para evitar referencias ambiguas.

## 8. Pendientes o bloqueos

GitHub remoto no proporcionado; red de laboratorio y política de VM preconfigurada pendientes del docente. No bloquean fases 0/1. Instalación real, tiempos y pruebas de seguridad corresponden a fases posteriores.

## 9. Posibles incumplimientos

Ninguna incompatibilidad del stack. La autenticación de facturas prevalece sobre la frase ambigua de P2. Se identificó que no deben reproducirse las capturas de vulnerabilidades antes de fase 4. Aprobación del docente declarada por usuario, sin prueba administrativa independiente.

## 10. Estado final

**COMPLETADA.** La fase 1 está expresamente autorizada en el mismo prompt. Se continúa únicamente con frontend y se detendrá antes de fase 2.
