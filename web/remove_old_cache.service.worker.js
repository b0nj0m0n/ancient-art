// Earlier builds installed an offline cache that kept serving old builds.
// This replaces it: it deletes every cache, removes itself, then reloads the
// page once at a fresh address so the browser fetches the latest build.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
	event.waitUntil((async () => {
		await self.clients.claim(); // Take over the open page so it can be reloaded.
		const keys = await caches.keys();
		await Promise.all(keys.map((key) => caches.delete(key)));
		await self.registration.unregister();
		const windows = await self.clients.matchAll({ type: 'window' });
		for (const client of windows) {
			const url = new URL(client.url);
			if (url.searchParams.has('fresh')) {
				continue; // Already reloaded once; never loop.
			}
			url.searchParams.set('fresh', Date.now().toString());
			client.navigate(url.href);
		}
	})());
});
