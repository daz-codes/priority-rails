import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.element.addEventListener(
      "turbo:morph-element",
      this.removeAfterAnimation,
    );
  }

  disconnect() {
    this.element.removeEventListener(
      "turbo:morph-element",
      this.removeAfterAnimation,
    );
  }

  removeAfterAnimation = () => {
    const highlighted = this.element.querySelectorAll(".animate-highlight");
    highlighted.forEach((el) => {
      el.addEventListener(
        "animationend",
        () => {
          el.classList.remove("animate-highlight");
        },
        { once: true },
      );
    });
  };
}
