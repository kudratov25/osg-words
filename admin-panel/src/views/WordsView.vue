<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../api'
import { formatNumber } from '../format'
import {
  CATEGORIES, LANGS, TARGETS, readStoredTarget, sourcesFor, storeTarget, wordTitle,
  LEVELS, LEVEL_DIFFICULTY, TOPICS,
} from '../languages'
import Modal from '../components/Modal.vue'
import WordForm from '../components/WordForm.vue'
import Pagination from '../components/Pagination.vue'

const route = useRoute()
const router = useRouter()

const target = ref(TARGETS.includes(route.query.target) ? route.query.target : readStoredTarget())
const words = ref([])
const loading = ref(true)
const error = ref('')
const q = ref('')
const category = ref('')
const difficulty = ref('') // CEFR level filter
const topic = ref('') // '' all | 'general' | a topic key
const missing = ref('') // '' | source code: only words without that translation

// "Show translations in": remembered; must be a source of the current target.
const SHOW_KEY = 'osg_admin_words_show'
function readShow() {
  try { return localStorage.getItem(SHOW_KEY) || '' } catch { return '' }
}
const sources = computed(() => sourcesFor(target.value))
const showPref = ref(readShow())
const show = computed({
  get: () => (sources.value.includes(showPref.value) ? showPref.value : target.value === 'en' ? 'uz' : 'en'),
  set: v => {
    showPref.value = v
    try { localStorage.setItem(SHOW_KEY, v) } catch { /* not remembered */ }
  },
})

const PAGE_SIZE_KEY = 'osg_admin_words_page_size'
function readPageSize() {
  try { const n = Number(localStorage.getItem(PAGE_SIZE_KEY)); return [25, 50, 100].includes(n) ? n : 25 } catch { return 25 }
}
const page = ref(1)
const pageSize = ref(readPageSize())
const scroller = ref(null)

const editing = ref(null) // null = closed, {} = add, word = edit
const deleting = ref(null)
const deleteBusy = ref(false)
const deleteError = ref('')
const notice = ref('')
let requestId = 0

async function load() {
  const id = ++requestId
  loading.value = true
  error.value = ''
  try {
    const data = await api.words(target.value)
    if (id !== requestId) return
    words.value = data
    openFromQuery()
  } catch (e) {
    if (id === requestId && e.status !== 401) error.value = e.message
  } finally {
    if (id === requestId) loading.value = false
  }
}
onMounted(load)

/** /words?target=de&edit=<external_id> (from the Reports page) opens that word. */
async function openFromQuery() {
  const ext = route.query.edit
  if (!ext) return
  router.replace({ query: {} })
  const w = words.value.find(x => x.external_id === ext)
  if (w) { editing.value = w; return }
  try {
    editing.value = await api.word(ext)
  } catch (e) {
    if (e.status === 404) flash(`Word “${ext}” no longer exists.`)
  }
}

watch(target, t => {
  storeTarget(t)
  words.value = []
  missing.value = ''
  page.value = 1
  load()
})

const categories = computed(() => {
  const extra = words.value.map(w => w.category).filter(c => c && !CATEGORIES.includes(c))
  return [...CATEGORIES, ...new Set(extra)]
})

function translationOf(w, s) {
  return w.translations?.[s]?.translation ?? ''
}

const filtered = computed(() => {
  const term = q.value.trim().toLowerCase()
  return words.value.filter(w => {
    if (category.value && w.category !== category.value) return false
    if (difficulty.value && (w.level ?? '') !== difficulty.value) return false
    if (topic.value === 'general' && w.topics?.length) return false
    if (topic.value && topic.value !== 'general' && !w.topics?.includes(topic.value)) return false
    if (missing.value && w.translations?.[missing.value]) return false
    if (!term) return true
    const hay = [w.term, wordTitle(w), w.external_id, ...Object.values(w.translations ?? {}).map(t => t.translation)]
    return hay.some(v => v && v.toLowerCase().includes(term))
  })
})

const pages = computed(() => Math.max(1, Math.ceil(filtered.value.length / pageSize.value)))
const pageRows = computed(() => filtered.value.slice((page.value - 1) * pageSize.value, page.value * pageSize.value))

// New search/filter -> back to page 1; fewer rows (e.g. after delete) -> clamp.
watch([q, category, difficulty, topic, missing], () => { page.value = 1 })
watch(pages, n => { if (page.value > n) page.value = n })
watch(pageSize, size => {
  try { localStorage.setItem(PAGE_SIZE_KEY, String(size)) } catch { /* not remembered */ }
})
watch([page, pageSize], () => { if (scroller.value) scroller.value.scrollTop = 0 })

