import { pushSupported, currentSubscription, subscribe, unsubscribe } from "lib/push"

const GIVE_UP_AFTER = 30 * 1000 // the browser's push service can occasionally fail to answer at all

const withTimeout = promise => Promise.race([
  promise,
  new Promise((_, reject) => setTimeout(() => reject(new Error("Timed out talking to the push service")), GIVE_UP_AFTER))
])

// The profile page's "Notifications on this device" switch. Drives the section's `pushState`:
// unsupported | blocked | off | on | working | failed
export default async function connectPushSettings({ element, data }) {
  if (!pushSupported()) return (data.pushState = "unsupported")
  if (Notification.permission === "denied") return (data.pushState = "blocked")

  data.pushState = (await currentSubscription()) ? "on" : "off"

  element.addEventListener("push:enable", async () => {
    data.pushState = "working"
    const attempt = subscribe(element.dataset.vapidKey)
    // If it does finish after we've given up, show that it worked after all
    attempt.then(result => { if (result === "granted" && data.pushState === "failed") data.pushState = "on" }, () => {})
    try {
      const result = await withTimeout(attempt)
      data.pushState = result === "granted" ? "on" : result === "denied" ? "blocked" : "off"
    } catch (error) {
      console.error(error)
      data.pushState = "failed"
    }
  })

  element.addEventListener("push:disable", async () => {
    data.pushState = "working"
    await unsubscribe()
    data.pushState = "off"
  })
}
