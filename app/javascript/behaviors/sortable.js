import Sortable from "sortablejs"

// Drag-and-drop ordering for the task list: <ul data-he-import="behaviors/sortable" data-sort-url="...">
export default function connectSortable({ element }) {
  const sortable = Sortable.create(element, {
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
        body: JSON.stringify({ task_ids: ids })
      })
    }
  })

  return () => sortable.destroy()
}
