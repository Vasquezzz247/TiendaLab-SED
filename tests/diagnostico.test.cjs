'use strict';
// Vulnerabilidad B (diagnostico ficticio en 8081): comprueba que existe, que es solo ficticia y que queda acotada.
// Uso: node tests/diagnostico.test.cjs [puerto]   (el servicio debe estar levantado; ver scripts/verificar-diagnostico.ps1)
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const os = require('node:os');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const port = Number(process.argv[2] || 8081);
let count = 0;
function check(condition, label) { assert.ok(condition, label); console.log(`PASS: ${++count} ${label}`); }
function raw(method, target) {
    return new Promise((resolve, reject) => {
        const req = http.request({host: '127.0.0.1', port, method, path: target, headers: method === 'POST' ? {'content-length': '3', 'content-type': 'application/x-www-form-urlencoded'} : {}}, res => {
            const chunks = []; res.on('data', c => chunks.push(c));
            res.on('end', () => resolve({status: res.statusCode, headers: res.headers, body: Buffer.concat(chunks).toString('utf8')}));
        });
        req.on('error', reject);
        if (method === 'POST') { req.write('a=b'); }
        req.end();
    });
}
function walk(dir, out = []) {
    for (const entry of fs.readdirSync(dir, {withFileTypes: true})) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) { walk(full, out); } else { out.push(full); }
    }
    return out;
}
(async () => {
    let r = await raw('GET', '/');
    check(r.status === 200 && /^text\/html; charset=utf-8$/i.test(r.headers['content-type']), 'el panel responde 200 como text/html UTF-8 en el puerto ' + port);
    const page = r.body;
    check(page.includes('panel de diagnóstico') && page.includes('Solo para el equipo de desarrollo') && page.includes('Diag#Ficticia-2026') && page.includes('tiendalab-vm01'), 'el panel muestra la informacion interna ficticia del anexo (servidor, base de datos, rutas)');
    check(page.includes('todos los datos de esta página son ficticios'), 'el panel declara que los datos son ficticios');

    // Todo es inventado: nada real del equipo ni de la aplicacion.
    const real = [os.hostname(), os.userInfo().username, ...Object.values(os.networkInterfaces()).flat().filter(i => i.family === 'IPv4' && !i.internal).map(i => i.address)].filter(v => v && v.length >= 4);
    const env = fs.existsSync(path.join(root, '.env')) ? fs.readFileSync(path.join(root, '.env'), 'utf8') : '';
    const secrets = env.split(/\r?\n/).filter(l => /^DB_(ROOT_)?PASSWORD=/.test(l)).map(l => l.split('=')[1]).filter(Boolean);
    check(real.every(v => !page.toLowerCase().includes(v.toLowerCase())), 'el panel no contiene el nombre de equipo, usuario ni IP reales de esta maquina (' + real.length + ' valores comparados)');
    check(secrets.length === 2 && secrets.every(s => !page.includes(s)) && !page.includes('tiendalab_app'), 'el panel no contiene las claves SQL reales ni el usuario SQL de la aplicacion');
    check(!/[A-Z]:\\|\/etc\/passwd|BEGIN [A-Z ]*PRIVATE KEY|gh[pousr]_[A-Za-z0-9]{20,}/.test(page), 'el panel no contiene rutas reales de Windows, llaves privadas ni tokens');

    // Acotado: pagina estatica, sin operaciones, sin enlaces, solo lectura.
    check(!/<form|<script|<a\s|href=|<iframe|<input/i.test(page), 'sin formularios, scripts, enlaces ni campos: no ofrece operaciones');
    for (const method of ['POST', 'PUT', 'DELETE']) {
        r = await raw(method, '/'); check(r.status === 403 || r.status === 405, `el metodo ${method} se rechaza (${r.status})`);
    }
    r = await raw('HEAD', '/'); check(r.status === 200 && r.body === '', 'HEAD permitido y sin cuerpo');
    for (const target of ['/index.php', '/cgi-bin/test', '/.htaccess', '/phpinfo.php']) {
        r = await raw('GET', target); check(r.status === 404 || r.status === 403, `no se ejecuta ni expone ${target} (${r.status})`);
    }
    for (const target of ['/..%2f..%2f..%2fetc%2fpasswd', '/%2e%2e/%2e%2e/etc/passwd', '/..%5c..%5cwindows%5cwin.ini']) {
        r = await raw('GET', target); check(r.status !== 200 && !r.body.includes('root:') && !r.body.includes('[fonts]'), `recorrido de directorios rechazado ${target} (${r.status})`);
    }
    r = await raw('GET', '/nada/'); check(r.status === 404 && !/Index of/i.test(r.body), 'sin listado de directorios');

    // Cabeceras: no se introduce ninguna otra debilidad (Content-Type incorrecto, version de Apache, PHP).
    r = await raw('GET', '/');
    check(r.headers['x-content-type-options'] === 'nosniff' && r.headers['cache-control'] === 'no-store', 'cabeceras nosniff y no-store presentes (Content-Type correcto, no es una vulnerabilidad extra)');
    check(!/\d/.test(r.headers.server || '') && !r.headers['x-powered-by'], 'la cabecera Server no revela version y no hay X-Powered-By (' + (r.headers.server || 'sin Server') + ')');

    // La vulnerabilidad: abierta a cualquier origen, sin enlace desde la tienda.
    const conf = fs.readFileSync(path.join(root, 'deploy/apache/tiendalab-diagnostico.conf'), 'utf8').split(/\r?\n/).filter(l => !l.trim().startsWith('#')).join('\n');
    check(/^Listen 8081$/m.test(conf) && /<Limit GET HEAD OPTIONS>\s*Require all granted/.test(conf) && !/Require ip|Require local|Listen 127\./.test(conf),'configuracion: escucha en 8081 en todas las interfaces y sin restriccion por IP (la debilidad aprobada)');
    check(/Options None/.test(conf) && /AllowOverride None/.test(conf) && /LimitExcept GET HEAD OPTIONS/.test(conf), 'configuracion: sin CGI/SSI/listado, sin .htaccess y solo metodos de lectura');
    const hits = ['app', 'public', 'demo', 'scripts/router.php'].flatMap(p => { const full = path.join(root, p); return fs.statSync(full).isDirectory() ? walk(full) : [full]; }).filter(f => /8081|diagnostico/i.test(fs.readFileSync(f, 'utf8')));
    check(hits.length === 0, 'la tienda (app, public, demo) no menciona ni enlaza el puerto 8081 ni el diagnostico');
    console.log(`TOTAL: ${count} comprobaciones del servicio de diagnostico aprobadas.`);
})().catch(error => { console.error(error); process.exitCode = 1; });
