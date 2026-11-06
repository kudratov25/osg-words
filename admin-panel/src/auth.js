import { reactive } from 'vue'
import { parseUtc } from './format'

const STORAGE_KEY = 'osg_admin_session'

function isExpired(s) {
  const exp = parseUtc(s?.expires_at)
  return exp ? exp.getTime() <= Date.now() : false
}

function load() {
  try {
    const s = JSON.parse(localStorage.getItem(STORAGE_KEY) || 'null')
    if (s && s.token && !isExpired(s)) return s
  } catch {
    // storage blocked or corrupt - treat as logged out
  }
  return null
}

/** { token, expires_at, username } or null */
export const session = reactive({ data: load() })

export function isLoggedIn() {
  if (!session.data) return false
  if (isExpired(session.data)) {
    logout()
    return false
  }
  return true
}

export function setSession(data) {
  session.data = data
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data))
  } catch {
    // session then only lives for this tab - acceptable
  }
}

export function logout() {
  session.data = null
  try {
    localStorage.removeItem(STORAGE_KEY)
  } catch {
    // ignore
  }
}
