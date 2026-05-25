const CACHE = 'showroom-2026-v7';
const OLD_CACHES = ['showroom-2026-v1','showroom-2026-v2','showroom-2026-v3','showroom-2026-v4','showroom-2026-v5','showroom-2026-v6'];

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(
    caches.keys().then(keys =>
        Promise.all(keys.filter(k => OLD_CACHES.includes(k)).map(k => caches.delete(k)))
    ).then(() => clients.claim())
));

self.addEventListener('fetch', e => {
    if (e.request.method !== 'GET') return;

    // HTML navigation: network-first so every reload shows the latest version.
    // Falls back to cache only when offline.
    if (e.request.mode === 'navigate') {
        e.respondWith(
            fetch(e.request).then(res => {
                caches.open(CACHE).then(c => c.put(e.request, res.clone()));
                return res;
            }).catch(() => caches.match(e.request))
        );
        return;
    }

    // Assets (fonts, CSS, JS, images): stale-while-revalidate for fast loads.
    e.respondWith(
        caches.open(CACHE).then(cache =>
            cache.match(e.request).then(cached => {
                const net = fetch(e.request).then(res => {
                    if (res.ok || res.type === 'opaque') cache.put(e.request, res.clone());
                    return res;
                }).catch(() => cached);
                return cached || net;
            })
        )
    );
});
