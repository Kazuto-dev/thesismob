'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { validateRequest, a1Sheet, ValidationError, MAX_ROWS } = require('./validate');

const ID = '1AbCdEfGhIjKlMnOpQrStUvWxYz0123456789';
const ok = { spreadsheetId: ID, sheetName: ' Sheet1 ', rows: [['CHB', 30, 375, 9375]] };

test('accepts a well-formed request and trims the sheet name', () => {
  const r = validateRequest({ ...ok, header: ['Materials', 'Area(sqm)', 'Quantity', 'Cost(₱)'] });
  assert.strictEqual(r.sheetName, 'Sheet1');
  assert.deepStrictEqual(r.rows, [['CHB', 30, 375, 9375]]);
  assert.strictEqual(r.header.length, 4);
});

test('header is optional', () => {
  assert.strictEqual(validateRequest(ok).header, null);
});

test('rejects bad spreadsheet IDs', () => {
  assert.throws(() => validateRequest({ ...ok, spreadsheetId: 'not a real id' }), ValidationError);
  assert.throws(() => validateRequest({ ...ok, spreadsheetId: 42 }), ValidationError);
});

test('rejects missing or oversized payloads', () => {
  assert.throws(() => validateRequest({ ...ok, sheetName: '  ' }), ValidationError);
  assert.throws(() => validateRequest({ ...ok, rows: [] }), ValidationError);
  const many = Array.from({ length: MAX_ROWS + 1 }, () => ['x']);
  assert.throws(() => validateRequest({ ...ok, rows: many }), ValidationError);
  assert.throws(() => validateRequest({ ...ok, rows: [['x'.repeat(301)]] }), ValidationError);
});

test('rejects non-finite numbers and nested values', () => {
  assert.throws(() => validateRequest({ ...ok, rows: [[Infinity]] }), ValidationError);
  assert.throws(() => validateRequest({ ...ok, rows: [[{ a: 1 }]] }), ValidationError);
});

test('quotes sheet names for A1 notation', () => {
  assert.strictEqual(a1Sheet("Bob's sheet"), "'Bob''s sheet'");
});
