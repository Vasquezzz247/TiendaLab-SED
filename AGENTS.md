# Instrucciones del proyecto TiendaLab

- Fuente obligatoria: los dos PDF originales de la raíz, `docs/ALCANCE.md` y `docs/MATRIZ_REQUISITOS.md`. La definición del docente prevalece sobre la propuesta.
- Fases 0 y 1 autorizadas en la petición inicial. **No comenzar fase 2 sin autorización nueva del usuario.** No avanzar automáticamente entre fases posteriores.
- Stack definitivo: Ubuntu Server 24.04 VM, Apache/PHP en host, PHP puro/HTML/CSS/JS, mysqli, MariaDB en Docker/Compose, GitHub y GitFlow. Nada de nube, frameworks, ORM, CDN ni backend generado.
- Prototipos aislados en `public/prototipo/`; no confundirlos con autenticación. No fingir compras, altas, eliminaciones ni persistencia. Mantener datos ficticios separados en `demo/`.
- Las dos vulnerabilidades elegidas se implementan solo en fase 4: IDOR de propiedad de factura manteniendo sesión; diagnóstico ficticio TCP/8081 independiente y limitado a red autorizada. No extender omisiones a otras operaciones.
- Por instrucción adicional del usuario, mantener `docs/GUIA_SEGURIDAD_Y_DEFENSA.md`: objetivo de cada control, comandos reales en orden, archivos, funcionamiento, pruebas, límites, mitigaciones y explicación sencilla. Separar estrictamente ejecutado de recomendado para Ubuntu. Nunca guardar secretos ni inventar resultados.
- Cada fase requiere `REPORTES/FASE_XX_NOMBRE.md` con los diez apartados del prompt, pruebas posibles y estado honesto. Al finalizar, detenerse para revisión.
- No publicar ni inventar remoto, PR o mediciones de instalación. El remoto no se ha proporcionado.
- La vista previa local usa `scripts/iniciar-frontend.ps1`; `public/` es la única raíz web. PHP portátil y temporales están ignorados por Git. No exponerlos a la red.
