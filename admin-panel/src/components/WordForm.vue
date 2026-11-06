<script setup>
import { computed, reactive, ref, watch } from 'vue'
import { api } from '../api'
import { suggestExternalId } from '../format'
import { ARTICLES, CATEGORIES, LANGS, hasArticles, sourcesFor, LEVELS, TOPICS } from '../languages'

/**
 * Add (word = null) or edit (word = existing AdminWord) a word.
 * Target-side fields first, then one tab per source language. An empty tab
 * means "no translation in that language" (removed on save when editing).
 */
const props = defineProps({
  word: { type: Object, default: null },
  /** target language for a new word; an existing word keeps its own `lang` */
  target: { type: String, default: 'de' },
})
const emit = defineEmits(['saved', 'cancel'])

const editing = computed(() => !!props.word)
const lang = computed(() => props.word?.lang ?? props.target)
const sources = computed(() => sourcesFor(lang.value))
const articles = computed(() => ARTICLES[lang.value] ?? [])
const withArticles = computed(() => hasArticles(lang.value))
const TARGET_FIELDS = ['term', 'article', 'example', 'pronunciation', 'category', 'level']

const form = reactive({
  external_id: props.word?.external_id ?? '',
  term: props.word?.term ?? '',
  article: props.word?.article ?? '',
  example: props.word?.example ?? '',
  pronunciation: props.word?.pronunciation ?? '',
  category: props.word?.category ?? '',
  level: props.word?.level ?? 'A1',
})
/** Job areas; empty = general word (served to every app version). */
const topics = ref([...(props.word?.topics ?? [])])
const sameTopics = (a, b) => [...a].sort().join(',') === [...b].sort().join(',')
const tr = reactive(Object.fromEntries(sources.value.map(s => [s, {
  translation: props.word?.translations?.[s]?.translation ?? '',
  example_translation: props.word?.translations?.[s]?.example_translation ?? '',
}])))
const tab = ref(sources.value[0])

/** keys: field names, or "tr.<lang>.translation" / "tr.<lang>.example_translation" */
const errors = reactive({})
const formError = ref('')
const saving = ref(false)

// A category not in the fixed list (old data) stays selectable.
const categoryOptions = computed(() =>
  form.category && !CATEGORIES.includes(form.category) ? [form.category, ...CATEGORIES] : CATEGORIES,
)

// Auto-suggest the id while adding, until the user edits it themselves.
const idTouched = ref(false)
watch(() => [form.article, form.term], () => {
  if (!editing.value && !idTouched.value) form.external_id = suggestExternalId(form.article, form.term, lang.value)
})

function clean(v) {
  const t = typeof v === 'string' ? v.trim() : v
  return t === '' || t === undefined ? null : t
}

function filled(s) {
  return !!clean(tr[s].translation)
}
function tabHasError(s) {
  return Object.keys(errors).some(k => k.startsWith(`tr.${s}.`))
}

function clearErrors() {
  for (const k of Object.keys(errors)) delete errors[k]
  formError.value = ''
}

function focusFirstErrorTab() {
  const s = sources.value.find(tabHasError)
  if (s) tab.value = s
}

function validate() {
  clearErrors()
  const required = { term: 'Word', example: 'Example sentence', category: 'Category' }
  if (!editing.value) required.external_id = 'ID'
  for (const [k, label] of Object.entries(required)) {
    if (!clean(form[k])) errors[k] = `${label} is required`
  }
  if (!editing.value && form.external_id) {
    const id = form.external_id.trim()
    if (!/^[a-z0-9_.]+$/.test(id)) errors.external_id = 'Use lowercase letters, digits, _ and . only'
    else if (lang.value !== 'de' && !id.startsWith(`${lang.value}.`)) errors.external_id = `IDs of ${LANGS[lang.value].english} words start with “${lang.value}.”`
  }
  for (const s of sources.value) {
    if (!filled(s) && clean(tr[s].example_translation)) {
      errors[`tr.${s}.translation`] = 'Add the translation, or clear the example translation'
    }
  }
  if (!sources.value.some(filled)) {
    formError.value = 'Add at least one translation — a word without translations appears in no pack.'
  }
  focusFirstErrorTab()
  return Object.keys(errors).length === 0 && !formError.value
}

