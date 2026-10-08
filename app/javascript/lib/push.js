// Web Push for this browser/device: register the service worker, and subscribe or unsubscribe
// with the server (PushSubscriptionsController).
export const pushSupported = () => "serviceWorker" in navigator && "PushManager" in window && "Notification" in window

const csrfToken = () => document.querySelector("meta[name='csrf-token']")?.content

// The VAPID public key is base64url; the Push API wants raw bytes
const keyBytes = base64 => {
  const padded = (base64 + "=".repeat((4 - base64.length % 4) % 4)).replace(/-/g, "+").replace(/_/g, "/")
  return Uint8Array.from(atob(padded), char => char.charCodeAt(0))
}

export const registration = () => navigator.serviceWorker.register("/service-worker.js", { scope: "/" })

export async function currentSubscription() {
  return (await registration()).pushManager.getSubscription()
}

export async function subscribe(vapidPublicKey) {
  const permission = await Notification.requestPermission()
  if (permission !== "granted") return permission

  const subscription = await (await registration()).pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: keyBytes(vapidPublicKey)
  })
  const response = await fetch("/push_subscription", {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
    body: JSON.stringify({ subscription: subscription.toJSON() })
  })
  if (!response.ok) {
    await subscription.unsubscribe()
    throw new Error(`Saving the subscription failed (${response.status})`)
  }
  return "granted"
}

export async function unsubscribe() {
  const subscription = await currentSubscription()
  if (!subscription) return
  await fetch(`/push_subscription?endpoint=${encodeURIComponent(subscription.endpoint)}`, {
    method: "DELETE",
    headers: { "X-CSRF-Token": csrfToken() }
  })
  await subscription.unsubscribe()
}

// Keep the worker registered and up to date for devices that already turned notifications on
if (pushSupported() && Notification.permission === "granted") registration()
