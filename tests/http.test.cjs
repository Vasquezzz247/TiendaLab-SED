'use strict';
const assert = require('node:assert/strict');
const base = `http://127.0.0.1:${process.argv[2] || 8000}`;
const disabled = `http://127.0.0.1:${process.argv[3] || 8002}`;
const pages = ['/', '/login.php', '/register.php', ...['inicio','comprador','carrito','factura','historial','vendedor','admin-productos','admin-usuarios'].map(view=>`/prototipo/?vista=${view}`)];
let checks = 0;
async function check(path, status, origin=base, options={}) {
    const response = await fetch(origin+path, options);
    assert.equal(response.status, status, `${path}: HTTP esperado ${status}; iniciar PHP con scripts/router.php. Un catalogo de respaldo HTTP 200 NO demuestra acceso al recurso solicitado.`);
    checks++;
    return response;
}
(async () => {
    const assets = new Set();
    const links = new Set();
    for (const path of pages) {
        const response = await check(path,200);
        assert.equal(response.headers.get('x-content-type-options'),'nosniff');
        assert.match(response.headers.get('cache-control'),/(?:^|,\s*)no-store(?:,|$)/);
        const prototype = path.startsWith('/prototipo/');
        assert.match(response.headers.get('content-security-policy'),prototype ? /form-action 'none'/ : /form-action 'self'/);
        if(prototype) assert.equal(response.headers.get('set-cookie'),null);
        else assert.match(response.headers.get('set-cookie'),/TiendaLabSID=/);
        const html = await response.text();
        assert.match(html,prototype ? /Datos ficticios/ : /Laboratorio/);
        assert.doesNotMatch(html,/Fatal error|Warning:|Notice:|<script[^>]*>[^<]+<\/script>|\son\w+\s*=/i);
        for (const match of html.matchAll(/(?:src|href)="([^"#]+)"/g)) {
            const target = match[1].replaceAll('&amp;','&');
            assert.ok(target.startsWith('/'),`Recurso externo inesperado: ${target}`);
            (target.startsWith('/assets/') ? assets : links).add(target);
        }
    }
    for (const path of [...assets,...links]) await check(path,200);
    for (const path of ['/prototipo/?vista=desconocida','/prototipo/?vista[]=carrito','/prototipo/?vista=../../demo/datos','/prototipo/?vista=factura&ejemplo=2','/prototipo/?vista=factura&ejemplo[]=4','/admin.php','/demo/datos.php','/app/bootstrap.php','/.git/config','/docs/ALCANCE.md']) await check(path,404);
    await check('/factura.php?id=2',303,base,{redirect:'manual'});
    await check('/login.php',403,base,{method:'POST',body:'dato=ficticio'});
    await check('/prototipo/',405,base,{method:'POST',body:'dato=ficticio'});
    await check('/prototipo/',404,disabled);
    const invoice = await (await check('/prototipo/?vista=factura&ejemplo=4',200)).text();
    for (const value of ['$73.99','$9.62','$83.61']) assert.ok(invoice.includes(value));
    checks++;
    console.log(`PASS: ${checks} comprobaciones HTTP; ${pages.length} pantallas, ${assets.size} assets únicos, enlaces, cabeceras, rutas negativas y factura del anexo.`);
})().catch(error => { console.error(error); process.exitCode=1; });
