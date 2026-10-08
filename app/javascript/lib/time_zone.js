// Fills in the account's time zone from the browser when it hasn't been set yet (the layout adds
// <meta name="detect-time-zone"> in that case), then refreshes so "today" is right straight away.
async function detectTimeZone() {
  const meta = document.querySelector('meta[name="detect-time-zone"]')
  const zone = Intl.DateTimeFormat().resolvedOptions().timeZone
  if (!meta || !zone) return
  meta.remove() // once per page

  const response = await fetch(meta.content, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
    },
    body: JSON.stringify({ time_zone: zone })
  })
  if (!response.ok) return

  // Lists morph in place; other pages (e.g. the profile showing the zone) are revisited
  if (document.querySelector('meta[name="turbo-refresh-method"][content="morph"]')) {
    window.Turbo.session.refresh(location.href)
  } else {
    window.Turbo.visit(location.href, { action: "replace" })
  }
}

document.addEventListener("turbo:load", detectTimeZone)
