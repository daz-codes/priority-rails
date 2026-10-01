import "@hotwired/turbo-rails"
import "lexxy"
import "@rails/actiontext"
import helium from "helium"
import { isDarkTheme, toggleTheme } from "lib/theme"

// Functions available to every Helium expression on the page
helium({
  isDarkTheme,
  toggleTheme,

  // Recolour the category pill and its task row straight away, then save the choice
  chooseCategory(select) {
    const option = select.options[select.selectedIndex]
    if (option?.dataset.color) {
      select.style.backgroundColor = option.dataset.color
      select.closest("li")?.style.setProperty("--category-color", option.dataset.color)
    }
    if (option?.dataset.textColor) select.style.color = option.dataset.textColor
    select.form.requestSubmit()
  },

  // Menu filter: true when a list's name matches the search text
  matchesQuery(element, query) {
    const text = query.trim().toLowerCase()
    return !text || element.textContent.toLowerCase().includes(text)
  },

  openLinksInNewTab(element) {
    element.querySelectorAll("a").forEach(link => {
      link.target = "_blank"
      link.rel = "noopener noreferrer"
    })
  }
})
