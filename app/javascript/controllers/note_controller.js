import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  toggle() {
    const note = document.getElementById(
      `note_${this.element.closest("li").dataset.id}`,
    );
    if (note) {
      note.hidden = !note.hidden;
    }
  }
}
