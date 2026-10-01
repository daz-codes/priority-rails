const prefersDark = window.matchMedia("(prefers-color-scheme: dark)")

export function isDarkTheme() {
  const stored = localStorage.getItem("theme")
  return stored ? stored === "dark" : prefersDark.matches
}

export function applyTheme() {
  const dark = isDarkTheme()
  document.documentElement.classList.toggle("dark", dark)
  return dark
}

// Returns the new state so a binding can store it, e.g. @click="dark = toggleTheme()"
export function toggleTheme() {
  localStorage.setItem("theme", isDarkTheme() ? "light" : "dark")
  return applyTheme()
}

// Follow the OS setting until the user picks a theme themselves
prefersDark.addEventListener("change", () => {
  if (!localStorage.getItem("theme")) applyTheme()
})
