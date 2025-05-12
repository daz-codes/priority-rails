// tasks_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["position"];

  connect() {
    this.updateLater("connected");
    document.addEventListener("turbo:morph", () => this.updateLater("morph"));
    document.addEventListener("turbo:render", () => this.updateLater("render"));
  }

  updateLater(source) {
    setTimeout(() => this.updatePositions(), 0);
  }

  updatePositions() {
    const tasks = document.querySelectorAll("[data-task-target='position']");
    tasks.forEach((el, index) => (el.textContent = `${index + 1}.`));
  }
}
