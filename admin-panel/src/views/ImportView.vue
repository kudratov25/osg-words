<script setup>
import { computed, ref } from 'vue'
import { api } from '../api'
import { formatNumber } from '../format'
import { LANGS, TARGETS, pairLabel } from '../languages'
import Modal from '../components/Modal.vue'

const MAX_WORDS = 2000

const text = ref('')
const fileName = ref('')
const chosenTarget = ref('de') // used only when the file names no target
const dragging = ref(false)
const fileInput = ref(null)

const checking = ref(false)
const importing = ref(false)
const confirmOpen = ref(false)
const error = ref('')
const check = ref(null) // { signature, result }
const done = ref(null) // result of the real import

/** Parse the pasted JSON: { target?, words: [...] } or a bare array. */
const parsed = computed(() => {
  const raw = text.value.trim()
  if (!raw) return { empty: true }
  let data
  try {
    data = JSON.parse(raw)
  } catch (e) {
    return { error: `Not valid JSON: ${e.message}` }
  }
  if (Array.isArray(data)) data = { words: data }
  if (!data || typeof data !== 'object' || !Array.isArray(data.words)) {
    return { error: 'Expected {"target": "de", "words": [ … ]} (the content-file shape) or an array of words.' }
  }
  if (data.target != null && !TARGETS.includes(data.target)) {
    return { error: `"target" must be one of ${TARGETS.join(', ')} (got "${data.target}").` }
  }
  if (data.words.length === 0) return { error: 'The file has no words.' }
  if (data.words.length > MAX_WORDS) {
    return { error: `${formatNumber(data.words.length)} words — at most ${formatNumber(MAX_WORDS)} per import. Split the file.` }
  }
  return { data, fileTarget: data.target ?? null, count: data.words.length }
})

const target = computed(() => parsed.value.fileTarget ?? chosenTarget.value)
const payload = computed(() => (parsed.value.data ? { ...parsed.value.data, target: target.value } : null))
// Identifies exactly what was checked, so Import is only allowed for that.
const signature = computed(() => (payload.value ? `${target.value}\n${text.value.trim()}` : ''))

const checkCurrent = computed(() => check.value && check.value.signature === signature.value)
const checkClean = computed(() => checkCurrent.value && check.value.result.errors.length === 0)
const changes = computed(() => (checkCurrent.value ? check.value.result.created + check.value.result.updated : 0))
const canImport = computed(() => checkClean.value && changes.value > 0 && !importing.value)

async function readFile(file) {
  if (!file) return
  error.value = ''
  done.value = null
  if (file.size > 5 * 1024 * 1024) {
    error.value = 'That file is over 5 MB — too big for one import.'
    return
  }
  try {
    text.value = await file.text()
    fileName.value = file.name
  } catch {
    error.value = 'Couldn’t read that file.'
  }
}
function onFile(e) {
  readFile(e.target.files?.[0])
  e.target.value = ''
}
function onDrop(e) {
  dragging.value = false
  readFile(e.dataTransfer?.files?.[0])
}
function onEdit() {
  fileName.value = ''
  done.value = null
}
function clearAll() {
  text.value = ''
  fileName.value = ''
  check.value = null
  done.value = null
  error.value = ''
}

async function runCheck() {
  if (!payload.value) return
  checking.value = true
  error.value = ''
  done.value = null
  const sig = signature.value
  try {
    const result = await api.importWords(payload.value, true)
    check.value = { signature: sig, result }
  } catch (e) {
    check.value = null
    if (e.status !== 401) error.value = e.message
  } finally {
    checking.value = false
  }
}

async function runImport() {
  if (!canImport.value) return
  importing.value = true
  error.value = ''
  try {
    const result = await api.importWords(payload.value, false)
    done.value = result
    check.value = null
    confirmOpen.value = false
  } catch (e) {
    confirmOpen.value = false
    if (e.status !== 401) error.value = e.message
  } finally {
    importing.value = false
  }
}

