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
    const { width, height } = page.viewportSize();
    // Phones and tablets pin a result bar and navigation bar at the bottom.
    const bottom = width >= 1024 ? 20 : 170;
    const matches = (await nodes(page)).filter(predicate);
    const node = matches.find((n) => n.y >= 0 && n.y + Math.min(n.h, 56) <= height - bottom) ?? matches[0];
    if (node) {
      if (node.y < 0 || node.y + Math.min(node.h, 56) > height - bottom) {
        // Off screen: scroll it into the upper part of the view first.
        await page.mouse.move(width / 2, height / 2);
        await page.mouse.wheel(0, node.y - height / 3);
        await page.waitForTimeout(400);
        continue;
      }
      // Text fields' nodes also cover their helper text, so aim high.
      const y = node.role === 'textbox' ? node.y + Math.min(node.h / 2, 24) : node.y + node.h / 2;
      await page.mouse.click(node.x + node.w / 2, y);
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
    for (const hash of [
      '',
      '#/category/structural/chb',
      '#/category/structural/column',
      '#/category/electrical/rough_in',
      '#/project',
      '#/project/all',
      '#/history',
      '#/settings',
      '#/settings/prices',
      '#/settings/help',
    ]) {
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

  // Search finds materials by their Filipino names.
  {
    const { context, page } = await open(browser, viewports.phone);
    await tap(page, (n) => n.role === 'textbox' && n.label.startsWith('Search'), 'Search');
    await page.waitForFunction(() => document.activeElement?.tagName === 'INPUT', null, { timeout: 3000 }).catch(() => {});
    await page.keyboard.type('yero', { delay: 20 });
    check(await waitForText(page, 'Roofing Sheets'), 'searching "yero" finds roofing sheets');
    await context.close();
  }

  // A full estimate: it appears as you type and can be added to a project.
  {
    const { context, page, errors } = await open(browser, viewports.phone, '#/category/structural/chb');
    const field = (label) => (n) => n.role === 'textbox' && n.label.startsWith(label);
    // Flutter creates the DOM <input> only once a field has focus, so wait
    // for it and confirm the text arrived before moving on.
    const fill = async (label, value) => {
      for (let attempt = 0; attempt < 3; attempt++) {
        await tap(page, field(label), label);
        await page
          .waitForFunction(() => document.activeElement?.tagName === 'INPUT', null, { timeout: 3000 })
          .catch(() => {});
        await page.keyboard.press('Control+A');
        await page.keyboard.press('Backspace');
        await page.keyboard.type(value, { delay: 20 });
        if ((await page.evaluate(() => document.activeElement?.value)) === value) return;
      }
      throw new Error(`could not type into ${label}`);
    };

    check(await waitForText(page, 'Enter wall length'), 'an empty form says what is missing');
    check(await hasText(page, 'From your price book'), 'the price comes from the price book');

    await fill('Wall length', '10');
    await fill('Wall height', '3');
    await fill('Price per block', '25');
    check(await waitForText(page, '₱9,850.00'), 'CHB 10 m × 3 m at ₱25 costs ₱9,850.00 with 5% waste');
    check(await hasText(page, '394 blocks'), 'and needs 394 blocks');

    // Blocks ₱9,850 plus cement, sand, bars and tie wire from the price book.
    check(await hasText(page, '₱23,705.00'), 'the materials total includes cement, sand, bars and tie wire');

    await tap(page, (n) => n.label === 'Add to My project', 'Add to My project');
    check(await waitForText(page, 'Added to My project'), 'adding to the project disables the button');

    await page.goto(BASE + '#/project');
    await page.waitForTimeout(1500);
    check(await waitForText(page, 'Project budget · 1 item'), 'the project shows one item');
    check(await hasText(page, '₱23,705.00'), 'the item costs ₱23,705.00 with its materials');
    // 40% labour and a 10% contingency: 23,705 × 1.4 × 1.1.
    check(await hasText(page, '₱36,505.70'), 'the owner budget is ₱36,505.70');
    const [download] = await Promise.all([
      page.waitForEvent('download', { timeout: 30000 }),
      tap(page, (n) => n.label === 'Download PDF', 'Download PDF'),
    ]);
    check(download.suggestedFilename() === 'my-project-boq.pdf', 'the project downloads as a PDF bill of quantities');
    check(errors.length === 0, `no errors during the estimate${errors.length ? `: ${errors[0]}` : ''}`);
    await context.close();
  }

  // Old bookmarks still work.
  {
    const { context, page } = await open(browser, viewports.desktop, '#/CHBpages');
    check(await waitForText(page, 'Concrete Hollow Blocks'), 'legacy #/CHBpages opens the CHB calculator');
    await context.close();
  }
  {
    const { context, page } = await open(browser, viewports.desktop, '#/summary');
    check(await waitForText(page, 'No estimates yet'), 'legacy #/summary opens the project');
    await context.close();
  }

  // After one visit the app starts and calculates with no connection.
  {
    const context = await browser.newContext({ ...viewports.phone, locale: 'en-PH' });
    const page = await context.newPage();
    await page.goto(BASE + '?offline');
    await page.waitForSelector('flutter-view', { state: 'attached', timeout: 60000 });
    await page.evaluate(() => navigator.serviceWorker.ready);
    // Reload under the worker so everything the app loads is cached, and
    // give the icon warm-up time to run.
    await page.reload();
    await page.waitForSelector('flutter-view', { state: 'attached', timeout: 60000 });
    await page.waitForTimeout(6000);
    await context.setOffline(true);
    await page.goto(BASE + '?offline#/category/structural/slab');
    await page.waitForSelector('flutter-view', { state: 'attached', timeout: 60000 });
    await page.waitForTimeout(1500);
    await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
    check(await waitForText(page, 'Concrete Slab'), 'offline: the slab calculator opens with no connection');
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
