/** Languages, pairs and categories (docs/SPEC-v2.md sections 1-2). */

export const LANGS = {
  en: { code: 'en', native: 'English', english: 'English', flag: '🇬🇧' },
  de: { code: 'de', native: 'Deutsch', english: 'German', flag: '🇩🇪' },
  uz: { code: 'uz', native: "O'zbekcha", english: 'Uzbek', flag: '🇺🇿' },
  ru: { code: 'ru', native: 'Русский', english: 'Russian', flag: '🇷🇺' },
}

/** Languages to learn (a word's `lang`). */
export const TARGETS = ['de', 'en']
/** Translation / interface languages. */
export const SOURCES = ['en', 'uz', 'ru']

/** Sources a word of `target` can be translated into. */
export function sourcesFor(target) {
  return SOURCES.filter(s => s !== target)
}

export const ARTICLES = { de: ['der', 'die', 'das'] }
export function hasArticles(target) {
  return (ARTICLES[target] ?? []).length > 0
}

export const CATEGORIES = [
  'Daily Life', 'Work', 'Food', 'Common Verbs', 'Travel', 'Emotions',
  'Adjectives', 'Time', 'Money', 'Health', 'Weather', 'Social', 'Home',
  'Family', 'Education', 'Shopping', 'Nature',
]

export const DIFFICULTIES = ['beginner', 'intermediate', 'advanced']

/** CEFR level (v2.1). The server derives `difficulty` from it. */
export const LEVELS = ['A1', 'A2', 'B1', 'B2', 'C1']
export const LEVEL_DIFFICULTY = { A1: 'beginner', A2: 'beginner', B1: 'intermediate', B2: 'advanced', C1: 'advanced' }

/** Job areas (v2.1). Words with a topic are only sent to app >= 2.1 and
 *  only planned for users who picked that area; no topic = general word. */
export const TOPICS = {
  retail: '🛒 Retail', it: '💻 IT', medicine: '🩺 Medicine', hospitality: '🏨 Hospitality',
  construction: '🏗️ Construction', logistics: '🚚 Logistics', office: '💼 Office', care: '🤝 Care',
}

export function langLabel(code) {
  const l = LANGS[code]
  return l ? `${l.flag} ${l.english}` : code
}

/** "uz-de" -> "🇺🇿 UZ → 🇩🇪 DE" */
export function pairLabel(pair) {
  if (!pair) return '—'
  const [s, t] = String(pair).split('-')
  const f = c => `${LANGS[c]?.flag ?? ''} ${String(c).toUpperCase()}`.trim()
  return t ? `${f(s)} → ${f(t)}` : pair
}

/** The term as shown, with its article when it has one. */
export function wordTitle(w) {
  if (!w) return ''
  const term = w.term ?? w.german ?? ''
  return w.article ? `${w.article} ${term}` : term
}

export const TARGET_KEY = 'osg_admin_words_target'
export function readStoredTarget() {
  try {
    const v = localStorage.getItem(TARGET_KEY)
    return TARGETS.includes(v) ? v : 'de'
  } catch {
    return 'de'
  }
}
export function storeTarget(v) {
  try { localStorage.setItem(TARGET_KEY, v) } catch { /* not remembered */ }
}
