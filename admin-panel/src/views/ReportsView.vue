<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { api } from '../api'
import { formatDateTime, formatNumber, relativeTime, shortId } from '../format'
import { pairLabel } from '../languages'
import Pagination from '../components/Pagination.vue'

const STATUS_KEY = 'osg_admin_reports_status'
const PAGE_SIZE_KEY = 'osg_admin_reports_page_size'
function readStatus() {
  try { const v = localStorage.getItem(STATUS_KEY); return ['open', 'resolved', ''].includes(v) ? v : 'open' } catch { return 'open' }
}
function readPageSize() {
  try { const n = Number(localStorage.getItem(PAGE_SIZE_KEY)); return [25, 50, 100].includes(n) ? n : 25 } catch { return 25 }
}

const status = ref(readStatus())
const items = ref([])
const loading = ref(true)
const error = ref('')
const rowError = ref('')
const busyId = ref(null)
const page = ref(1)
const pageSize = ref(readPageSize())
const scroller = ref(null)
const now = ref(Date.now())
let ticker = null
let requestId = 0

const KINDS = {
  wrong_translation: 'Wrong translation',
  wrong_article: 'Wrong article',
  wrong_example: 'Wrong example',
  other: 'Other',
}
const STATUSES = [
  { value: 'open', label: 'Open' },
  { value: 'resolved', label: 'Resolved' },
  { value: '', label: 'All' },
]

async function load() {
  const id = ++requestId
  loading.value = true
  error.value = ''
  try {
    const data = await api.wordIssues(status.value)
    if (id !== requestId) return
    items.value = data
    now.value = Date.now()
  } catch (e) {
    if (id === requestId && e.status !== 401) error.value = e.message
  } finally {
    if (id === requestId) loading.value = false
  }
}

watch(status, v => {
  try { localStorage.setItem(STATUS_KEY, v) } catch { /* not remembered */ }
  page.value = 1
  load()
})
watch(pageSize, size => {
  try { localStorage.setItem(PAGE_SIZE_KEY, String(size)) } catch { /* not remembered */ }
})
const pages = computed(() => Math.max(1, Math.ceil(items.value.length / pageSize.value)))
watch(pages, n => { if (page.value > n) page.value = n })
watch([page, pageSize], () => { if (scroller.value) scroller.value.scrollTop = 0 })
const pageRows = computed(() => items.value.slice((page.value - 1) * pageSize.value, page.value * pageSize.value))

async function setStatus(issue, next) {
  busyId.value = issue.id
  rowError.value = ''
  try {
    const updated = await api.updateWordIssue(issue.id, next)
    // Leaves the list when it no longer matches the filter.
    if (status.value && updated.status !== status.value) {
      items.value = items.value.filter(i => i.id !== issue.id)
    } else {
      items.value = items.value.map(i => (i.id === issue.id ? updated : i))
    }
  } catch (e) {
    if (e.status !== 401) rowError.value = `Couldn't update report #${issue.id}: ${e.message}`
  } finally {
    busyId.value = null
  }
}

onMounted(() => {
  load()
  ticker = setInterval(() => { now.value = Date.now() }, 30000)
})
onBeforeUnmount(() => clearInterval(ticker))

const summary = computed(() => {
  const n = items.value.length
  const word = n === 1 ? 'report' : 'reports'
  if (status.value === 'open') return `${formatNumber(n)} open ${word}`
  if (status.value === 'resolved') return `${formatNumber(n)} resolved ${word}`
  return `${formatNumber(n)} ${word}`
})
</script>

