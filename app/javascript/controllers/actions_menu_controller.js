import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["backdrop", "modal"];

  toggle() {
    const isHidden = this.modalTarget.hidden;
    this.modalTarget.hidden = !isHidden;
    this.backdropTarget.hidden = !isHidden;
  }

  close() {
    this.modalTarget.hidden = true;
    this.backdropTarget.hidden = true;
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

  snooze() {
    this.close();
    const snoozeBtn = this.element
      .closest("li")
      .querySelector("[data-controller='snoozer'] button");
    if (snoozeBtn) snoozeBtn.click();
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
