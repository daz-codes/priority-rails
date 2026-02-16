import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "input", "listContainer"]

  toggle() {
    this.modalTarget.toggleAttribute("hidden")
    if (!this.modalTarget.hidden) {
      this.inputTarget.value = ""
      this.filter()
    }
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.modalTarget.hidden = true
    }
  }

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    const items = this.listContainerTarget.querySelectorAll("li")

    items.forEach(item => {
      const name = item.textContent.toLowerCase()
      item.style.display = !query || name.includes(query) ? "" : "none"
    })
  }

  connect() {
    this._outsideClick = this.close.bind(this)
    document.addEventListener("click", this._outsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick)
  }
}
