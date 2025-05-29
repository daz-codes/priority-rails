import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  toggle() {
    this.menuTarget.hidden = !this.menuTarget.hidden;
  }

  select(event) {
    const snoozedUntil = event.currentTarget.dataset.value;
    const id = this.element.dataset.taskId;
    this.menuTarget.hidden = true;
    fetch(`/tasks/${id}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")
          .content,
      },
      body: JSON.stringify({ task: { snoozed_until: snoozedUntil } }),
    });
  }
}
