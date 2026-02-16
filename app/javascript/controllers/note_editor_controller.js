import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["display", "form"];

  connect() {
    if (this.hasDisplayTarget) {
      this.displayTarget.querySelectorAll("a").forEach(link => {
        link.setAttribute("target", "_blank")
        link.setAttribute("rel", "noopener noreferrer")
      })
    }
  }

  edit() {
    if (this.hasDisplayTarget) this.displayTarget.hidden = true;
    this.formTarget.hidden = false;
  }
}
