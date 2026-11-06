import { session, logout, setSession } from './auth'

export class ApiError extends Error {
  constructor(status, detail) {
    super(ApiError.describe(status, detail))
    this.status = status
    this.detail = detail
    /** field name -> message, from FastAPI 422 responses */
    this.fieldErrors = {}
    /** dotted path below "body" -> message, e.g. "translations.uz.translation" */
    this.pathErrors = {}
    if (Array.isArray(detail)) {
      for (const item of detail) {
        const loc = Array.isArray(item?.loc) ? item.loc : []
        const field = loc.length ? loc[loc.length - 1] : null
        if (field && !this.fieldErrors[field]) this.fieldErrors[field] = item.msg
        const path = loc.filter((p, i) => !(i === 0 && p === 'body')).join('.')
        if (path && !this.pathErrors[path]) this.pathErrors[path] = item.msg
      }
    }
  }

  static describe(status, detail) {
    if (typeof detail === 'string' && detail) return detail
    if (Array.isArray(detail)) {
      return detail.map(d => {
        const field = Array.isArray(d?.loc) ? d.loc[d.loc.length - 1] : ''
        return field ? `${field}: ${d.msg}` : d?.msg
      }).filter(Boolean).join('; ') || 'Invalid input'
    }
    if (status === 0) return 'Network error — check your connection.'
    return `Request failed (${status})`
  }
}

let onUnauthorized = null
export function setUnauthorizedHandler(fn) {
  onUnauthorized = fn
}

async function request(path, { method = 'GET', body, auth = true } = {}) {
  const headers = { Accept: 'application/json' }
  if (body !== undefined) headers['Content-Type'] = 'application/json'
  if (auth && session.data?.token) headers.Authorization = `Bearer ${session.data.token}`

  let res
  try {
    res = await fetch(path, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    })
  } catch {
    throw new ApiError(0, null)
  }

  if (res.status === 401 && auth) {
    logout()
    onUnauthorized?.()
    throw new ApiError(401, 'Your session has expired. Please sign in again.')
  }

  if (res.status === 204) return null
  const text = await res.text()
  let data = null
  if (text) {
    try {
      data = JSON.parse(text)
    } catch {
      data = text
    }
  }
  if (!res.ok) throw new ApiError(res.status, data?.detail ?? (typeof data === 'string' ? data : null))
  return data
}

function qs(params) {
  const p = new URLSearchParams()
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== null && v !== '') p.set(k, v)
  }
  const s = p.toString()
  return s ? `?${s}` : ''
}

export const api = {
  async login(username, password) {
    const data = await request('/admin/login', {
      method: 'POST',
      body: { username, password },
      auth: false,
    })
    setSession({ token: data.token, expires_at: data.expires_at, username: data.username ?? username })
    return data
  },
  async changePassword(currentPassword, newPassword) {
    const data = await request('/admin/password', {
      method: 'POST',
      body: { current_password: currentPassword, new_password: newPassword },
    })
    // Every older session is now invalid; keep this tab signed in with the fresh token.
    setSession({ token: data.token, expires_at: data.expires_at, username: data.username })
    return data
  },
  me: () => request('/admin/me'),
  stats: () => request('/admin/stats'),
  devices: ({ limit = 50, offset = 0, q = '' } = {}) => request(`/admin/devices${qs({ limit, offset, q })}`),
  words: (target = '') => request(`/admin/words${qs({ target })}`),
  word: externalId => request(`/admin/words/${encodeURIComponent(externalId)}`),
  createWord: word => request('/admin/words', { method: 'POST', body: word }),
  updateWord: (externalId, changes) =>
    request(`/admin/words/${encodeURIComponent(externalId)}`, { method: 'PATCH', body: changes }),
  deleteWord: externalId =>
    request(`/admin/words/${encodeURIComponent(externalId)}`, { method: 'DELETE' }),
  importWords: (payload, dryRun = true) =>
    request(`/admin/import${qs({ dry_run: dryRun ? 'true' : 'false' })}`, { method: 'POST', body: payload }),
  coverage: () => request('/admin/coverage'),
  wordIssues: (status = '', limit = 1000) => request(`/admin/word-issues${qs({ status, limit })}`),
  updateWordIssue: (id, status) => request(`/admin/word-issues/${id}`, { method: 'PATCH', body: { status } }),
}
