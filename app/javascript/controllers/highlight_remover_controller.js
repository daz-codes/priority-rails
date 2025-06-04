import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.removeAfterAnimation();
    this.removeQueryString();
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

  removeQueryString() {
    if (window.location.search) {
      const url =
        window.location.origin +
        window.location.pathname +
        window.location.hash;
      history.replaceState(null, "", url);
    }
  }
}
