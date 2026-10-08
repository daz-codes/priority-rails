import Sortable from "sortablejs"

// Drag-and-drop ordering: <ul data-he-import="behaviors/sortable" data-sort-url="...">. Each child's
// data-id is sent, in order, as data-sort-param (task_ids by default). data-sort-handle limits
// dragging to an element matching that selector, so rows with inputs can still be used.
export default function connectSortable({ element }) {
  const param = element.dataset.sortParam || "task_ids"
  const sortable = Sortable.create(element, {
    handle: element.dataset.sortHandle || undefined,
    delay: 100,
    delayOnTouchOnly: true,
    touchStartThreshold: 2,
    onEnd() {
      const ids = Array.from(element.children).map(child => child.dataset.id)
      fetch(element.dataset.sortUrl, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        },
        body: JSON.stringify({ [param]: ids })
      })
    }
  })

  return () => sortable.destroy()
}
