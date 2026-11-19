<?php
declare(strict_types=1);

function image_url(string $name): string
{
    if (preg_match('/^[a-f0-9]{32}\.png$/D', $name)) { return '/imagen.php?id=' . $name; }
    // El seed conserva rutas /assets/img/...; los nombres de prueba pueden ser relativos.
    return '/assets/img/' . (preg_match('#^(?:/assets/img/)?([a-z]+\.svg)$#D', $name, $match) ? $match[1] : 'marca.svg');
}
function save_image(?array $file): ?string
{
    if (!$file || ($file['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_NO_FILE) { return null; }
    if (($file['error'] ?? -1) !== UPLOAD_ERR_OK || !is_string($file['tmp_name'] ?? null)
        || !is_uploaded_file($file['tmp_name']) || ($file['size'] ?? 0) > 2 * 1024 * 1024) { throw new AppError('Imagen no válida o mayor de 2 MB.'); }
    $extension = strtolower(pathinfo(is_string($file['name'] ?? null) ? $file['name'] : '', PATHINFO_EXTENSION));
    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($file['tmp_name']);
    $types = ['jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'png' => 'image/png', 'webp' => 'image/webp'];
    if (!isset($types[$extension]) || $types[$extension] !== $mime) { throw new AppError('Solo se permiten imágenes JPG, PNG o WEBP auténticas.'); }
    $size = @getimagesize($file['tmp_name']);
    if (!$size || $size[0] > 4096 || $size[1] > 4096 || $size[0] * $size[1] > 16000000) { throw new AppError('Imagen demasiado grande: máximo 4096 px y 16 millones de píxeles.'); }
    $image = @imagecreatefromstring(file_get_contents($file['tmp_name']));
    if (!$image) { throw new AppError('No se pudo leer la imagen.'); }
    $name = bin2hex(random_bytes(16)) . '.png';
    $target = storage_dir('uploads') . '/' . $name;
    try {
        imagesavealpha($image, true);
        if (!imagepng($image, $target) || !is_file($target)) { throw new RuntimeException('No se pudo guardar imagen'); }
        if (filesize($target) > 2 * 1024 * 1024) { @unlink($target); throw new AppError('La imagen procesada supera 2 MB.'); }
        chmod($target, 0600);
    } finally { imagedestroy($image); }
    return $name;
}
function remove_image(?string $name): void
{
    if ($name && preg_match('/^[a-f0-9]{32}\.png$/D', $name)) {
        $path = storage_dir('uploads') . '/' . $name;
        if (is_file($path)) { @unlink($path); }
    }
}
