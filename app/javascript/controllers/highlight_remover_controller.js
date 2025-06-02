import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.removeAfterAnimation();
  }

  removeAfterAnimation() {
    const highlighted = this.element.querySelectorAll(".highlight");
    highlighted.forEach((el) => {
      el.addEventListener(
        "animationend",
        (e) => {
          el.classList.remove("highlight");
        },
        { once: true },
      );
    });
  }
}