<template>
  <div class="page-fill">
    <div class="page-head">
      <div>
        <h1>Reports</h1>
        <p>{{ summary }}. Mistakes people flagged on a word card with “Report a mistake”.</p>
      </div>
    </div>

    <div v-if="rowError" class="alert alert-error notice" role="alert">{{ rowError }}</div>

    <section class="glass table-card">
      <div class="toolbar table-toolbar">
        <div class="seg" role="radiogroup" aria-label="Status">
          <button
            v-for="s in STATUSES"
            :key="s.value"
            class="seg-btn"
            :class="{ on: status === s.value }"
            role="radio"
            :aria-checked="status === s.value"
            @click="status = s.value"
          >{{ s.label }}</button>
        </div>
        <button class="btn btn-sm" :disabled="loading" @click="load">
          <span v-if="loading" class="spinner" style="width:14px;height:14px" /> Refresh
        </button>
      </div>

      <div v-if="error" class="table-state">
        <div class="alert alert-error" role="alert">
          {{ error }} <button class="btn btn-sm" style="margin-left:8px" @click="load">Retry</button>
        </div>
      </div>
      <div v-else-if="loading && items.length === 0" class="table-state state"><span class="spinner" /></div>
      <div v-else-if="items.length === 0" class="table-state state">
        <strong>{{ status === 'open' ? 'No open reports' : status === 'resolved' ? 'No resolved reports' : 'No reports yet' }}</strong>
        {{ status === 'open' ? 'Nothing to fix right now.' : 'Reports appear when someone flags a word in the app.' }}
      </div>

      <template v-else>
        <div ref="scroller" class="table-scroll" :class="{ busy: loading }">
          <table class="table">
            <thead>
              <tr>
                <th>Time</th>
                <th>Word</th>
                <th>Pair</th>
                <th>Kind</th>
                <th>Note</th>
                <th>Device</th>
                <th class="right"><span class="sr-only">Actions</span></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="r in pageRows" :key="r.id" :class="{ resolved: r.status === 'resolved' }">
                <td class="nowrap" :title="formatDateTime(r.created_at)">
                  {{ relativeTime(r.created_at, now) }}
                  <div class="faint small">#{{ r.id }}</div>
                </td>
                <td class="nowrap">
                  <strong v-if="r.term">{{ r.term }}</strong>
                  <span v-else class="faint small">deleted word</span>
                  <div class="faint mono" style="font-size:12px">{{ r.external_id }}</div>
                </td>
                <td class="nowrap">{{ pairLabel(`${r.source}-${r.target}`) }}</td>
                <td class="nowrap"><span class="badge" :class="`kind-${r.kind}`">{{ KINDS[r.kind] ?? r.kind }}</span></td>
                <td class="note">
                  <template v-if="r.note">{{ r.note }}</template>
                  <span v-else class="faint">—</span>
                </td>
                <td class="nowrap">
                  <span class="mono" :title="r.device_id">{{ r.device_id === 'deleted' ? 'deleted' : shortId(r.device_id) }}</span>
                </td>
                <td class="right nowrap">
                  <RouterLink
                    v-if="r.term"
                    class="btn btn-sm"
                    :to="{ name: 'words', query: { target: r.target, edit: r.external_id } }"
                  >Edit word</RouterLink>
                  <button
                    v-if="r.status === 'open'"
                    class="btn btn-sm btn-primary act"
                    :disabled="busyId === r.id"
                    @click="setStatus(r, 'resolved')"
                  >Resolve</button>
                  <button
                    v-else
                    class="btn btn-sm act"
                    :disabled="busyId === r.id"
                    @click="setStatus(r, 'open')"
                  >Reopen</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="table-footer">
          <Pagination v-model:page="page" v-model:page-size="pageSize" :total="items.length" />
        </div>
      </template>
    </section>
  </div>
</template>

<style scoped>
.notice { margin-bottom: 16px; }
.note { min-width: 200px; max-width: 360px; overflow-wrap: anywhere; }
.act { margin-left: 6px; min-width: 76px; }
.btn:hover { text-decoration: none; }
tr.resolved td { color: var(--text-2); }
.kind-wrong_translation { color: var(--badge-advanced); border-color: var(--badge-advanced-border); }
.kind-wrong_article, .kind-wrong_example { color: var(--badge-intermediate); border-color: var(--badge-intermediate-border); }
.table-toolbar { justify-content: space-between; }
</style>
