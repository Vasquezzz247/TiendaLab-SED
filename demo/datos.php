<?php
declare(strict_types=1);

// Ejemplos del anexo. No sustituye al futuro seed SQL ni contiene contraseñas.
return [
    'products' => [
        ['id'=>1, 'name'=>'Audífonos inalámbricos', 'description'=>'Bluetooth 5.3, hasta 30 horas de batería y estuche de carga.', 'cents'=>3999, 'stock'=>25, 'image'=>'audifonos.svg'],
        ['id'=>2, 'name'=>'Teclado mecánico', 'description'=>'Switches rojos, retroiluminación RGB y formato compacto 75%.', 'cents'=>6450, 'stock'=>10, 'image'=>'teclado.svg'],
        ['id'=>3, 'name'=>'Mouse ergonómico', 'description'=>'Sensor de 4000 DPI, seis botones y conexión USB-C.', 'cents'=>2490, 'stock'=>40, 'image'=>'mouse.svg'],
        ['id'=>4, 'name'=>'Monitor 24 pulgadas', 'description'=>'Panel IPS Full HD a 100 Hz con bordes delgados.', 'cents'=>12900, 'stock'=>8, 'image'=>'monitor.svg'],
        ['id'=>5, 'name'=>'Memoria USB 64 GB', 'description'=>'USB 3.2, cuerpo metálico y llavero incluido.', 'cents'=>975, 'stock'=>59, 'image'=>'memoria.svg'],
        ['id'=>6, 'name'=>'Cámara web HD', 'description'=>'1080p con micrófono doble y tapa de privacidad.', 'cents'=>3400, 'stock'=>15, 'image'=>'camara.svg'],
        ['id'=>7, 'name'=>'Base para laptop', 'description'=>'Aluminio, altura ajustable y ventilación pasiva.', 'cents'=>2150, 'stock'=>20, 'image'=>'base.svg'],
        ['id'=>8, 'name'=>'Cargador 65 W', 'description'=>'USB-C con carga rápida para laptop y teléfono.', 'cents'=>2999, 'stock'=>30, 'image'=>'cargador.svg'],
        ['id'=>9, 'name'=>'Parlante Bluetooth', 'description'=>'Sonido portátil, conexión inalámbrica y batería recargable.', 'cents'=>4500, 'stock'=>10, 'image'=>'parlante.svg'],
    ],
    'users' => [
        ['id'=>1, 'name'=>'Administrador', 'email'=>'admin@tiendalab.test', 'role'=>'Administrador'],
        ['id'=>2, 'name'=>'Tienda Volcán', 'email'=>'vendedor@tiendalab.test', 'role'=>'Vendedor'],
        ['id'=>3, 'name'=>'Ana Martínez', 'email'=>'ana@tiendalab.test', 'role'=>'Comprador'],
        ['id'=>4, 'name'=>'Luis Hernández', 'email'=>'luis@tiendalab.test', 'role'=>'Comprador'],
        ['id'=>5, 'name'=>'Carla Prueba', 'email'=>'carla@tiendalab.test', 'role'=>'Comprador'],
    ],
    // Solo ejemplos de Ana. No se incluye una ruta a facturas ajenas ni IDOR.
    'invoices' => [
        4 => ['date'=>'10/11/2026 11:12', 'items'=>[1=>1, 6=>1]],
        3 => ['date'=>'10/11/2026 11:09', 'items'=>[4=>1, 5=>1]],
        1 => ['date'=>'05/11/2026 10:15', 'items'=>[1=>1, 3=>1]],
    ],
];
