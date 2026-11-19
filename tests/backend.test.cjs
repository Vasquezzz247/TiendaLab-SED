'use strict';
// HTTP real contra dos procesos PHP y MariaDB. No usa dependencias externas.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {execFileSync} = require('node:child_process');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const fixture = JSON.parse(fs.readFileSync(path.join(root, 'tmp/fase03-fixtures.json'), 'utf8'));
const php = process.env.TIENDALAB_TEST_PHP;
const options = JSON.parse(process.env.TIENDALAB_TEST_PHP_OPTIONS || '[]');
const base = `http://127.0.0.1:${process.argv[2] || 8010}`;
const second = `http://127.0.0.1:${process.argv[3] || 8011}`;
const password = 'Prueba-Fase03-2026!'; // Exclusivamente ficticia, no clave SQL.
let count = 0;
function check(condition, label) { assert.ok(condition, label); console.log(`PASS: ${++count} ${label}`); }
function state() { return JSON.parse(execFileSync(php, [...options, 'tests/backend-fixtures.php', 'inspect'], {cwd:root,encoding:'utf8'})); }
class Browser {
    constructor(origin=base){this.origin=origin;this.cookie='';this.token='';}
    async request(route, values, file){
        const headers = this.cookie ? {cookie:this.cookie} : {};
        const config = {method:values ? 'POST' : 'GET', redirect:'manual', headers};
        if(values){
            if(file){const form=new FormData();for(const [k,v] of Object.entries(values))form.set(k,String(v));form.set('imagen',new Blob([file.bytes],{type:file.type}),file.name);config.body=form;}
            else {config.body=new URLSearchParams(values);}
        }
        const result=await fetch(this.origin+route,config);
        for(const cookie of result.headers.getSetCookie()){
            if(cookie.startsWith('TiendaLabSID='))this.cookie=cookie.split(';')[0];
        }
        const bytes=Buffer.from(await result.arrayBuffer());
        const body=bytes.toString('utf8');
        const token=body.match(/name="csrf" value="([a-f0-9]{64})"/);
        if(token)this.token=token[1];
        return {status:result.status,headers:result.headers,body,bytes};
    }
    async form(route, values, file){await this.request(route);return this.request(route,{csrf:this.token,...values},file);}
    async login(key){return this.form('/login.php',{correo:fixture.users[key].email,password});}
}
(async()=>{
    const guest=new Browser();
    let r=await guest.request('/');check(r.status===200 && r.body.includes(fixture.prefix+'anexo1'),'catalogo consulta productos reales');
    check(r.body.includes('src="/assets/img/audifonos.svg"'),'catalogo conserva las rutas de imagen del seed');
    check(r.headers.get('x-content-type-options')==='nosniff' && r.headers.get('content-security-policy').includes("form-action 'self'"),'cabeceras y formularios restringidos a mismo origen');
    r=await guest.request('/?q='+encodeURIComponent(fixture.prefix+'anexo1'));check(r.body.includes(fixture.prefix+'anexo1')&&!r.body.includes(fixture.prefix+'anexo2'),'busqueda real literal');
    r=await guest.request('/?q='+encodeURIComponent("' OR 1=1 --"));check(r.status===200 && r.body.includes('No encontramos productos'),'consulta preparada: texto SQL no altera busqueda');
    r=await guest.request('/?q='+encodeURIComponent('<script>alert(1)</script>'));check(!r.body.includes('<script>alert(1)</script>')&&r.body.includes('&lt;script&gt;'),'entrada escapada al renderizar');
    for(const route of ['/carrito.php','/factura.php?id=1','/historial.php','/vendedor.php','/admin-productos.php','/admin-usuarios.php']){
        r=await guest.request(route);check(r.status===303&&r.headers.get('location')==='/login.php',`sin sesion no accede ${route.split('?')[0]}`);
    }
    for(const route of ['/.env','/app/database.php','/storage/sessions/','/tools/php/php.exe','/database/init/02-seed.sql','/no-existe.php']){
        r=await guest.request(route);check(r.status===404,`ruta privada o inexistente bloqueada ${route}`);
    }
    r=await guest.request('/prototipo/');check(r.status===404,'maquetas deshabilitadas por defecto en servidor real');
    r=await guest.request('/?q[]=x');check(r.status===422&&!/Stack trace|Fatal error|mysqli_sql_exception|DB_PASSWORD/.test(r.body),'entrada de tipo incorrecto produce error controlado');
    const cookieCheck=new Browser();r=await cookieCheck.request('/login.php');
    const sessionCookies=r.headers.getSetCookie().filter(c=>c.startsWith('TiendaLabSID='));
    check(sessionCookies.length===1&&/HttpOnly/i.test(sessionCookies[0])&&/SameSite=Lax/i.test(sessionCookies[0]),'atributos de una cookie nueva de sesion');
    const fixation=new Browser();fixation.cookie='TiendaLabSID='+ 'x'.repeat(32);
    await fixation.request('/login.php');check(fixation.cookie!=='TiendaLabSID'+'='+ 'x'.repeat(32),'modo estricto rechaza ID de sesion no inicializado');
    const preLogin=guest.cookie;
    r=await guest.request('/login.php',{correo:fixture.users.buyer.email,password,csrf:'invalido'});check(r.status===403,'login protegido contra CSRF');
    r=await guest.form('/login.php',{correo:fixture.users.buyer.email,password:'Incorrecta-2026!'});check(r.status===401,'login incorrecto rechazado');
    r=await guest.login('buyer');check(r.status===303&&r.headers.get('location')==='/'&&guest.cookie!==preLogin,'login comprador y regeneracion de ID');
    const buyer=guest;
    const oldSession=new Browser();oldSession.cookie=preLogin;r=await oldSession.request('/historial.php');check(r.status===303,'sesion previa a login no autentica');
    for(const route of ['/vendedor.php','/admin-productos.php','/admin-usuarios.php']){r=await buyer.request(route);check(r.status===403,'comprador sin permiso '+route);}
    const inactive=new Browser();r=await inactive.login('inactive');check(r.status===401,'cuenta inactiva no inicia sesion');
    const registration=new Browser();
    const email=fixture.prefix+'registered@tiendalab.test';
    r=await registration.form('/register.php',{nombre:fixture.prefix+'registro',correo:email,password,confirm:password,rol:'administrador',activo:'0'});check(r.status===303,'registro real');
    let data=state(),registered=data.users.find(u=>u.correo===email);
    check(registered?.rol==='comprador'&&Number(registered.activo)===1&&registered.hash_verificable,'registro fuerza comprador activo y hash verificable');
    r=await registration.form('/register.php',{nombre:'Duplicado',correo:email,password,confirm:password});check(r.status===409,'correo duplicado rechazado');
    r=await registration.form('/register.php',{nombre:'Confirmacion',correo:fixture.prefix+'bad@tiendalab.test',password,confirm:'otra'});check(r.status===422,'confirmacion de contraseña validada');
    r=await registration.form('/login.php',{correo:email,password});check(r.status===303,'cuenta registrada puede iniciar sesion');
    const savedCookie=registration.cookie;
    r=await registration.form('/logout.php',{}); // GET logout es 405, pero mantiene el CSRF de login hasta navegar.
    if(r.status===403){await registration.request('/');r=await registration.request('/logout.php',{csrf:registration.token});}
    check(r.status===303,'logout por POST');
    const replay=new Browser();replay.cookie=savedCookie;r=await replay.request('/historial.php');check(r.status===303,'cookie de sesion destruida no permite reingreso');
    const seller=new Browser(),seller2=new Browser(),admin=new Browser(),other=new Browser(second);
    for(const [client,key,home] of [[seller,'seller','/vendedor.php'],[seller2,'seller2','/vendedor.php'],[admin,'admin','/admin-productos.php'],[other,'other','/']]){
        r=await client.login(key);check(r.status===303&&r.headers.get('location')===home,'login y destino rol '+key);
    }
    r=await seller.request('/admin-usuarios.php');check(r.status===403,'vendedor no administra usuarios');
    r=await admin.request('/carrito.php');check(r.status===403,'administrador no simula comprador');
    r=await admin.request('/admin-productos.php');check(r.status===200&&r.body.includes('Ventas'),'metricas administrativas reales');
    r=await admin.request('/admin-usuarios.php');check(r.status===200&&r.body.includes(email),'listado real de usuarios');
    const p1=fixture.products.anexo1,p2=fixture.products.anexo2;
    r=await buyer.form('/',{action:'add',id:p1,cantidad:'1.5'});check(r.status===422,'cantidades fraccionarias rechazadas');
    r=await buyer.form('/',{action:'add',id:p1,cantidad:'-1'});check(r.status===422,'cantidades negativas rechazadas');
    r=await buyer.form('/',{action:'add',id:p1,cantidad:'999'});check(r.status===409,'stock insuficiente al agregar');
    r=await buyer.form('/',{action:'add',id:p1,cantidad:'2',precio:'0.01',stock:'99999'});check(r.status===303,'agregar ignora precio y stock enviados');
    r=await buyer.form('/carrito.php',{action:'update',id:p1,cantidad:'1'});check(r.status===303,'modificacion del carrito');
    r=await buyer.form('/',{action:'add',id:p2,cantidad:'1'});check(r.status===303,'segundo producto');
    r=await buyer.form('/carrito.php',{action:'remove',id:p2});check(r.status===303,'eliminacion del carrito');
    await buyer.form('/',{action:'add',id:p2,cantidad:'1'});
    r=await buyer.request('/carrito.php');check(r.body.includes('$73.99')&&r.body.includes('$9.62')&&r.body.includes('$83.61'),'subtotal IVA y total del anexo calculados por PHP');
    const checkoutToken=buyer.token;
    r=await buyer.request('/carrito.php',{action:'checkout',csrf:checkoutToken,total:'0.01',comprador_id:fixture.users.other.id});
    check(r.status===303&&/^\/factura.php\?id=\d+$/.test(r.headers.get('location')),'compra real genera factura');
    const invoicePath=r.headers.get('location'),invoiceId=Number(invoicePath.split('=')[1]);
    data=state();const invoice=data.invoices.find(i=>Number(i.id)===invoiceId);
    check(invoice?.total==='83.61'&&Number(invoice.comprador_id)===fixture.users.buyer.id,'precio y comprador salen del servidor');
    check(data.products.find(p=>Number(p.id)===p1).stock===9&&data.products.find(p=>Number(p.id)===p2).stock===9,'stock descontado una vez');
    check(data.details.filter(d=>Number(d.factura_id)===invoiceId).length===2,'detalle completo guardado');
    r=await buyer.request('/carrito.php',{action:'checkout',csrf:checkoutToken});check(r.status===403,'repeticion del POST de compra no duplica factura');
    r=await buyer.request(invoicePath);check(r.status===200&&r.body.includes('$83.61'),'consulta factura propia');
    r=await other.request(invoicePath);check(r.status===404,'factura ajena rechazada: IDOR aun no implementado');
    r=await buyer.request('/historial.php');check(r.body.includes(invoicePath),'historial incluye compra propia');
    r=await other.request('/historial.php');check(!r.body.includes(invoicePath),'historial no filtra facturas de otro comprador');
    for(const client of [buyer,other]){r=await client.form('/',{action:'add',id:fixture.products.concurrent,cantidad:'1'});check(r.status===303,'carrito concurrente preparado');await client.request('/carrito.php');}
    const concurrent=await Promise.all([buyer.request('/carrito.php',{action:'checkout',csrf:buyer.token}),other.request('/carrito.php',{action:'checkout',csrf:other.token})]);
    check(concurrent.map(r=>r.status).sort().join(',')==='303,409','dos procesos PHP: una compra gana y otra recibe stock insuficiente');
    data=state();check(data.products.find(p=>Number(p.id)===fixture.products.concurrent).stock===0&&data.details.filter(d=>Number(d.producto_id)===fixture.products.concurrent).length===1,'concurrencia sin stock negativo ni doble factura');
    const png=fs.readFileSync(path.join(root,'tmp/fase03-valid.png'));
    const image={bytes:png,type:'image/png',name:'prueba.png'};
    const fields={action:'save',id:'0',nombre:fixture.prefix+'<b>Producto</b>',descripcion:'Descripción con acento',precio:'12.34',stock:'5',activo:'1',vendedor_id:fixture.users.seller2.id};
    r=await seller.form('/vendedor.php',fields,{bytes:Buffer.from('<?php echo "LAB"; ?>'),type:'image/png',name:'falsa.png'});check(r.status===422,'archivo ejecutable disfrazado rechazado');
    r=await seller.form('/vendedor.php',fields,{...image,name:'imagen.php'});check(r.status===422,'extension no permitida rechazada');
    r=await seller.form('/vendedor.php',fields,{bytes:Buffer.alloc(2097153),type:'image/png',name:'grande.png'});check(r.status===422,'archivo mayor de 2 MB rechazado');
    r=await seller.form('/vendedor.php',{...fields,precio:'0'},image);check(r.status===422,'precio cero rechazado en servidor');
    r=await seller.form('/vendedor.php',fields,{...image,bytes:Buffer.concat([png,Buffer.from('MARCADOR_NO_IMAGEN')])});check(r.status===303,'vendedor crea producto con imagen autentica');
    const productId=Number(r.headers.get('location').split('=')[1]);
    data=state();let product=data.products.find(p=>Number(p.id)===productId);
    check(Number(product.vendedor_id)===fixture.users.seller.id,'vendedor no puede falsificar dueño al crear');
    r=await seller.request('/vendedor.php');check(r.body.includes('&lt;b&gt;Producto&lt;/b&gt;')&&!r.body.includes('<b>Producto</b>'),'salida persistida escapada');
    r=await seller.request('/imagen.php?id='+product.imagen);check(r.status===200&&r.headers.get('content-type')==='image/png'&&!r.bytes.includes(Buffer.from('MARCADOR_NO_IMAGEN')),'imagen recodificada y servida como PNG sin contenido añadido');
    r=await seller.request('/imagen.php?id=../.env');check(r.status===404,'traversal en imagen rechazado');
    r=await seller2.request('/vendedor.php?editar='+productId);check(r.status===404,'vendedor no abre editor ajeno');
    r=await seller2.form('/vendedor.php',{...fields,id:productId,nombre:fixture.prefix+'intruso'});check(r.status===404,'vendedor no modifica producto ajeno por POST');
    r=await seller.request('/vendedor.php',{...fields,id:productId,csrf:'mal'});check(r.status===403,'CSRF de producto rechazado');
    r=await seller.form('/vendedor.php',{...fields,id:productId,stock:'7'});check(r.status===303,'vendedor edita producto propio conservando imagen');
    r=await admin.form('/admin-productos.php',{...fields,nombre:fixture.prefix+'admin',vendedor_id:fixture.users.seller2.id},image);check(r.status===303,'administrador crea producto');
    const adminProduct=Number(r.headers.get('location').split('=')[1]);
    r=await admin.form('/admin-productos.php',{...fields,id:adminProduct,nombre:fixture.prefix+'admin-editado',vendedor_id:fixture.users.seller2.id,activo:'0'});check(r.status===303,'administrador edita y retira producto');
    r=await buyer.request('/?q='+encodeURIComponent(fixture.prefix+'admin-editado'));check(r.body.includes('No encontramos productos'),'producto retirado no aparece en catalogo');
    r=await admin.form('/admin-productos.php',{action:'delete',id:adminProduct});check(r.status===303,'administrador elimina producto');
    r=await admin.form('/admin-productos.php',{action:'delete',id:p1});check(r.status===303,'eliminar producto facturado conserva historia');
    data=state();check(data.details.some(d=>Number(d.factura_id)===invoiceId&&d.producto_id===null&&d.precio_unitario==='39.99'),'FK SET NULL conserva nombre y precio del detalle');
    r=await buyer.request(invoicePath);check(r.status===200&&r.body.includes('$83.61'),'factura sigue consultable tras eliminar producto');
    const newEmail=fixture.prefix+'admin-created@tiendalab.test';
    const userFields={action:'save',id:'0',nombre:fixture.prefix+'nuevo',correo:newEmail,password,rol:'comprador',activo:'1'};
    r=await admin.form('/admin-usuarios.php',userFields);check(r.status===303,'administrador crea usuario');
    const newUser=Number(r.headers.get('location').split('=')[1]);
    r=await admin.form('/admin-usuarios.php',{...userFields,id:newUser,password:'',rol:'vendedor'});check(r.status===303&&state().users.find(u=>Number(u.id)===newUser).rol==='vendedor','administrador cambia rol y conserva hash');
    r=await admin.form('/admin-usuarios.php',{...userFields,id:newUser,password:'',rol:'invalido'});check(r.status===422,'rol fuera de lista rechazado');
    r=await admin.form('/admin-usuarios.php',{action:'delete',id:newUser});check(r.status===303&&!state().users.some(u=>Number(u.id)===newUser),'usuario sin referencias eliminado fisicamente');
    const otherFields={...userFields,id:fixture.users.other.id,nombre:fixture.prefix+'other',correo:fixture.users.other.email,password:'',activo:'0'};
    r=await admin.form('/admin-usuarios.php',otherFields);check(r.status===303,'desactivar usuario');
    r=await other.request('/historial.php');check(r.status===303&&r.headers.get('location')==='/login.php','desactivacion revoca sesion existente');
    r=await admin.form('/admin-usuarios.php',{...otherFields,activo:'1'});check(r.status===303,'reactivar usuario');
    await other.login('other');
    r=await admin.form('/admin-usuarios.php',{...otherFields,activo:'1',rol:'vendedor'});check(r.status===303,'cambio de rol real');
    r=await other.request('/historial.php');check(r.status===403,'rol se consulta en BD por solicitud');
    r=await other.request('/vendedor.php');check(r.status===200,'nuevo rol permite su panel');
    r=await admin.form('/admin-usuarios.php',{action:'delete',id:fixture.users.buyer.id});check(r.status===303&&Number(state().users.find(u=>Number(u.id)===fixture.users.buyer.id).activo)===0,'usuario con facturas se desactiva sin romper FK');
    r=await buyer.request('/historial.php');check(r.status===303,'baja logica revoca acceso del comprador');
    // Rehabilitar fixture para prueba CLI de rollback; solo datos propios.
    await admin.form('/admin-usuarios.php',{...userFields,id:fixture.users.buyer.id,nombre:fixture.prefix+'buyer',correo:fixture.users.buyer.email,password:'',activo:'1'});
    r=await admin.form('/admin-usuarios.php',{action:'delete',id:fixture.users.admin.id});check(r.status===422,'administrador no elimina su propio acceso');
    r=await admin.request('/admin-usuarios.php',{...userFields,csrf:'incorrecto'});check(r.status===403,'CSRF de usuarios rechazado');
    r=await admin.form('/admin-usuarios.php',{...userFields,id:fixture.users.seller2.id,nombre:fixture.prefix+'seller2',correo:fixture.users.seller2.email,password:'Nueva-Clave-2026!',rol:'vendedor'});check(r.status===303,'cambio de contraseña administrativo');
    r=await seller2.request('/vendedor.php');check(r.status===303,'cambio de contraseña invalida sesion previa');
    // Observacion B: un vendedor con productos activos no puede cambiar de rol (evita productos huerfanos).
    r=await admin.form('/admin-productos.php',{...fields,nombre:fixture.prefix+'producto-b',vendedor_id:fixture.users.other.id},image);check(r.status===303,'administrador publica un producto a nombre de un vendedor');
    const productB=Number(r.headers.get('location').split('=')[1]);
    const demote={...otherFields,rol:'comprador',activo:'1'};
    r=await admin.form('/admin-usuarios.php',demote);check(r.status===422,'vendedor con productos activos no cambia de rol');
    data=state();check(data.users.find(u=>Number(u.id)===fixture.users.other.id).rol==='vendedor'&&Number(data.products.find(p=>Number(p.id)===productB).vendedor_id)===fixture.users.other.id,'rol y propiedad del producto conservados tras el rechazo');
    r=await admin.form('/admin-productos.php',{...fields,id:productB,nombre:fixture.prefix+'producto-b',vendedor_id:fixture.users.other.id,activo:'0'});check(r.status===303,'administrador retira el producto del vendedor');
    r=await admin.form('/admin-usuarios.php',demote);check(r.status===303&&state().users.find(u=>Number(u.id)===fixture.users.other.id).rol==='comprador','sin productos activos el rol si puede cambiar');
    const rate=new Browser();let statuses=[];
    for(let n=0;n<6;n++){r=await rate.form('/login.php',{correo:fixture.prefix+'throttle@tiendalab.test',password:'Incorrecta-2026!'});statuses.push(r.status);}
    check(statuses.slice(0,5).every(s=>s===401)&&statuses[5]===429,'limite de cinco intentos por correo aun sin cuenta');
    const newCookie=new Browser();r=await newCookie.form('/login.php',{correo:fixture.prefix+'throttle@tiendalab.test',password:'Incorrecta-2026!'});check(r.status===429,'limite persiste al cambiar cookie');
    // Los accesos correctos no consumen el limite; solo cuentan los fallos.
    const ownEmail=fixture.users.seller.email;
    statuses=[];
    for(let n=0;n<8;n++){const ok=new Browser();r=await ok.form('/login.php',{correo:ownEmail,password});statuses.push(r.status);}
    check(statuses.every(s=>s===303),'ocho accesos correctos seguidos no activan el limite');
    statuses=[];
    for(let n=0;n<4;n++){const bad=new Browser();r=await bad.form('/login.php',{correo:ownEmail,password:'Incorrecta-2026!'});statuses.push(r.status);}
    const good=new Browser();r=await good.form('/login.php',{correo:ownEmail,password});statuses.push(r.status);
    for(let n=0;n<4;n++){const bad=new Browser();r=await bad.form('/login.php',{correo:ownEmail,password:'Incorrecta-2026!'});statuses.push(r.status);}
    const last=new Browser();r=await last.form('/login.php',{correo:ownEmail,password});statuses.push(r.status);
    check(statuses.join(',')==='401,401,401,401,303,401,401,401,401,303','un acceso correcto reinicia el contador de fallos del correo');
    for(const route of ['/factura.php?id[]=1','/imagen.php?id[]=x']){r=await admin.request(route);check([403,404,422].includes(r.status)&&!r.body.includes('Stack trace'),'error controlado para parametros anidados');}
    const unavailable=new Browser(`http://127.0.0.1:${process.argv[4] || 8012}`);
    r=await unavailable.request('/');check(r.status===503&&r.body.includes('No se pudo completar')&&!/mysqli|tiendalab_app|DB_PASSWORD|Stack trace|C:\\Users/.test(r.body),'conexion SQL no disponible devuelve 503 sin informacion interna');
    console.log(`TOTAL: ${count} comprobaciones HTTP/BD aprobadas.`);
})().catch(error=>{console.error(error);process.exitCode=1;});
