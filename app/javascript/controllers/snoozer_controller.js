import { Controller } from "@hotwired/stimulus";
import { patch } from "@rails/request.js";

export default class extends Controller {
  static targets = ["backdrop", "modal"];
  static values = { taskId: Number };

  toggle(event) {
    event.stopPropagation();
    if (this.modalTarget.hidden) {
      this.open();
    } else {
      this.close();
    }
  }

  open() {
    this.backdropTarget.hidden = false;
    this.modalTarget.hidden = false;
  }

  close() {
    this.backdropTarget.hidden = true;
    this.modalTarget.hidden = true;
  }

  select(event) {
    const snoozedUntil = event.currentTarget.dataset.snoozeUntil;
    this.close();
    patch(`/tasks/${this.taskIdValue}`, {
      body: JSON.stringify({ task: { snoozed_until: snoozedUntil } }),
      contentType: "application/json",
      responseKind: "turbo-stream",
    });
  }
}
