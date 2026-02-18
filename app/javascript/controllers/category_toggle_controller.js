import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    const select = event.target
    const option = select.options[select.selectedIndex]
    const color = option?.dataset?.color
    const textColor = option?.dataset?.textColor

    if (color) select.style.backgroundColor = color
    if (textColor) select.style.color = textColor

    select.form.requestSubmit()
  }
}
