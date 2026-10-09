'use strict';

// Request validation for the sheets proxy. Kept free of Google/HTTP code so it
// can be unit tested with `node --test`.

const SPREADSHEET_ID = /^[A-Za-z0-9_-]{20,128}$/;
const MAX_ROWS = 200;
const MAX_CELLS = 12;
const MAX_TEXT = 300;
const MAX_SHEET_NAME = 100;

class ValidationError extends Error {}

function validateCell(cell) {
  if (cell === null) return '';
  if (typeof cell === 'number') {
    if (!Number.isFinite(cell)) throw new ValidationError('Numbers must be finite.');
    return cell;
  }
  if (typeof cell === 'string') {
    if (cell.length > MAX_TEXT) throw new ValidationError('A cell is too long.');
    return cell;
  }
  if (typeof cell === 'boolean') return cell;
  throw new ValidationError('Cells must be text, numbers or booleans.');
}

function validateRow(row) {
  if (!Array.isArray(row) || row.length === 0 || row.length > MAX_CELLS) {
    throw new ValidationError(`Each row needs 1-${MAX_CELLS} cells.`);
  }
  return row.map(validateCell);
}

/**
 * Returns a normalised `{ spreadsheetId, sheetName, header, rows }` or throws
 * a ValidationError with a message that is safe to show to the user.
 */
function validateRequest(body) {
  if (!body || typeof body !== 'object') {
    throw new ValidationError('Expected a JSON object.');
  }
  const { spreadsheetId, sheetName, header, rows } = body;
  if (typeof spreadsheetId !== 'string' || !SPREADSHEET_ID.test(spreadsheetId)) {
    throw new ValidationError('That spreadsheet ID is not valid.');
  }
  if (typeof sheetName !== 'string' || !sheetName.trim() || sheetName.length > MAX_SHEET_NAME) {
    throw new ValidationError('Enter the name of a sheet (tab) in the spreadsheet.');
  }
  if (!Array.isArray(rows) || rows.length === 0 || rows.length > MAX_ROWS) {
    throw new ValidationError(`Send between 1 and ${MAX_ROWS} rows.`);
  }
  return {
    spreadsheetId,
    sheetName: sheetName.trim(),
    header: header === undefined ? null : validateRow(header),
    rows: rows.map(validateRow),
  };
}

/** Quotes a sheet title for A1 notation, e.g. `My 'Tab'` -> `'My ''Tab'''`. */
function a1Sheet(sheetName) {
  return `'${sheetName.replace(/'/g, "''")}'`;
}

module.exports = { validateRequest, a1Sheet, ValidationError, MAX_ROWS };
