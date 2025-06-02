import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.removeAfterAnimation();
    alert("highlight_remover");
  }

  removeAfterAnimation() {
    const highlighted = this.element.querySelectorAll(".highlight");
    alert(highlighted.length);
    highlighted.forEach((el) => {
      el.addEventListener(
        "animationend",
        (e) => {
          el.classList.remove("highlight");
          alert("animation end");
        },
        { once: true },
      );
    });
  }
}
