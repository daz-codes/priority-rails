import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["backdrop", "modal", "mainPanel", "snoozePanel", "title"];
  static values = { taskId: Number };

  toggle() {
    const isHidden = this.modalTarget.hidden;
    this.modalTarget.hidden = !isHidden;
    this.backdropTarget.hidden = !isHidden;
    if (!isHidden) this.resetPanels();
  }

  close() {
    this.modalTarget.hidden = true;
    this.backdropTarget.hidden = true;
    this.resetPanels();
  }

  resetPanels() {
    this.mainPanelTarget.hidden = false;
    this.snoozePanelTarget.hidden = true;
    this.titleTarget.textContent = "Actions";
  }

  showSnooze() {
    this.mainPanelTarget.hidden = true;
    this.snoozePanelTarget.hidden = false;
    this.titleTarget.textContent = "Snooze";
  }

  backToMain() {
    this.resetPanels();
  }

  selectSnooze(event) {
    const snoozedUntil = event.currentTarget.dataset.snoozeValue;
    this.close();
    fetch(`/tasks/${this.taskIdValue}`, {
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

  editNote() {
    this.close();
    const noteBtn = this.element
      .closest("li")
      .querySelector("[data-controller='note']");
    if (noteBtn) noteBtn.click();
  }

  recurring() {
    this.close();
    const recurrenceBtn = this.element
      .closest("li")
      .querySelector("[data-controller='recurrence'] button");
    if (recurrenceBtn) recurrenceBtn.click();
  }

  unsnooze() {
    this.close();
    const form = this.element
      .closest("li")
      .querySelector("[data-actions-menu-target='unsnoozeForm']");
    if (form) form.requestSubmit();
  }

  delete() {
    this.close();
    const form = this.element
      .closest("li")
      .querySelector("[data-actions-menu-target='deleteForm']");
    if (form) form.requestSubmit();
  }
}
