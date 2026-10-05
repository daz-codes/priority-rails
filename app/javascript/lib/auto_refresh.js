// Bring a list up to date when you come back to it. Live updates only arrive while the page is
// awake, and some changes never broadcast at all (a snooze ending, a new day), so after the app
// has been in the background for a while, morph-refresh the page as a broadcast would.
const STALE_AFTER = 60 * 1000 // long enough that a quick app switch doesn't close an open task panel

let hiddenAt = null

// Only pages that opt into morph refreshes (the list pages), never e.g. a half-filled settings form
const refreshable = () => document.querySelector('meta[name="turbo-refresh-method"][content="morph"]')

function refresh() {
  if (refreshable()) window.Turbo?.session.refresh(location.href)
}

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "hidden") {
    hiddenAt = Date.now()
  } else {
    if (hiddenAt !== null && Date.now() - hiddenAt > STALE_AFTER) refresh()
    hiddenAt = null
  }
})

// iOS Safari often restores a page from its back/forward cache instead of reloading it
window.addEventListener("pageshow", event => {
  if (event.persisted) refresh()
})
