USE tiendalab;
CREATE TABLE usuarios (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(100) NOT NULL,
 correo VARCHAR(190) NOT NULL UNIQUE,
 password_hash VARCHAR(255) NOT NULL,
 rol ENUM('comprador','vendedor','administrador') NOT NULL DEFAULT 'comprador',
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT ck_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE productos (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 vendedor_id INT UNSIGNED NOT NULL,
 nombre VARCHAR(120) NOT NULL,
 descripcion TEXT NOT NULL,
 precio DECIMAL(10,2) NOT NULL CHECK (precio > 0),
 stock INT NOT NULL CHECK (stock >= 0),
 imagen VARCHAR(255) NOT NULL,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_producto_vendedor FOREIGN KEY (vendedor_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
 CONSTRAINT ck_producto_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE facturas (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 comprador_id INT UNSIGNED NOT NULL,
 fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
 iva DECIMAL(12,2) GENERATED ALWAYS AS (ROUND(subtotal * 0.13, 2)) STORED,
 total DECIMAL(12,2) GENERATED ALWAYS AS (subtotal + ROUND(subtotal * 0.13, 2)) STORED,
 CONSTRAINT fk_factura_comprador FOREIGN KEY (comprador_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
 INDEX ix_comprador_fecha (comprador_id, fecha)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE detalle_facturas (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 factura_id INT UNSIGNED NOT NULL,
 producto_id INT UNSIGNED NULL,
 nombre_producto VARCHAR(120) NOT NULL,
 cantidad INT NOT NULL CHECK (cantidad > 0),
 precio_unitario DECIMAL(10,2) NOT NULL CHECK (precio_unitario > 0),
 importe DECIMAL(12,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
 CONSTRAINT fk_detalle_factura FOREIGN KEY (factura_id) REFERENCES facturas(id) ON DELETE RESTRICT,
 CONSTRAINT fk_detalle_producto FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