function trBody(s) {
  return { translation: clean(tr[s].translation), example_translation: clean(tr[s].example_translation) }
}

function buildCreate() {
  const body = { lang: lang.value, external_id: form.external_id.trim(), translations: {} }
  for (const k of TARGET_FIELDS) {
    const v = clean(form[k])
    if (v !== null) body[k] = v
  }
  for (const s of sources.value) if (filled(s)) body.translations[s] = trBody(s)
  if (topics.value.length) body.topics = [...topics.value]
  return body
}

function buildPatch() {
  const changes = {}
  for (const k of TARGET_FIELDS) {
    const next = clean(form[k])
    const prev = props.word[k] ?? null
    if (next !== prev) changes[k] = next
  }
  if (!sameTopics(topics.value, props.word.topics ?? [])) changes.topics = [...topics.value]
  const translations = {}
  for (const s of sources.value) {
    const prev = props.word.translations?.[s] ?? null
    if (!filled(s)) {
      if (prev) translations[s] = null // remove this language
      continue
    }
    const next = trBody(s)
    if (!prev || prev.translation !== next.translation || (prev.example_translation ?? null) !== next.example_translation) {
      translations[s] = next
    }
  }
  if (Object.keys(translations).length) changes.translations = translations
  return changes
}

/** Server errors -> the field they belong to. */
function applyServerError(e) {
  if (e.status === 409) {
    errors.external_id = e.message || 'This ID already exists'
    return
  }
  if (e.status === 422) {
    let placed = false
    for (const [path, msg] of Object.entries(e.pathErrors ?? {})) {
      const m = path.match(/^translations\.(\w+)\.(translation|example_translation)$/)
      if (m) { errors[`tr.${m[1]}.${m[2]}`] = msg; placed = true }
      else if (m === null && /^translations\.(\w+)$/.test(path)) { errors[`tr.${path.split('.')[1]}.translation`] = msg; placed = true }
      else if (path in form) { errors[path] = msg; placed = true }
    }
    if (typeof e.detail === 'string') {
      const d = e.detail
      const m = d.match(/translations\.(\w+)\.(translation|example_translation)/)
      if (m) { errors[`tr.${m[1]}.${m[2]}`] = d; placed = true }
      else if (/\barticle\b|has no articles/.test(d)) { errors.article = d; placed = true }
      else if (/category/.test(d)) { errors.category = d; placed = true }
      else {
        const f = d.match(/^(term|example|difficulty|level) /)
        if (f) { errors[f[1]] = d; placed = true }
      }
    }
    if (placed) { focusFirstErrorTab(); return }
  }
  if (e.status === 404) formError.value = 'This word no longer exists. Close and refresh the list.'
  else if (e.status !== 401) formError.value = e.message
}

async function submit() {
  if (!validate()) return
  saving.value = true
  try {
    let saved
    if (editing.value) {
      const changes = buildPatch()
      saved = Object.keys(changes).length ? await api.updateWord(props.word.external_id, changes) : props.word
    } else {
      saved = await api.createWord(buildCreate())
    }
    emit('saved', saved)
  } catch (e) {
    applyServerError(e)
  } finally {
    saving.value = false
  }
}

const placeholders = {
  de: { term: 'Fenster', id: 'das_fenster', example: 'Kannst du bitte das Fenster öffnen?' },
  en: { term: 'window', id: 'en.window', example: 'Could you open the window, please?' },
}
const ph = computed(() => placeholders[lang.value] ?? placeholders.en)
const trPh = {
  en: { translation: 'window', example: 'Could you open the window, please?' },
  uz: { translation: 'deraza', example: 'Iltimos, derazani ocha olasizmi?' },
  ru: { translation: 'окно', example: 'Можешь, пожалуйста, открыть окно?' },
}
</script>

