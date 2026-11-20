USE tiendalab;
SET NAMES utf8mb4;
START TRANSACTION;
INSERT INTO usuarios(id,nombre,correo,password_hash,rol) VALUES (1,'Administrador','admin@tiendalab.test','$2y$10$vJgDC5Ydd9lTXxZiI5I9l.m0wNjswPA7IE7dNw0naoU4ajUfD7.9.','administrador');
INSERT INTO usuarios(id,nombre,correo,password_hash,rol) VALUES (2,'Tienda Volcán','vendedor@tiendalab.test','$2y$10$W7dG1/T97fzfRivXedelLuN2bUhxjI0Vlnnd9db3PhL3OBFRH.gJW','vendedor');
INSERT INTO usuarios(id,nombre,correo,password_hash,rol) VALUES (3,'Ana Martínez','ana@tiendalab.test','$2y$10$boyTFPBf0PxaY9hRuIvrR.LmaTqSb9chQHWcjq9jwVBA4iw.2/2oK','comprador');
INSERT INTO usuarios(id,nombre,correo,password_hash,rol) VALUES (4,'Luis Hernández','luis@tiendalab.test','$2y$10$w4bshoI.Ceu69M5PbRdxGeVSs5iVWlSNMzG0y1WCk6E.J3n5gvUai','comprador');
INSERT INTO usuarios(id,nombre,correo,password_hash,rol) VALUES (5,'Carla Prueba','carla@tiendalab.test','$2y$10$sX5EWN2Du0YXMXdPpjHjp.Yni7w2wutUbfHvwO9Y6PGEIOUvAp/oC','comprador');
INSERT INTO productos(id,vendedor_id,nombre,descripcion,precio,stock,imagen) VALUES (1,2,'Audífonos inalámbricos','Bluetooth 5.3, hasta 30 horas de batería y estuche de carga.',39.99,25,'/assets/img/audifonos.svg');
INSERT INTO productos(id,vendedor_id,nombre,descripcion,precio,stock,imagen) VALUES (2,2,'Teclado mecánico','Switches rojos, retroiluminación RGB y formato compacto 75%.',64.50,10,'/assets/img/teclado.svg');
INSERT INTO productos(id,vendedor_id,nombre,descripcion,precio,stock,imagen) VALUES (3,2,'Mouse ergonómico','Sensor de 4000 DPI, seis botones y conexión USB-C.',24.90,40,'/assets/img/mouse.svg');
INSERT INTO productos(id,vendedor_id,nombre,descripcion,precio,stock,imagen) VALUES (4,2,'Monitor 24 pulgadas','Panel IPS Full HD a 100 Hz con bordes delgados.',129.00,8,'/assets/img/monitor.svg');
INSERT INTO productos(id,vendedor_id,nombre,descripcion,precio,stock,imagen) VALUES (5,2,'Memoria USB 64 GB','USB 3.2, cuerpo metálico y llavero incluido.',9.75,59,'/assets/img/memoria.svg');
INSERT INTO productos(id,vendedor_id,nombre,descripcion,precio,stock,imagen) VALUES (6,2,'Cámara web HD','1080p con micrófono doble y tapa de privacidad.',34.00,15,'/assets/img/camara.svg');
INSERT INTO productos(id,vendedor_id,nombre,descripcion,precio,stock,imagen) VALUES (7,2,'Base para laptop','Aluminio, altura ajustable y ventilación pasiva.',21.50,20,'/assets/img/base.svg');
INSERT INTO productos(id,vendedor_id,nombre,descripcion,precio,stock,imagen) VALUES (8,2,'Cargador 65 W','USB-C con carga rápida para laptop y teléfono.',29.99,30,'/assets/img/cargador.svg');
INSERT INTO productos(id,vendedor_id,nombre,descripcion,precio,stock,imagen) VALUES (9,2,'Parlante Bluetooth','Sonido portátil, conexión inalámbrica y batería recargable.',45.00,10,'/assets/img/parlante.svg');
INSERT INTO facturas(id,comprador_id,fecha,subtotal) VALUES
(1,3,'2026-11-05 10:15:00',64.89),
(2,4,'2026-11-06 16:40:00',129.00),
(3,3,'2026-11-10 11:09:00',138.75),
(4,3,'2026-11-10 11:12:00',73.99);
INSERT INTO detalle_facturas(factura_id,producto_id,nombre_producto,cantidad,precio_unitario) VALUES (1,1,'Audífonos inalámbricos',1,39.99);
INSERT INTO detalle_facturas(factura_id,producto_id,nombre_producto,cantidad,precio_unitario) VALUES (1,3,'Mouse ergonómico',1,24.90);
INSERT INTO detalle_facturas(factura_id,producto_id,nombre_producto,cantidad,precio_unitario) VALUES (2,4,'Monitor 24 pulgadas',1,129.00);
INSERT INTO detalle_facturas(factura_id,producto_id,nombre_producto,cantidad,precio_unitario) VALUES (3,4,'Monitor 24 pulgadas',1,129.00);
INSERT INTO detalle_facturas(factura_id,producto_id,nombre_producto,cantidad,precio_unitario) VALUES (3,5,'Memoria USB 64 GB',1,9.75);
INSERT INTO detalle_facturas(factura_id,producto_id,nombre_producto,cantidad,precio_unitario) VALUES (4,1,'Audífonos inalámbricos',1,39.99);
INSERT INTO detalle_facturas(factura_id,producto_id,nombre_producto,cantidad,precio_unitario) VALUES (4,6,'Cámara web HD',1,34.00);
COMMIT;
