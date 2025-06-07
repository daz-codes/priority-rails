import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.element.addEventListener("submit", () => {
      const editor = this.element.querySelector("trix-editor");
      if (editor) {
        // Force the Trix editor to sync its contents to the hidden input
        editor.editor.loadHTML(editor.innerHTML);
        editor.dispatchEvent(new Event("change", { bubbles: true }));
      }
    });
  }
}
