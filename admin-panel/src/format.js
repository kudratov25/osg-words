/** Backend timestamps are UTC but may lack a zone suffix - treat those as UTC. */
export function parseUtc(value) {
  if (!value) return null
  if (value instanceof Date) return value
  const s = String(value)
  const hasZone = /[zZ]|[+-]\d\d:?\d\d$/.test(s)
  const d = new Date(hasZone ? s : s.replace(' ', 'T') + 'Z')
  return Number.isNaN(d.getTime()) ? null : d
}

const dateTimeFmt = new Intl.DateTimeFormat(undefined, {
  year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit',
})
const dateFmt = new Intl.DateTimeFormat(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
const numberFmt = new Intl.NumberFormat()

export function formatDateTime(value) {
  const d = parseUtc(value)
  return d ? dateTimeFmt.format(d) : '—'
}

export function formatDate(value) {
  const d = parseUtc(value)
  return d ? dateFmt.format(d) : '—'
}

export function formatNumber(n) {
  return n == null ? '—' : numberFmt.format(n)
}

/** "YYYY-MM-DD" (a UTC day) -> "Nov 4" */
export function formatDayLabel(day, withYear = false) {
  const [y, m, d] = day.split('-').map(Number)
  const date = new Date(Date.UTC(y, m - 1, d))
  return date.toLocaleDateString(undefined, {
    month: 'short', day: 'numeric', ...(withYear ? { year: 'numeric' } : {}), timeZone: 'UTC',
  })
}

export function relativeTime(value, now = Date.now()) {
  const d = parseUtc(value)
  if (!d) return '—'
  const sec = Math.round((now - d.getTime()) / 1000)
  if (sec < 45) return 'just now'
  const min = Math.round(sec / 60)
  if (min < 60) return `${min} min ago`
  const hr = Math.round(min / 60)
  if (hr < 24) return `${hr} h ago`
  const day = Math.round(hr / 24)
  if (day < 30) return day === 1 ? 'yesterday' : `${day} days ago`
  return formatDate(d)
}

export function shortId(id) {
  return id ? String(id).slice(0, 8) : '—'
}

/**
 * "der" + "Schlüssel" -> "der_schluessel" (matches the existing word ids).
 * English targets get an "en." prefix: "apple" -> "en.apple".
 */
export function suggestExternalId(article, term, target = 'de') {
  const raw = [article, term].filter(Boolean).join(' ')
  const slug = raw
    .toLowerCase()
    .replace(/ä/g, 'ae').replace(/ö/g, 'oe').replace(/ü/g, 'ue').replace(/ß/g, 'ss')
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
  if (!slug) return ''
  return target === 'de' ? slug : `${target}.${slug}`
}

/** "android TP1A.220624.014" -> { platform: "Android", detail: "TP1A.220624.014" } */
export function splitOs(os) {
  if (!os) return { platform: 'Unknown', detail: '' }
  const [first, ...rest] = String(os).trim().split(/\s+/)
  const names = { android: 'Android', ios: 'iOS', macos: 'macOS', windows: 'Windows', linux: 'Linux' }
  return { platform: names[first.toLowerCase()] ?? first, detail: rest.join(' ') }
}
