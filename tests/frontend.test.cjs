'use strict';
const assert = require('node:assert/strict');
const { test } = require('node:test');
const { normalizeQuantity, totals } = require('../public/assets/js/carrito.js');
test('anexo: 39.99 + 34.00, IVA 13%, total 83.61', () => {
    assert.deepEqual(totals([{cents:3999,quantity:1},{cents:3400,quantity:1}]), {subtotal:7399,tax:962,total:8361});
});
test('carrito vacío y redondeo al centavo', () => {
    assert.deepEqual(totals([]), {subtotal:0,tax:0,total:0});
    assert.deepEqual(totals([{cents:975,quantity:3}]), {subtotal:2925,tax:380,total:3305});
});
test('cantidades enteras entre uno y existencias, sin negativos ni fracciones', () => {
    for (const bad of [-1,0,1.5,26,'abc',Infinity,'']) assert.equal(normalizeQuantity(bad,25), null);
    assert.equal(normalizeQuantity('1',25),1);
    assert.equal(normalizeQuantity('25',25),25);
});
