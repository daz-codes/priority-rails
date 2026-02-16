import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["taskList"]

  connect() {
    this.selectedIndex = -1
    this._onKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this._onKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKeydown)
  }

  handleKeydown(event) {
    // Ignore when typing in inputs/textareas/contenteditable
    const tag = event.target.tagName
    if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT" || event.target.isContentEditable) {
      // But still handle Escape to close menu
      if (event.key === "Escape") {
        this.closeMenu()
        event.target.blur()
      }
      return
    }

    if (event.metaKey || event.ctrlKey || event.altKey) return

    const menu = document.querySelector("[data-controller='menu']")
    const menuOpen = menu && !menu.querySelector("[data-menu-target='modal']").hidden

    if (menuOpen) {
      this.handleMenuKeys(event, menu)
    } else {
      this.handlePageKeys(event)
    }
  }

  handleMenuKeys(event, menu) {
    const items = this.visibleMenuItems(menu)

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.highlightMenuItem(items)
        break
      case "ArrowUp":
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
        this.highlightMenuItem(items)
        break
      case "Enter":
        event.preventDefault()
        if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
          const link = items[this.selectedIndex].querySelector("a[href]")
          if (link) Turbo.visit(link.href)
        }
        break
      case "Escape":
        event.preventDefault()
        this.closeMenu()
        break
    }
  }

  handlePageKeys(event) {
    switch (event.key) {
      case "p":
      case "P":
        event.preventDefault()
        this.openMenu()
        break
      case "1":
      case "2":
      case "3":
      case "4":
        this.switchTab(event.key)
        break
      case "ArrowDown":
        event.preventDefault()
        this.navigateTasks(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this.navigateTasks(-1)
        break
      case "Enter":
        event.preventDefault()
        this.toggleSelectedTask()
        break
      case "Escape":
        this.clearTaskSelection()
        break
      case "/":
        event.preventDefault()
        this.focusTaskInput()
        break
    }
  }

  openMenu() {
    const btn = document.querySelector("[data-controller='menu'] button[data-action*='menu#toggle']")
    if (btn) {
      this.selectedIndex = -1
      btn.click()
    }
  }

  closeMenu() {
    const menu = document.querySelector("[data-controller='menu']")
    if (menu) {
      const modal = menu.querySelector("[data-menu-target='modal']")
      if (modal && !modal.hidden) {
        modal.hidden = true
        this.selectedIndex = -1
        this.clearMenuHighlight(menu)
      }
    }
  }

  visibleMenuItems(menu) {
    const container = menu.querySelector("[data-menu-target='listContainer']")
    if (!container) return []
    return Array.from(container.querySelectorAll("li")).filter(li => li.style.display !== "none")
  }

  highlightMenuItem(items) {
    items.forEach((item, i) => {
      if (i === this.selectedIndex) {
        item.classList.add("bg-green-100", "dark:bg-green-900")
        item.scrollIntoView({ block: "nearest" })
      } else {
        item.classList.remove("bg-green-100", "dark:bg-green-900")
      }
    })
  }

  clearMenuHighlight(menu) {
    const items = menu.querySelectorAll("[data-menu-target='listContainer'] li")
    items.forEach(item => item.classList.remove("bg-green-100", "dark:bg-green-900"))
  }

  switchTab(key) {
    const tabs = document.querySelectorAll("#list_actions a")
    const index = parseInt(key) - 1
    if (tabs[index]) Turbo.visit(tabs[index].href)
  }

  get taskItems() {
    const container = document.getElementById("tasks")
    if (!container) return []
    return Array.from(container.querySelectorAll("li[id^='task_']"))
  }

  navigateTasks(direction) {
    const items = this.taskItems
    if (items.length === 0) return

    const current = items.findIndex(li => li.classList.contains("keyboard-selected"))
    let next = current + direction

    if (current === -1) {
      next = direction > 0 ? 0 : items.length - 1
    } else {
      next = Math.max(0, Math.min(next, items.length - 1))
    }

    items.forEach(li => li.classList.remove("keyboard-selected"))
    items[next].classList.add("keyboard-selected")
    items[next].scrollIntoView({ block: "nearest" })
  }

  toggleSelectedTask() {
    const selected = document.querySelector("li.keyboard-selected")
    if (!selected) return

    const checkbox = selected.querySelector("input[type='checkbox'].task-checkbox")
    if (checkbox) checkbox.click()
  }

  clearTaskSelection() {
    this.taskItems.forEach(li => li.classList.remove("keyboard-selected"))
  }

  focusTaskInput() {
    const input = document.querySelector("#new_task_form input[type='text']")
    if (input) input.focus()
  }
}