const example = `{
  "target": "de",
  "words": [
    {
      "external_id": "der_schluessel",
      "term": "Schlüssel",
      "article": "der",
      "example": "Wo ist mein Schlüssel?",
      "category": "Daily Life",
      "difficulty": "beginner",
      "translations": {
        "en": { "translation": "key", "example_translation": "Where is my key?" },
        "uz": { "translation": "kalit" },
        "ru": { "translation": "ключ" }
      }
    }
  ]
}`
</script>

<template>
  <div>
    <div class="page-head">
      <div>
        <h1>Import</h1>
        <p>Add or update many words at once from a content file. Words are matched by <span class="mono">external_id</span>.</p>
      </div>
    </div>

    <div class="layout">
      <section class="card glass input-card">
        <div class="card-head">
          <h2>1. Content</h2>
          <div class="toolbar">
            <input ref="fileInput" type="file" accept=".json,application/json" class="sr-only" tabindex="-1" @change="onFile" />
            <button class="btn btn-sm" @click="fileInput?.click()">Choose .json file</button>
            <button v-if="text" class="btn btn-sm btn-ghost" @click="clearAll">Clear</button>
          </div>
        </div>

        <textarea
          v-model="text"
          class="input mono json"
          :class="{ drop: dragging, invalid: parsed.error }"
          spellcheck="false"
          aria-label="Content JSON"
          :placeholder="`Paste JSON here or drop a .json file.\n\n${example}`"
          @input="onEdit"
          @dragover.prevent="dragging = true"
          @dragleave="dragging = false"
          @drop.prevent="onDrop"
        />

        <div class="meta small">
          <span v-if="parsed.error" class="error-text">{{ parsed.error }}</span>
          <template v-else-if="parsed.data">
            <span class="badge">{{ formatNumber(parsed.count) }} {{ parsed.count === 1 ? 'word' : 'words' }}</span>
            <span v-if="fileName" class="faint mono">{{ fileName }}</span>
            <span v-if="parsed.fileTarget" class="muted">target {{ LANGS[parsed.fileTarget].flag }} {{ LANGS[parsed.fileTarget].english }}</span>
            <label v-else class="muted target-pick">
              No "target" in the file — import as
              <select v-model="chosenTarget" class="input input-sm">
                <option v-for="t in TARGETS" :key="t" :value="t">{{ LANGS[t].flag }} {{ LANGS[t].english }}</option>
              </select>
            </label>
          </template>
          <span v-else class="faint">Same shape as backend/content/de.json: {"target", "words": [...]}. Up to {{ formatNumber(MAX_WORDS) }} words per import.</span>
        </div>

        <div class="actions">
          <button class="btn btn-primary" :disabled="!payload || checking" @click="runCheck">
            <span v-if="checking" class="spinner" style="width:14px;height:14px" /> Check
          </button>
          <button class="btn" :disabled="!canImport" :title="canImport ? '' : 'Run a clean check of this exact content first'" @click="confirmOpen = true">
            Import
          </button>
          <span class="faint small hint">Check is a dry run — nothing is saved. Import unlocks after a check without errors.</span>
        </div>
      </section>

      <section class="card glass result-card">
        <h2 class="sub">2. Result</h2>

        <div v-if="error" class="alert alert-error" role="alert">{{ error }}</div>

        <template v-if="done">
          <div class="alert alert-success" role="status">
            Imported: {{ formatNumber(done.created) }} created, {{ formatNumber(done.updated) }} updated, {{ formatNumber(done.unchanged) }} unchanged.
            <template v-if="done.bumped.length">Phones get the new packs within 30 minutes (or on pull-to-refresh).</template>
          </div>
          <div v-if="done.bumped.length" class="bumped">
            <span class="faint small">Packs updated:</span>
            <span v-for="p in done.bumped" :key="p" class="badge">{{ pairLabel(p) }}</span>
          </div>
        </template>

        <template v-else-if="check">
          <div v-if="!checkCurrent" class="alert alert-info">The content changed since the last check — check again.</div>
          <div class="counts">
            <div class="count"><div class="n num">{{ formatNumber(check.result.created) }}</div><div class="faint small">new</div></div>
            <div class="count"><div class="n num">{{ formatNumber(check.result.updated) }}</div><div class="faint small">updated</div></div>
            <div class="count"><div class="n num">{{ formatNumber(check.result.unchanged) }}</div><div class="faint small">unchanged</div></div>
            <div class="count" :class="{ bad: check.result.errors.length }"><div class="n num">{{ formatNumber(check.result.errors.length) }}</div><div class="faint small">errors</div></div>
          </div>

          <div class="bumped">
            <span class="faint small">Packs that would be bumped:</span>
            <span v-for="p in check.result.bumped" :key="p" class="badge">{{ pairLabel(p) }}</span>
            <span v-if="!check.result.bumped.length" class="faint small">none</span>
          </div>

          <div v-if="check.result.errors.length" class="errors">
            <div class="alert alert-error">Fix {{ check.result.errors.length === 1 ? 'this item' : `these ${check.result.errors.length} items` }} and check again. Import stays locked until the check is clean.</div>
            <div class="table-wrap err-scroll">
              <table class="table">
                <thead><tr><th class="right">#</th><th>ID</th><th>Problem</th></tr></thead>
                <tbody>
                  <tr v-for="e in check.result.errors" :key="e.index">
                    <td class="right num faint">{{ e.index }}</td>
                    <td class="mono nowrap">{{ e.external_id || '—' }}</td>
                    <td>{{ e.error }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
          <div v-else-if="checkCurrent && changes === 0" class="alert alert-info">Everything is already up to date — nothing to import.</div>
          <div v-else-if="checkCurrent" class="alert alert-success">Check passed. Press Import to apply.</div>
        </template>

        <p v-else-if="!error" class="faint small" style="margin:0">Paste or choose a file, then press Check to see what would change.</p>
      </section>
    </div>

    <Modal v-if="confirmOpen" title="Import words?" width="460px" @close="confirmOpen = false">
      <p style="margin-top:0">
        Apply <strong>{{ formatNumber(check.result.created) }}</strong> new and <strong>{{ formatNumber(check.result.updated) }}</strong> updated
        {{ LANGS[target].english }} words?
      </p>
      <p v-if="check.result.bumped.length" class="muted small">
        Bumps {{ check.result.bumped.join(', ') }} — phones download the changes within 30 minutes (or on pull-to-refresh).
      </p>
      <div style="display:flex;justify-content:flex-end;gap:10px">
        <button class="btn" @click="confirmOpen = false">Cancel</button>
        <button class="btn btn-primary" :disabled="importing" @click="runImport">
          <span v-if="importing" class="spinner" style="width:14px;height:14px" /> Import
        </button>
      </div>
    </Modal>
  </div>
</template>

<style scoped>
.layout { display: grid; grid-template-columns: minmax(0, 1.2fr) minmax(0, 1fr); gap: 16px; align-items: start; }
@media (max-width: 1100px) { .layout { grid-template-columns: minmax(0, 1fr); } }
.card-head h2, .sub { margin: 0; }
.sub { margin-bottom: 14px; }
.json { min-height: 320px; font-size: 12.5px; line-height: 1.5; white-space: pre; overflow: auto; }
.json.drop { border-color: var(--accent); box-shadow: 0 0 0 3px var(--accent-ring); }
.meta { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; margin-top: 10px; min-height: 24px; }
.error-text { color: var(--danger); }
.target-pick { display: inline-flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.input-sm { width: auto; height: 32px; padding: 0 28px 0 10px; font-size: 13px; }
.actions { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; margin-top: 14px; }
.actions .hint { flex: 1 1 200px; }
.counts { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; margin-bottom: 14px; }
.count { padding: 12px; border-radius: var(--radius-sm); border: 1px solid var(--glass-border-soft); background: var(--input-readonly); }
.count .n { font-size: 24px; font-weight: 700; line-height: 1.2; }
.count.bad { border-color: var(--danger-border-soft); background: var(--danger-fill); }
.count.bad .n { color: var(--danger); }
.bumped { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; margin-bottom: 14px; }
.errors { display: flex; flex-direction: column; gap: 10px; }
.err-scroll { max-height: 360px; overflow: auto; }
.result-card .alert + .alert, .result-card .alert { margin-bottom: 12px; }
.result-card .alert:last-child { margin-bottom: 0; }
@media (max-width: 520px) {
  .counts { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .json { min-height: 240px; }
}
</style>
