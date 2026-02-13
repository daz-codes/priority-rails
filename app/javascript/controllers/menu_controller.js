import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "input"]

  toggle() {
    this.modalTarget.toggleAttribute("hidden")
    if (!this.modalTarget.hidden) {
      this.inputTarget.focus()
    }
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.modalTarget.hidden = true
    }
  }

  async createList(event) {
    if (event.key !== "Enter") return
    const name = this.inputTarget.value.trim()
    if (!name) return

    const token = document.querySelector('meta[name="csrf-token"]').content
    const response = await fetch("/lists", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token,
        "Accept": "application/json"
      },
      body: JSON.stringify({ list: { name } })
    })

    if (response.ok) {
      const data = await response.json()
      Turbo.visit(data.url)
    }
  }

  connect() {
    this._outsideClick = this.close.bind(this)
    document.addEventListener("click", this._outsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick)
  }
}
