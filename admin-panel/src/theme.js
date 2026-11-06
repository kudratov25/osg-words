import { reactive } from 'vue'

/**
 * Day / night theme. First visit follows the device setting (and keeps
 * following it live); once the user picks one, that choice is remembered.
 * index.html applies the same rule inline before the page paints, so there
 * is no flash of the wrong theme.
 */
const STORAGE_KEY = 'osg_admin_theme'
const META_COLOR = { dark: '#0B0E14', light: '#EEF2F9' }
const media = typeof window !== 'undefined' && window.matchMedia ? window.matchMedia('(prefers-color-scheme: light)') : null

function storedChoice() {
  try {
    const v = localStorage.getItem(STORAGE_KEY)
    return v === 'light' || v === 'dark' ? v : null
  } catch {
    return null
  }
}

function systemTheme() {
  return media?.matches ? 'light' : 'dark'
}

function apply(value) {
  document.documentElement.dataset.theme = value
  document.querySelector('meta[name="theme-color"]')?.setAttribute('content', META_COLOR[value])
}

export const theme = reactive({ value: storedChoice() ?? systemTheme() })
apply(theme.value)

media?.addEventListener?.('change', () => {
  if (!storedChoice()) {
    theme.value = systemTheme()
    apply(theme.value)
  }
})

export function setTheme(value) {
  theme.value = value
  apply(value)
  try {
    localStorage.setItem(STORAGE_KEY, value)
  } catch {
    // not remembered across visits - still applied now
  }
}
