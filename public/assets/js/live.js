'use strict';
// Mejora visual; todos los permisos, precios y validaciones permanecen en PHP.
document.querySelectorAll('[data-quantity-step]').forEach(button => button.addEventListener('click', () => {
    const input = button.closest('.quantity').querySelector('input');
    input.value = String(Math.max(1, Math.min(Number(input.max), (Number(input.value) || 1) + Number(button.dataset.quantityStep))));
}));
document.querySelectorAll('[data-confirm]').forEach(form => form.addEventListener('submit', event => {
    if (!window.confirm(form.dataset.confirm)) event.preventDefault();
}));
document.querySelector('#print-invoice')?.addEventListener('click', () => window.print());
let preview;
document.querySelector('#product-image')?.addEventListener('change', event => {
    const file = event.target.files[0];
    const image = document.querySelector('#image-preview');
    if (preview) URL.revokeObjectURL(preview);
    image.hidden = true;
    event.target.setCustomValidity('');
    if (!file) return;
    if (!['image/jpeg','image/png','image/webp'].includes(file.type) || file.size > 2097152) {
        event.target.setCustomValidity('Elige JPG, PNG o WEBP de hasta 2 MB.');
        event.target.reportValidity(); return;
    }
    preview = URL.createObjectURL(file);
    image.src = preview; image.hidden = false;
});
