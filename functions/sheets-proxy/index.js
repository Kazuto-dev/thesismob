'use strict';

// HTTP Cloud Function that appends estimate rows to a Google Sheet.
//
// It runs as the service account the function is deployed with (Application
// Default Credentials), so no key file exists anywhere. A spreadsheet is only
// writable if its owner shared it with that service account.

const functions = require('@google-cloud/functions-framework');
const { GoogleAuth } = require('google-auth-library');
const { validateRequest, a1Sheet, ValidationError } = require('./validate');

const SHEETS_API = 'https://sheets.googleapis.com/v4/spreadsheets';
const auth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/spreadsheets'] });

function allowedOrigins() {
  return (process.env.ALLOWED_ORIGINS || '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
}

function applyCors(req, res) {
  const origin = req.get('Origin');
  const allowed = allowedOrigins();
  if (origin && (allowed.includes(origin) || allowed.includes('*'))) {
    res.set('Access-Control-Allow-Origin', origin);
    res.set('Vary', 'Origin');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.set('Access-Control-Max-Age', '3600');
    return true;
  }
  return !origin; // non-browser callers (curl, tests) send no Origin header
}

async function sheetsRequest(path, init = {}) {
  const client = await auth.getClient();
  const { token } = await client.getAccessToken();
  const response = await fetch(`${SHEETS_API}/${path}`, {
    ...init,
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  });
  const body = await response.json().catch(() => ({}));
  return { status: response.status, body };
}

function fail(res, status, error) {
  res.status(status).json({ error });
}

functions.http('appendRows', async (req, res) => {
  const corsOk = applyCors(req, res);
  if (req.method === 'OPTIONS') return res.status(corsOk ? 204 : 403).send('');
  if (!corsOk) return fail(res, 403, 'Origin not allowed.');
  if (req.method !== 'POST') return fail(res, 405, 'Use POST.');

  let request;
  try {
    request = validateRequest(req.body);
  } catch (e) {
    if (e instanceof ValidationError) return fail(res, 400, e.message);
    throw e;
  }
  const { spreadsheetId, sheetName, header, rows } = request;
  const id = encodeURIComponent(spreadsheetId);

  try {
    const meta = await sheetsRequest(`${id}?fields=sheets.properties.title`);
    if (meta.status === 403) return fail(res, 403, 'The spreadsheet is not shared with the app.');
    if (meta.status === 404) return fail(res, 404, 'Spreadsheet not found.');
    if (meta.status !== 200) return fail(res, 502, 'Google Sheets is unavailable.');

    const titles = (meta.body.sheets || []).map((s) => s.properties.title);
    if (!titles.includes(sheetName)) {
      return fail(res, 404, `There is no sheet named "${sheetName}" in that spreadsheet.`);
    }

    const range = encodeURIComponent(`${a1Sheet(sheetName)}!A1`);
    const values = header ? [header, ...rows] : rows;
    if (header) {
      const first = await sheetsRequest(`${id}/values/${range}`);
      if (first.status === 200 && Array.isArray(first.body.values) && first.body.values.length) {
        values.shift(); // the sheet already has content, so keep its header
      }
    }

    // RAW stores text literally, so a material name can never become a formula.
    const appended = await sheetsRequest(
      `${id}/values/${range}:append?valueInputOption=RAW&insertDataOption=INSERT_ROWS`,
      { method: 'POST', body: JSON.stringify({ values }) },
    );
    if (appended.status !== 200) return fail(res, 502, 'Google Sheets rejected the rows.');
    return res.status(200).json({ ok: true, appendedRows: rows.length });
  } catch (e) {
    console.error('append failed', e);
    return fail(res, 500, 'Export failed.');
  }
});
