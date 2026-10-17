'use strict';

// Keeps BuildQuantify working without a connection. The app shell is
// cached when the worker installs and everything else as it is fetched, so
// after one visit the app starts offline. Pages are fetched network-first,
// so a new release shows up on the next visit; other files are served from
// the cache and refreshed in the background.

const CACHE = 'buildquantify-v5';

const SHELL = [
  './',
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  // Deferred parts: the PDF library and the PDF documents (project, bid,
  // contract, cash flow and purchase schedule), loaded when a PDF is first
  // downloaded. Missing names are skipped.
  'main.dart.js_1.part.js',
  'main.dart.js_2.part.js',
  'main.dart.js_3.part.js',
  'main.dart.js_4.part.js',
  'main.dart.js_5.part.js',
  'main.dart.js_6.part.js',
  'main.dart.js_7.part.js',
  'main.dart.js_8.part.js',
  'manifest.json',
  'favicon.png',
  'icons/mark-64.png',
  'icons/Icon-192.png',
  'assets/FontManifest.json',
  'assets/AssetManifest.bin',
  'assets/AssetManifest.bin.json',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      // A missing file must not stop the rest from being cached.
      await Promise.all(
        SHELL.map((url) =>
          cache.add(new Request(url, { cache: 'reload' })).catch(() => {}),
        ),
      );
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      for (const key of await caches.keys()) {
        if (key !== CACHE) await caches.delete(key);
      }
      await self.clients.claim();
    })(),
  );
});

function cacheable(url) {
  if (url.origin === self.location.origin) {
    return !url.pathname.endsWith('/sw.js');
  }
  // CanvasKit and fallback fonts when the build uses Google's CDN.
  return url.hostname === 'www.gstatic.com' || url.hostname === 'fonts.gstatic.com';
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET' || request.headers.has('range')) return;
  const url = new URL(request.url);
  if (!cacheable(url)) return;
  event.respondWith(
    request.mode === 'navigate'
      ? networkFirst(request)
      : staleWhileRevalidate(event, request),
  );
});

async function networkFirst(request) {
  const cache = await caches.open(CACHE);
  try {
    const response = await fetch(request);
    if (response.ok) await cache.put(request, response.clone());
    return response;
  } catch (error) {
    return (
      (await cache.match(request, { ignoreSearch: true })) ||
      (await cache.match('index.html')) ||
      (await cache.match('./')) ||
      Response.error()
    );
  }
}

async function staleWhileRevalidate(event, request) {
  const cache = await caches.open(CACHE);
  const cached = await cache.match(request);
  const refresh = fetch(request)
    .then((response) => {
      if (response.ok) cache.put(request, response.clone());
      return response;
    })
    .catch(() => undefined);
  if (cached) {
    event.waitUntil(refresh);
    return cached;
  }
  return (await refresh) || Response.error();
}
