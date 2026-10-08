// Suggests categories while typing a #tag in the add-task box. Tab (or tapping a suggestion)
// completes the tag: "finish report #w" + Tab -> "finish report #work ". Up/Down choose between
// several matches, Escape closes the list, and Tab without a #tag being typed works as normal.
// Categories come from the form's data-categories ([{ name, tag, color }], kept current by live
// updates); the suggestions list is server-rendered so page refreshes keep it.
const TOKEN = /(?:^|\s)#([^\s#]*)$/ // a #tag that ends at the caret
const key = text => text.toLowerCase().replace(/[^\p{L}\p{N}]/gu, "") // as the server matches tags

export default function connectCategoryAutocomplete({ element, signal }) {
  const input = element.querySelector("input[name='task[description]']")
  const list = () => element.querySelector("[data-category-suggestions]")
  let matches = []
  let index = 0

  const categories = () => {
    try { return JSON.parse(element.dataset.categories || "[]") } catch { return [] }
  }

  const currentToken = () => {
    const before = input.value.slice(0, input.selectionStart)
    const match = before.match(TOKEN)
    return match && { typed: match[1], start: before.length - match[1].length - 1 }
  }

  const render = () => {
    const menu = list()
    menu.hidden = matches.length === 0
    menu.replaceChildren(...matches.map((category, i) => {
      const item = document.createElement("li")
      item.setAttribute("role", "option")
      item.setAttribute("aria-selected", i === index)
      item.className = `flex items-center gap-2 px-3 py-2 rounded-lg cursor-pointer text-sm font-bold ${i === index ? "bg-surface-hover" : ""}`
      item.innerHTML = '<span class="size-3 rounded-full shrink-0"></span><span></span>'
      item.firstChild.style.backgroundColor = category.color
      item.lastChild.textContent = `#${category.tag}`
      item.addEventListener("mousedown", event => event.preventDefault()) // keep the input focused
      item.addEventListener("click", () => complete(i))
      return item
    }))
  }

  const update = () => {
    const token = currentToken()
    const typed = token ? key(token.typed) : null
    matches = token ? categories().filter(category => key(category.name).startsWith(typed)) : []
    // Nothing left to complete once the tag is already whole
    if (matches.length === 1 && key(matches[0].name) === typed) matches = []
    index = 0
    render()
  }

  const close = () => { matches = []; render() }

  const complete = i => {
    const token = currentToken()
    if (!token || !matches[i]) return
    const before = input.value.slice(0, token.start)
    const after = input.value.slice(input.selectionStart).replace(/^\S*\s*/, "") // rest of a half-typed word
    const tag = `#${matches[i].tag} `
    input.value = before + tag + after
    const caret = (before + tag).length
    input.setSelectionRange(caret, caret)
    close()
    input.focus()
  }

  input.addEventListener("input", update, { signal })
  input.addEventListener("click", update, { signal })
  input.addEventListener("blur", close, { signal })
  element.addEventListener("submit", close, { signal })

  input.addEventListener("keydown", event => {
    if (matches.length === 0) return
    switch (event.key) {
      case "Tab":
        if (event.shiftKey) return
        event.preventDefault()
        complete(index)
        break
      case "ArrowDown":
        event.preventDefault()
        index = (index + 1) % matches.length
        render()
        break
      case "ArrowUp":
        event.preventDefault()
        index = (index - 1 + matches.length) % matches.length
        render()
        break
      case "Escape":
        event.stopPropagation() // just close the list; don't also leave the box
        close()
        break
    }
  }, { signal })
}
