import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["lists"];
  static values = {
    listPicker: String,
  };

  connect() {
    this.clickOutsideHandler = this.handleClickOutside.bind(this);
    document.addEventListener("click", this.clickOutsideHandler);
  }

  disconnect() {
    document.removeEventListener("click", this.clickOutsideHandler);
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.listsTarget.hidden = true;
    }
  }

  toggle() {
    this.listsTarget.hidden = !this.listsTarget.hidden;
  }

  select(event) {
    const listId = event.currentTarget.dataset.listPickerValue;
    this.listsTarget.hidden = true;

    if (listId) {
      Turbo.visit(`/lists/${listId}`);
    }
  }

  create() {
    Turbo.visit("/lists/new");
  }
}
