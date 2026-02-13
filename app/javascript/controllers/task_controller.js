import { Controller } from "@hotwired/stimulus";
import { patch } from "@rails/request.js";

export default class extends Controller {
  static values = { url: String };

  async toggle(event) {
    const checked = event.target.checked;

    await patch(this.urlValue, {
      body: JSON.stringify({ task: { completed: checked } }),
      headers: {
        "Content-Type": "application/json",
        Accept: "text/vnd.turbo-stream.html",
      },
    });
  }
}
