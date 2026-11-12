const CACHE = 'smart-grocery-v2';
const CDN = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.js';
const FILES = ['./', 'index.html', 'config.js', 'manifest.webmanifest', 'icon-180.png', 'icon-192.png', 'icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => Promise.all([c.addAll(FILES), c.add(CDN).catch(() => {})]))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Network-first για το site και τη βιβλιοθήκη. Τα αιτήματα προς το Supabase (δεδομένα/σύνδεση) δεν περνούν από την cache.
self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  const same = url.origin === self.location.origin;
  if (!same && url.hostname !== 'cdn.jsdelivr.net') return;
  e.respondWith(
    fetch(req, same ? { cache: 'no-cache' } : undefined)
      .then(res => {
        if (res && (res.ok || res.type === 'opaque')) {
          const copy = res.clone();
          caches.open(CACHE).then(c => c.put(req, copy));
        }
        return res;
      })
      .catch(() => caches.match(req, { ignoreVary: true }).then(r => r || caches.match('index.html')))
  );
});
