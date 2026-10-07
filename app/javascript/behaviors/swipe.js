// Touch swipes on task rows: right to snooze (opens the snooze picker), left to delete (with undo).
// The row follows the finger over a coloured strip showing what will happen, and only acts if it's
// let go past THRESHOLD of the row's width; otherwise it springs back. Attached to <body>, so rows
// added by live updates are covered too. Touch events (not pointer events) so the swipe can stop
// the browser treating the gesture as a scroll.
const THRESHOLD = 0.6
const DECIDE_AFTER = 10 // px moved before telling a sideways swipe from a vertical scroll
const SETTLE_MS = 200

const rowFor = target => target.closest?.("#tasks li[id^='task_']")
const ignoredTarget = target => target.closest("input, select, textarea, button, [contenteditable], [data-task-panel]")
const canSnooze = row => !row.querySelector(".task-struck")
const csrfToken = () => document.querySelector("meta[name='csrf-token']")?.content

export default function connectSwipe({ data, signal }) {
  let gesture = null

  const begin = g => {
    g.state = "swiping"
    g.width = g.row.offsetWidth
    const parent = g.row.parentElement
    if (getComputedStyle(parent).position === "static") parent.style.position = "relative"

    g.layer = document.createElement("div")
    g.layer.className = "swipe-layer"
    g.layer.setAttribute("aria-hidden", "true")
    g.layer.innerHTML = '<span class="swipe-snooze"><i class="fa-solid fa-clock"></i> Snooze</span>' +
                        '<span class="swipe-delete">Delete <i class="fa-solid fa-trash"></i></span>'
    Object.assign(g.layer.style, {
      top: `${g.row.offsetTop}px`, left: `${g.row.offsetLeft}px`,
      width: `${g.row.offsetWidth}px`, height: `${g.row.offsetHeight}px`,
      borderRadius: getComputedStyle(g.row).borderRadius
    })
    parent.insertBefore(g.layer, g.row)

    // Rows without their own background (e.g. without the bold theme) would show the strip through
    if (getComputedStyle(g.row).backgroundColor === "rgba(0, 0, 0, 0)") g.row.style.backgroundColor = "var(--surface-primary)"
    g.row.classList.add("swiping")
  }

  const render = g => {
    g.row.style.transform = `translateX(${g.dx}px)`
    g.layer.dataset.direction = g.dx > 0 ? "snooze" : "delete"
    g.layer.classList.toggle("armed", Math.abs(g.dx) > g.width * THRESHOLD)
  }

  const slideTo = (g, x) => new Promise(resolve => {
    g.row.style.transition = `transform ${SETTLE_MS}ms ease-out`
    g.row.style.transform = `translateX(${x}px)`
    setTimeout(resolve, SETTLE_MS)
  })

  const reset = g => {
    g.layer?.remove()
    g.row.classList.remove("swiping")
    g.row.style.transform = g.row.style.transition = g.row.style.backgroundColor = ""
  }

  // The tap that ends a swipe shouldn't also open the task
  const swallowNextClick = row => {
    const swallow = event => { event.preventDefault(); event.stopPropagation() }
    row.addEventListener("click", swallow, { capture: true, once: true })
    setTimeout(() => row.removeEventListener("click", swallow, { capture: true }), 400)
  }

  const deleteTask = async g => {
    await slideTo(g, -g.width * 1.1)
    try {
      const response = await fetch(`/tasks/${g.row.dataset.id}`, {
        method: "DELETE",
        headers: { Accept: "text/vnd.turbo-stream.html", "X-CSRF-Token": csrfToken() },
        credentials: "same-origin"
      })
      if (!response.ok) throw new Error(`Delete failed: ${response.status}`)
      // Removes the row and shows the undo toast
      window.Turbo.renderStreamMessage(await response.text())
      g.layer.remove()
    } catch (error) {
      await slideTo(g, 0)
      reset(g)
      throw error
    }
  }

  document.addEventListener("touchstart", event => {
    if (event.touches.length !== 1) return (gesture = null)
    const row = rowFor(event.target)
    if (!row || ignoredTarget(event.target)) return
    const touch = event.touches[0]
    gesture = { row, startX: touch.clientX, startY: touch.clientY, dx: 0, state: "pending" }
  }, { signal, passive: true })

  document.addEventListener("touchmove", event => {
    if (!gesture) return
    const touch = event.touches[0]
    const dx = touch.clientX - gesture.startX
    const dy = touch.clientY - gesture.startY

    if (gesture.state === "pending") {
      if (Math.abs(dx) < DECIDE_AFTER && Math.abs(dy) < DECIDE_AFTER) return
      if (Math.abs(dy) >= Math.abs(dx)) return (gesture = null) // a scroll: leave it to the browser
      begin(gesture)
    }

    event.preventDefault() // sideways swipe: don't let the browser pan or start a drag
    gesture.dx = dx > 0 && !canSnooze(gesture.row) ? 0 : dx
    render(gesture)
  }, { signal, passive: false })

  document.addEventListener("touchend", () => {
    const g = gesture
    gesture = null
    if (!g || g.state !== "swiping") return

    swallowNextClick(g.row)
    const armed = Math.abs(g.dx) > g.width * THRESHOLD
    if (armed && g.dx < 0) {
      deleteTask(g)
    } else {
      slideTo(g, 0).then(() => reset(g))
      if (armed && g.dx > 0) data.snoozeTask = { url: `/tasks/${g.row.dataset.id}` }
    }
  }, { signal })

  document.addEventListener("touchcancel", () => {
    const g = gesture
    gesture = null
    if (g?.state === "swiping") slideTo(g, 0).then(() => reset(g))
  }, { signal })
}
