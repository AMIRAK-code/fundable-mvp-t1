self.addEventListener('push', (event) => {
  if (!event.data) return
  const { title, body, url } = event.data.json()
  const target = url ?? '/app/feed'
  event.waitUntil(
    self.registration.showNotification(title ?? 'Fundable', {
      body: body ?? '',
      icon: '/favicon.ico',
      badge: '/favicon.ico',
      // One notification per conversation — new pushes replace the old one
      tag: target,
      renotify: true,
      data: { url: target },
    })
  )
})

self.addEventListener('notificationclick', (event) => {
  event.notification.close()
  const url = event.notification.data?.url ?? '/app/feed'
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      for (const client of list) {
        if ('focus' in client) {
          client.navigate(url)
          return client.focus()
        }
      }
      return clients.openWindow(url)
    })
  )
})