<template>
  <form class="form" novalidate @submit.prevent="submit">
    <div v-if="formError" class="alert alert-error" role="alert">{{ formError }}</div>

    <div class="lang-line small muted">
      <span class="badge">{{ LANGS[lang]?.flag }} {{ LANGS[lang]?.native ?? lang }}</span>
      word · translations below
    </div>

    <div class="row two">
      <div v-if="withArticles" class="field" style="flex:0 0 110px">
        <label for="wf-article">Article</label>
        <select id="wf-article" v-model="form.article" class="input" :class="{ invalid: errors.article }">
          <option value="">none</option>
          <option v-for="a in articles" :key="a" :value="a">{{ a }}</option>
        </select>
        <span v-if="errors.article" class="error">{{ errors.article }}</span>
      </div>
      <div class="field" style="flex:1">
        <label for="wf-term">Word *</label>
        <input id="wf-term" v-model="form.term" class="input" :class="{ invalid: errors.term }" maxlength="200" :placeholder="ph.term" />
        <span v-if="errors.term" class="error">{{ errors.term }}</span>
      </div>
    </div>
    <span v-if="!withArticles && errors.article" class="error small">{{ errors.article }}</span>

    <div class="field">
      <label for="wf-id">ID *</label>
      <input
        id="wf-id"
        v-model="form.external_id"
        class="input mono"
        :class="{ invalid: errors.external_id }"
        :readonly="editing"
        maxlength="64"
        :placeholder="ph.id"
        @input="idTouched = true"
      />
      <span v-if="errors.external_id" class="error">{{ errors.external_id }}</span>
      <span v-else class="hint">{{ editing ? 'Permanent, can’t be changed.' : 'Permanent key, suggested from the word. Never reuse an old one.' }}</span>
    </div>

    <div class="field">
      <label for="wf-example">Example sentence *</label>
      <textarea id="wf-example" v-model="form.example" class="input" :class="{ invalid: errors.example }" maxlength="500" rows="2" :placeholder="ph.example" />
      <span v-if="errors.example" class="error">{{ errors.example }}</span>
    </div>

    <div class="row two">
      <div class="field" style="flex:1">
        <label for="wf-category">Category *</label>
        <select id="wf-category" v-model="form.category" class="input" :class="{ invalid: errors.category }">
          <option value="" disabled>Choose…</option>
          <option v-for="c in categoryOptions" :key="c" :value="c">{{ c }}</option>
        </select>
        <span v-if="errors.category" class="error">{{ errors.category }}</span>
      </div>
      <div class="field" style="flex:0 0 170px">
        <label for="wf-level">Level (CEFR)</label>
        <select id="wf-level" v-model="form.level" class="input" :class="{ invalid: errors.level }">
          <option v-for="lv in LEVELS" :key="lv" :value="lv">{{ lv }}</option>
        </select>
        <span v-if="errors.level" class="error">{{ errors.level }}</span>
      </div>
    </div>

    <fieldset class="field topics">
      <legend>Work areas <span class="faint">(none = general word for everyone)</span></legend>
      <label v-for="(label, key) in TOPICS" :key="key" class="topic">
        <input v-model="topics" type="checkbox" :value="key" /> {{ label }}
      </label>
    </fieldset>

    <div class="field">
      <label for="wf-pron">Pronunciation <span class="faint">(optional)</span></label>
      <input id="wf-pron" v-model="form.pronunciation" class="input" maxlength="200" placeholder="FEN-ster" />
      <span v-if="errors.pronunciation" class="error">{{ errors.pronunciation }}</span>
    </div>

    <section class="tr-box">
      <div class="tabs" role="tablist" aria-label="Translations">
        <button
          v-for="s in sources"
          :id="`wf-tab-${s}`"
          :key="s"
          type="button"
          role="tab"
          class="tab"
          :class="{ on: tab === s, err: tabHasError(s) }"
          :aria-selected="tab === s"
          :aria-controls="`wf-panel-${s}`"
          @click="tab = s"
        >
          <span aria-hidden="true">{{ LANGS[s].flag }}</span>
          {{ s.toUpperCase() }}
          <span class="dot" :class="{ full: filled(s) }" :title="filled(s) ? 'Has a translation' : 'No translation'" />
        </button>
      </div>
      <div
        v-for="s in sources"
        v-show="tab === s"
        :id="`wf-panel-${s}`"
        :key="s"
        class="tr-panel"
        role="tabpanel"
        :aria-labelledby="`wf-tab-${s}`"
      >
        <div class="field">
          <label :for="`wf-tr-${s}`">Translation ({{ LANGS[s].english }})</label>
          <input :id="`wf-tr-${s}`" v-model="tr[s].translation" class="input" :class="{ invalid: errors[`tr.${s}.translation`] }" maxlength="200" :placeholder="trPh[s]?.translation" />
          <span v-if="errors[`tr.${s}.translation`]" class="error">{{ errors[`tr.${s}.translation`] }}</span>
          <span v-else class="hint">
            {{ filled(s) ? 'Short: 1–3 words, “/” between alternatives.'
              : editing && word?.translations?.[s] ? `Empty: the ${LANGS[s].english} translation is removed on save.`
              : `Empty: no ${LANGS[s].english} translation — the word isn’t in the ${s}-${lang} pack.` }}
          </span>
        </div>
        <div class="field">
          <label :for="`wf-trex-${s}`">Example translation <span class="faint">(optional)</span></label>
          <textarea :id="`wf-trex-${s}`" v-model="tr[s].example_translation" class="input" :class="{ invalid: errors[`tr.${s}.example_translation`] }" maxlength="500" rows="2" :placeholder="trPh[s]?.example" />
          <span v-if="errors[`tr.${s}.example_translation`]" class="error">{{ errors[`tr.${s}.example_translation`] }}</span>
        </div>
      </div>
    </section>

    <p class="faint small" style="margin:0">Phones get changes within 30 minutes (next app open), or right away with pull-to-refresh.</p>

    <div class="actions">
      <button type="button" class="btn" @click="emit('cancel')">Cancel</button>
      <button type="submit" class="btn btn-primary" :disabled="saving">
        <span v-if="saving" class="spinner" style="width:14px;height:14px" />
        {{ editing ? 'Save changes' : 'Add word' }}
      </button>
    </div>
  </form>
