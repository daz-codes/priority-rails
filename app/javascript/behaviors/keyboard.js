// Page-wide keyboard shortcuts, listed on /shortcuts. Attached with <body data-he-import="behaviors/keyboard">.
const HIGHLIGHT = [ "bg-sky-100", "dark:bg-sky-900" ]

const menuModal = () => document.querySelector("[data-menu-modal]")
const menuOpen = () => menuModal() && !menuModal().hidden
const visibleMenuItems = () => Array.from(document.querySelectorAll("[data-menu-list] li")).filter(li => !li.hidden)
const taskItems = () => Array.from(document.querySelectorAll("#tasks li[id^='task_']"))

export default function connectKeyboard({ signal }) {
  let menuIndex = -1

  const highlightMenuItem = items => {
    items.forEach((item, i) => HIGHLIGHT.forEach(name => item.classList.toggle(name, i === menuIndex)))
    items[menuIndex]?.scrollIntoView({ block: "nearest" })
  }

  const clearMenuHighlight = () => {
    document.querySelectorAll("[data-menu-list] li").forEach(item => item.classList.remove(...HIGHLIGHT))
    menuIndex = -1
  }

  const closeMenu = () => {
    if (!menuOpen()) return
    document.dispatchEvent(new CustomEvent("close-menu"))
    clearMenuHighlight()
  }

  const openMenu = () => {
    menuIndex = -1
    document.querySelector("[data-menu-toggle]")?.click()
  }

  const navigateTasks = direction => {
    const items = taskItems()
    if (items.length === 0) return

    const current = items.findIndex(li => li.classList.contains("keyboard-selected"))
    const next = current === -1
      ? (direction > 0 ? 0 : items.length - 1)
      : Math.max(0, Math.min(current + direction, items.length - 1))

    items.forEach(li => li.classList.remove("keyboard-selected"))
    items[next].classList.add("keyboard-selected")
    items[next].scrollIntoView({ block: "nearest" })
  }

  const handleMenuKeys = event => {
    const items = visibleMenuItems()
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        menuIndex = Math.min(menuIndex + 1, items.length - 1)
        highlightMenuItem(items)
        break
      case "ArrowUp":
        event.preventDefault()
        menuIndex = Math.max(menuIndex - 1, 0)
        highlightMenuItem(items)
        break
      case "Enter": {
        event.preventDefault()
        const link = items[menuIndex]?.querySelector("a[href]")
        if (link) Turbo.visit(link.href)
        break
      }
      case "Escape":
        event.preventDefault()
        closeMenu()
        break
    }
  }

  const handlePageKeys = event => {
    switch (event.key) {
      case "p":
      case "P":
        event.preventDefault()
        openMenu()
        break
      case "1":
      case "2":
      case "3":
      case "4": {
        const tab = document.querySelectorAll("#list_actions a")[Number(event.key) - 1]
        if (tab) Turbo.visit(tab.href)
        break
      }
      case "ArrowDown":
        event.preventDefault()
        navigateTasks(1)
        break
      case "ArrowUp":
        event.preventDefault()
        navigateTasks(-1)
        break
      case "Enter":
        event.preventDefault()
        document.querySelector("li.keyboard-selected input.task-checkbox")?.click()
        break
      case "Escape": {
        const back = document.querySelector("[data-escape-back]")
        if (back) Turbo.visit(back.href)
        else taskItems().forEach(li => li.classList.remove("keyboard-selected"))
        break
      }
      case "/":
        event.preventDefault()
        document.querySelector("#new_task_form input[type='text']")?.focus()
        break
    }
  }

  document.addEventListener("keydown", event => {
    const target = event.target
    const typing = [ "INPUT", "TEXTAREA", "SELECT" ].includes(target.tagName) || target.isContentEditable
    if (typing) {
      // Escape still closes the menu and leaves the field
      if (event.key === "Escape") {
        closeMenu()
        target.blur()
      }
      return
    }
    if (event.metaKey || event.ctrlKey || event.altKey) return

    menuOpen() ? handleMenuKeys(event) : handlePageKeys(event)
  }, { signal })
}
