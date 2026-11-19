-- Usuario creado por la imagen oficial; reducir permisos al CRUD de esta base.
REVOKE ALL PRIVILEGES ON tiendalab.* FROM 'tiendalab_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON tiendalab.* TO 'tiendalab_app'@'%';