</template>

<style scoped>
.topics { border: 0; padding: 0; margin: 0; display: flex; flex-wrap: wrap; gap: 8px 16px; }
.topics legend { margin-bottom: 6px; font-size: 13px; }
.topic { display: inline-flex; align-items: center; gap: 6px; font-size: 14px; cursor: pointer; }
.form { display: flex; flex-direction: column; gap: 14px; }
.row.two { display: flex; gap: 12px; }
.actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 4px; }
.lang-line { display: flex; align-items: center; gap: 8px; }

.tr-box { border: 1px solid var(--glass-border-soft); border-radius: var(--radius-sm); overflow: hidden; }
.tabs { display: flex; border-bottom: 1px solid var(--glass-border-soft); background: var(--input-readonly); }
.tab {
  flex: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: 40px;
  border: 0;
  border-bottom: 2px solid transparent;
  background: transparent;
  color: var(--text-2);
  font: inherit;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
}
.tab:hover { color: var(--text); background: var(--row-hover); }
.tab.on { color: var(--accent); border-bottom-color: var(--accent); background: var(--accent-tint); }
.tab.err { color: var(--danger); }
.tab.err.on { border-bottom-color: var(--danger); background: var(--danger-fill); }
.dot { width: 7px; height: 7px; border-radius: 50%; border: 1.5px solid var(--text-3); }
.dot.full { background: var(--success); border-color: var(--success); }
.tr-panel { padding: 14px; display: flex; flex-direction: column; gap: 12px; }

@media (max-width: 520px) {
  .row.two { flex-direction: column; }
  .row.two .field { flex: 1 1 auto !important; }
}
</style>
