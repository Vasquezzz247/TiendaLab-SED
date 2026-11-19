# Instrucciones del proyecto TiendaLab

- Fuente obligatoria: los dos PDF originales de la raíz, `docs/ALCANCE.md` y `docs/MATRIZ_REQUISITOS.md`. La definición del docente prevalece sobre la propuesta.
- Autorización vigente: desarrollar e integrar fase 3 (backend PHP/mysqli y operaciones reales). **Detenerse antes de fases 4 y 5.** Facturas con autenticación y propiedad; ningún servicio 8081.
- Stack definitivo: Ubuntu Server 24.04 VM, Apache/PHP en host, PHP puro/HTML/CSS/JS, mysqli, MariaDB en Docker/Compose, GitHub y GitFlow. Nada de nube, frameworks, ORM, CDN ni backend generado.
- Prototipos aislados en `public/prototipo/`; no confundirlos con autenticación. No fingir compras, altas, eliminaciones ni persistencia. Mantener datos ficticios separados en `demo/`.
- Las dos vulnerabilidades elegidas se implementan solo en fase 4: IDOR de propiedad de factura manteniendo sesión; diagnóstico ficticio TCP/8081 independiente y limitado a red autorizada. No extender omisiones a otras operaciones.
- Por instrucción adicional del usuario, mantener `docs/GUIA_SEGURIDAD_Y_DEFENSA.md`: objetivo de cada control, comandos reales en orden, archivos, funcionamiento, pruebas, límites, mitigaciones y explicación sencilla. Separar estrictamente ejecutado de recomendado para Ubuntu. Nunca guardar secretos ni inventar resultados.
- Cada fase requiere `REPORTES/FASE_XX_NOMBRE.md` con los diez apartados del prompt, pruebas posibles y estado honesto. Al finalizar, detenerse para revisión.
- Remoto público por autorización explícita: https://github.com/Vasquezzz247/TiendaLab-SED. Fases 0–2 integradas por PR #1–#6. Fase 3 en feature/fase-03-backend desde develop, con pruebas, commits por módulo y PR real hacia develop. Main intacta.
- La vista previa local usa `scripts/iniciar-frontend.ps1`; `public/` es la única raíz web. PHP portátil y temporales están ignorados por Git. No exponerlos a la red.
