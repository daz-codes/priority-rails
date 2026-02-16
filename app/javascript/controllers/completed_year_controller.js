import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "arrow"]
  static values = { url: String, loaded: { type: Boolean, default: false } }

  async toggle(event) {
    event.preventDefault()

    if (!this.loadedValue) {
      this.arrowTarget.textContent = "↓"
      const response = await fetch(this.urlValue, {
        headers: { "Accept": "text/html" }
      })
      this.contentTarget.innerHTML = await response.text()
      this.loadedValue = true
      this.contentTarget.hidden = false
    } else if (this.contentTarget.hidden) {
      this.arrowTarget.textContent = "↓"
      this.contentTarget.hidden = false
    } else {
      this.arrowTarget.innerHTML = "&rsaquo;"
      this.contentTarget.hidden = true
    }
  }
}