function flash(msg) {
  notice.value = msg
  setTimeout(() => { if (notice.value === msg) notice.value = '' }, 3500)
}

function onSaved(saved) {
  const i = words.value.findIndex(w => w.external_id === saved.external_id)
  if (i >= 0) {
    words.value.splice(i, 1, saved)
    flash(`Saved “${wordTitle(saved)}”.`)
  } else if (saved.lang === target.value) {
    words.value.push(saved)
    flash(`Added “${wordTitle(saved)}”.`)
  } else {
    flash(`Saved “${wordTitle(saved)}” (${LANGS[saved.lang]?.english ?? saved.lang}).`)
  }
  editing.value = null
}

async function confirmDelete() {
  deleteBusy.value = true
  deleteError.value = ''
  const w = deleting.value
  try {
    await api.deleteWord(w.external_id)
    words.value = words.value.filter(x => x.external_id !== w.external_id)
    flash(`Deleted “${wordTitle(w)}”.`)
    deleting.value = null
  } catch (e) {
    if (e.status === 404) {
      words.value = words.value.filter(x => x.external_id !== w.external_id)
      deleting.value = null
    } else if (e.status !== 401) {
      deleteError.value = e.message
    }
  } finally {
    deleteBusy.value = false
  }
}

function openDelete(w) {
  deleteError.value = ''
  deleting.value = w
}

const coverageNote = computed(() => {
  if (!words.value.length) return ''
  return sources.value
    .map(s => `${s.toUpperCase()} ${formatNumber(words.value.filter(w => w.translations?.[s]).length)}`)
    .join(' · ')
})
</script>

