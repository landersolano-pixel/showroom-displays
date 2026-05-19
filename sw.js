const CACHE = 'showroom-2026-v1';

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(clients.claim()));

self.addEventListener('fetch', e => {
    if (e.request.method !== 'GET') return;
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
