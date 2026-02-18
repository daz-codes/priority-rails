import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  connect() {
    this.clickOutsideHandler = this.handleClickOutside.bind(this);
    this.mouseLeaveHandler = this.hideMenu.bind(this);
    document.addEventListener("click", this.clickOutsideHandler);

    this.taskRow = this.element.closest("li");
    if (this.taskRow) {
      this.taskRow.addEventListener("mouseleave", this.mouseLeaveHandler);
    }
  }

  disconnect() {
    document.removeEventListener("click", this.clickOutsideHandler);
    if (this.taskRow) {
      this.taskRow.removeEventListener("mouseleave", this.mouseLeaveHandler);
    }
  }

  hideMenu() {
    this.menuTarget.hidden = true;
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.hidden = true;
    }
  }

  toggle() {
    const isHidden = this.menuTarget.hidden;
    this.menuTarget.hidden = !isHidden;

    if (isHidden) {
      const rect = this.element.getBoundingClientRect();
      const menu = this.menuTarget;

      menu.style.position = "fixed";
      menu.style.right = `${window.innerWidth - rect.right}px`;
      menu.style.left = "auto";

      menu.style.visibility = "hidden";
      menu.hidden = false;
      const menuHeight = menu.offsetHeight;
      menu.style.visibility = "";

      menu.style.top = `${rect.top - menuHeight}px`;
    }
  }

  select(event) {
    const snoozedUntil = event.currentTarget.dataset.snoozerValue;
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
