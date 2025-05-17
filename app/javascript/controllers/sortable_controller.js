import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  connect() {
    this.sortable = Sortable.create(this.element, {
      onEnd: this.dragEnd.bind(this),
    });
  }

  dragEnd(event) {
    const ids = Array.from(this.element.children).map((el) => el.dataset.id);
    fetch("/tasks/sort", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")
          .content,
      },
      body: JSON.stringify({ task_ids: ids }),
    });
  }
}
