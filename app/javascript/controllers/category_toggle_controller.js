import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    const el = event.target
    const form = el.closest("form")

    if (el.tagName === "SELECT") {
      const option = el.options[el.selectedIndex]
      const color = option?.dataset?.color
      const textColor = option?.dataset?.textColor

      if (color) el.style.backgroundColor = color
      if (textColor) el.style.color = textColor
    }

    form.requestSubmit()
  }
}