<template>
  <div class="page-fill">
    <div class="page-head">
      <div>
        <h1>Words</h1>
        <p>
          {{ formatNumber(words.length) }} {{ LANGS[target].english }} words<span v-if="coverageNote"> · translated: {{ coverageNote }}</span>.
          Phones pick up changes within 30 minutes, or right away with pull-to-refresh.
        </p>
      </div>
      <div class="head-actions">
        <div class="seg" role="radiogroup" aria-label="Language to learn">
          <button
            v-for="t in TARGETS"
            :key="t"
            class="seg-btn"
            :class="{ on: target === t }"
            role="radio"
            :aria-checked="target === t"
            @click="target = t"
          >
            <span aria-hidden="true">{{ LANGS[t].flag }}</span> {{ LANGS[t].native }}
          </button>
        </div>
        <button class="btn btn-primary" @click="editing = {}">+ Add word</button>
      </div>
    </div>

    <div v-if="notice" class="alert alert-info notice" role="status">{{ notice }}</div>

    <section class="glass table-card">
      <div class="toolbar table-toolbar">
        <input v-model="q" class="input" type="search" placeholder="Search word, any translation or ID…" aria-label="Search words" />
        <select v-model="show" class="input show" aria-label="Show translations in">
          <option v-for="s in sources" :key="s" :value="s">Show {{ LANGS[s].flag }} {{ LANGS[s].english }}</option>
        </select>
        <select v-model="category" class="input" aria-label="Filter by category">
          <option value="">All categories</option>
          <option v-for="c in categories" :key="c" :value="c">{{ c }}</option>
        </select>
        <select v-model="difficulty" class="input" aria-label="Filter by difficulty">
          <option value="">All levels</option>
          <option v-for="lv in LEVELS" :key="lv" :value="lv">{{ lv }}</option>
        </select>
        <select v-model="topic" class="input" aria-label="Filter by work area">
          <option value="">All words</option>
          <option value="general">General only</option>
          <option v-for="(label, key) in TOPICS" :key="key" :value="key">{{ label }}</option>
        </select>
        <select v-model="missing" class="input" aria-label="Filter by missing translation">
          <option value="">Any coverage</option>
          <option v-for="s in sources" :key="s" :value="s">Missing {{ s.toUpperCase() }}</option>
        </select>
      </div>

      <div v-if="error" class="table-state">
        <div class="alert alert-error" role="alert">
          Couldn't load words: {{ error }} <button class="btn btn-sm" style="margin-left:8px" @click="load">Retry</button>
        </div>
      </div>
      <div v-else-if="loading" class="table-state state"><span class="spinner" /></div>
      <div v-else-if="words.length === 0" class="table-state state">
        <strong>No {{ LANGS[target].english }} words yet</strong>
        Add one with “Add word”, or bring in a content file on the Import page.
      </div>
      <div v-else-if="filtered.length === 0" class="table-state state">
        <strong>No matches</strong>
        Try another search or clear the filters.
      </div>

      <template v-else>
        <div ref="scroller" class="table-scroll">
          <table class="table">
            <thead>
              <tr>
                <th>{{ LANGS[target].english }}</th>
                <th>Translation · {{ show.toUpperCase() }}</th>
                <th>Example</th>
                <th>Category</th>
                <th>Level</th>
                <th>Translated</th>
                <th class="right"><span class="sr-only">Actions</span></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="w in pageRows" :key="w.external_id">
                <td class="nowrap">
                  <strong>{{ wordTitle(w) }}</strong>
                  <div class="faint mono" style="font-size:12px">{{ w.external_id }}</div>
                </td>
                <td :title="w.translations?.[show]?.example_translation || undefined">
                  <template v-if="translationOf(w, show)">{{ translationOf(w, show) }}</template>
                  <span v-else class="faint small">— missing</span>
                </td>
                <td class="example muted">{{ w.example }}</td>
                <td class="nowrap">{{ w.category }}</td>
                <td class="nowrap">
                  <span class="badge" :class="`badge-${LEVEL_DIFFICULTY[w.level] ?? w.difficulty}`">{{ w.level ?? w.difficulty }}</span>
                  <span v-for="t in w.topics ?? []" :key="t" class="topic-tag" :title="TOPICS[t]">{{ TOPICS[t]?.split(' ')[0] }}</span>
                </td>
                <td class="nowrap">
                  <span
                    v-for="s in sources"
                    :key="s"
                    class="cov"
                    :class="{ has: w.translations?.[s] }"
                    :title="w.translations?.[s] ? `${LANGS[s].english}: ${w.translations[s].translation}` : `No ${LANGS[s].english} translation`"
                  >{{ s.toUpperCase() }}</span>
                </td>
                <td class="right nowrap">
                  <button class="btn btn-sm" @click="editing = w">Edit</button>
                  <button class="btn btn-sm btn-danger" style="margin-left:6px" @click="openDelete(w)">Delete</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="table-footer">
          <Pagination v-model:page="page" v-model:page-size="pageSize" :total="filtered.length" />
        </div>
      </template>
    </section>

    <Modal v-if="editing" :title="editing.external_id ? `Edit “${wordTitle(editing)}”` : `Add ${LANGS[target].english} word`" @close="editing = null">
      <WordForm :word="editing.external_id ? editing : null" :target="target" @saved="onSaved" @cancel="editing = null" />
    </Modal>

    <Modal v-if="deleting" title="Delete word?" width="440px" @close="deleting = null">
      <p style="margin-top:0">
        Delete <strong>{{ wordTitle(deleting) }}</strong><template v-if="translationOf(deleting, show)"> ({{ translationOf(deleting, show) }})</template>?
      </p>
      <p class="muted small">It disappears from every {{ LANGS[deleting.lang]?.english }} pack. Phones that already have it keep it (their progress is never deleted), but new installs won’t get it.</p>
      <div v-if="deleteError" class="alert alert-error" role="alert" style="margin-bottom:12px">{{ deleteError }}</div>
      <div style="display:flex;justify-content:flex-end;gap:10px">
        <button class="btn" @click="deleting = null">Cancel</button>
        <button class="btn btn-danger" :disabled="deleteBusy" @click="confirmDelete">
          <span v-if="deleteBusy" class="spinner" style="width:14px;height:14px" /> Delete
        </button>
      </div>
    </Modal>
  </div>
</template>

<style scoped>
.example { min-width: 170px; max-width: 320px; }
.notice { margin-bottom: 16px; }
.head-actions { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
.toolbar .input { flex-basis: 220px; }
.toolbar select.input { flex-basis: 150px; }
.toolbar select.input.show { flex-basis: 170px; }
.cov {
  display: inline-block;
  margin-right: 4px;
  padding: 1px 6px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.03em;
  border: 1px dashed var(--glass-border-soft);
  color: var(--text-3);
  opacity: 0.55;
}
.topic-tag { margin-left: 4px; font-size: 14px; }
.cov.has { opacity: 1; border-style: solid; border-color: var(--badge-beginner-border); color: var(--badge-beginner); }
@media (max-width: 520px) {
  .toolbar .input { flex-basis: 100%; }
  .toolbar select.input { flex-basis: calc(50% - 5px); }
  .toolbar select.input.show, .toolbar select.input:last-child { flex-basis: 100%; }
  .head-actions { width: 100%; }
  .head-actions .seg { flex: 1 1 100%; }
  .head-actions .btn { flex: 1 1 100%; }
}
</style>
