import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["display", "form"];

  edit() {
    if (this.hasDisplayTarget) this.displayTarget.hidden = true;
    this.formTarget.hidden = false;
  }
}
