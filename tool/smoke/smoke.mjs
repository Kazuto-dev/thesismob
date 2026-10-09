// End-to-end smoke test of the release web build in Chromium.
//
//   flutter build web --release --no-web-resources-cdn
//   python3 -m http.server 8090 --directory build/web &
//   cd tool/smoke && npm ci && npx playwright install chromium
//   BASE_URL=http://127.0.0.1:8090/ node smoke.mjs
//
// Flutter draws to a canvas, so the test reads the accessibility tree that
// Flutter mirrors into the DOM once semantics are enabled.
import { chromium } from 'playwright';

const BASE = process.env.BASE_URL ?? 'http://127.0.0.1:8090/';
const viewports = {
  phone: { width: 390, height: 844, deviceScaleFactor: 3, isMobile: true, hasTouch: true },
  tablet: { width: 820, height: 1180, deviceScaleFactor: 2, isMobile: true, hasTouch: true },
  desktop: { width: 1440, height: 900, deviceScaleFactor: 1 },
};

const failures = [];
const check = (condition, message) => {
  console.log(`${condition ? 'ok  ' : 'FAIL'} ${message}`);
  if (!condition) failures.push(message);
};

async function open(browser, viewport, hash = '') {
  const context = await browser.newContext({ ...viewport, locale: 'en-PH', serviceWorkers: 'block' });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
  await page.goto(BASE + hash);
  await page.waitForSelector('flutter-view', { state: 'attached', timeout: 60000 });
  await page.waitForTimeout(1500);
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(500);
  return { context, page, errors };
}

/** Accessibility nodes as {label, x, y, w, h}. */
const nodes = (page) => page.evaluate(() =>
  [...document.querySelectorAll('flt-semantics')].map((n) => {
    const r = n.getBoundingClientRect();
    const input = n.querySelector(':scope > input, :scope > textarea');
    // Text sits in the node's own children (#text, <span>, <h2>…), not in
    // nested flt-semantics nodes.
    const own = [...n.childNodes]
      .filter((c) => !c.nodeName.startsWith('FLT-SEMANTICS') && c.nodeName !== 'INPUT' && c.nodeName !== 'TEXTAREA')
      .map((c) => c.textContent).join(' ');
    const label = n.getAttribute('aria-label') || input?.getAttribute('aria-label') || own || '';
    return { label: label.trim(), role: n.getAttribute('role') || (input ? 'textbox' : ''), x: r.x, y: r.y, w: r.width, h: r.height };
  }).filter((n) => n.w > 0 && n.h > 0));

async function tap(page, predicate, description) {
  for (let i = 0; i < 20; i++) {
    const node = (await nodes(page)).find(predicate);
    if (node) {
      await page.mouse.click(node.x + node.w / 2, node.y + node.h / 2);
      return true;
    }
    await page.waitForTimeout(250);
  }
  throw new Error(`not found: ${description}`);
}

const hasText = async (page, text) => (await nodes(page)).some((n) => n.label.includes(text));

async function waitForText(page, text, timeout = 5000) {
  for (let t = 0; t < timeout; t += 250) {
    if (await hasText(page, text)) return true;
    await page.waitForTimeout(250);
  }
  return false;
}

const browser = await chromium.launch();
try {
  // Every screen loads without errors or horizontal overflow at each size.
  for (const [name, viewport] of Object.entries(viewports)) {
    for (const hash of ['', '#/category/structural/chb', '#/summary', '#/history', '#/sheet', '#/help']) {
      const { context, page, errors } = await open(browser, viewport, hash);
      const overflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
      check(errors.length === 0 && !overflow, `${name} ${hash || '#/'} loads cleanly${errors.length ? `: ${errors[0]}` : ''}`);
      await context.close();
    }
  }

  // Home lists the categories, all reachable.
  {
    const { context, page } = await open(browser, viewports.phone);
    for (const c of ['Structural', 'Architectural', 'Electrical', 'Plumbing']) {
      check(await hasText(page, c), `home shows ${c}`);
    }
    await context.close();
  }

  // A full estimate: invalid input is blocked, a valid one is added to the summary.
  {
    const { context, page, errors } = await open(browser, viewports.phone, '#/category/structural/chb');
    const field = (label) => (n) => n.role === 'textbox' && n.label.startsWith(label);
    const fill = async (label, value) => {
      await tap(page, field(label), label);
      await page.keyboard.type(value);
    };

    await tap(page, (n) => n.label === 'Calculate', 'Calculate');
    check(await waitForText(page, 'Enter a wall length'), 'empty form shows a validation message');

    await fill('Wall length', '10');
    await fill('Wall height', '3');
    await fill('Price per block', '25');
    await tap(page, (n) => n.label === 'Calculate', 'Calculate');
    check(await waitForText(page, '₱9,375.00'), 'CHB 10 m × 3 m at ₱25 costs ₱9,375.00');
    check(await hasText(page, '375 blocks'), 'and needs 375 blocks');

    await tap(page, (n) => n.label.startsWith('Add to summary'), 'Add to summary');
    check(await waitForText(page, 'Added to summary'), 'adding to the summary disables the button');

    await page.goto(BASE + '#/summary');
    await page.waitForTimeout(1500);
    check(await waitForText(page, 'Total, 1 item'), 'summary shows one item');
    check(await hasText(page, '₱9,375.00'), 'summary total is ₱9,375.00');
    check(errors.length === 0, `no errors during the estimate${errors.length ? `: ${errors[0]}` : ''}`);
    await context.close();
  }

  // Old bookmarks still work.
  {
    const { context, page } = await open(browser, viewports.desktop, '#/CHBpages');
    check(await waitForText(page, 'Concrete Hollow Blocks'), 'legacy #/CHBpages opens the CHB calculator');
    await context.close();
  }
} catch (e) {
  failures.push(String(e));
  console.error(e);
} finally {
  await browser.close();
}

if (failures.length) {
  console.error(`\n${failures.length} check(s) failed`);
  process.exit(1);
}
console.log('\nAll smoke checks passed');
