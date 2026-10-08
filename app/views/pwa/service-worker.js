// Receives push notifications (see PushSubscription / Notifications). Deliberately no fetch handler
// or caching, so it can never serve stale pages.
self.addEventListener("install", () => self.skipWaiting())
self.addEventListener("activate", event => event.waitUntil(self.clients.claim()))

self.addEventListener("push", event => {
  const data = event.data ? event.data.json() : {}
  event.waitUntil(
    self.registration.showNotification(data.title || "PR!OR!TY!", {
      body: data.body,
      icon: "/web-app-manifest-192x192.png",
      badge: "/favicon-96x96.png",
      tag: data.tag,
      renotify: Boolean(data.tag), // still buzz when a newer notification replaces an older one
      data: { url: data.url || "/" }
    })
  )
})

// Tapping a notification opens its list, reusing an open Priority window if there is one
self.addEventListener("notificationclick", event => {
  event.notification.close()
  const url = new URL(event.notification.data?.url || "/", self.location.origin).href

  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({ type: "window", includeUncontrolled: true })
    const open = windows.find(client => client.url.startsWith(self.location.origin))
    if (open) {
      await open.focus()
      try { return await open.navigate(url) } catch { /* not controlled yet: fall back to a new window */ }
    }
    return self.clients.openWindow(url)
  })())
})
