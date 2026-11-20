/* Cálculo puro en centavos: reutilizable y comprobable sin navegador. */
(function (root) {
    'use strict';
    const normalizeQuantity = (value, max) => {
        const number = Number(value);
        return Number.isInteger(number) && number >= 1 && number <= max ? number : null;
    };
    const totals = (items) => {
        const subtotal = items.reduce((sum, item) => sum + item.cents * item.quantity, 0);
        const tax = Math.round(subtotal * 13 / 100);
        return { subtotal, tax, total: subtotal + tax };
    };
    const api = Object.freeze({ normalizeQuantity, totals });
    if (typeof module !== 'undefined' && module.exports) module.exports = api;
    else root.TiendaCart = api;
})(globalThis);
