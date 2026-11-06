<script setup>
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { api } from '../api'
import { formatDateTime, formatNumber, relativeTime, shortId, splitOs } from '../format'
import Pagination from '../components/Pagination.vue'
import { pairLabel } from '../languages'

const PAGE_SIZE_KEY = 'osg_admin_devices_page_size'
const items = ref([])
const total = ref(0)
const page = ref(1)
const pageSize = ref(readPageSize())
const scroller = ref(null)
const q = ref('')
const loading = ref(true)
const error = ref('')
const copied = ref('')
const now = ref(Date.now())
let debounce = null
let ticker = null
let requestId = 0

function readPageSize() {
  try { return [25, 50, 100].includes(Number(localStorage.getItem(PAGE_SIZE_KEY))) ? Number(localStorage.getItem(PAGE_SIZE_KEY)) : 25 } catch { return 25 }
}

async function load() {
  const id = ++requestId
  loading.value = true
  error.value = ''
  try {
    const data = await api.devices({ limit: pageSize.value, offset: (page.value - 1) * pageSize.value, q: q.value.trim() })
    if (id !== requestId) return // a newer search replaced this one
    items.value = data.items
    total.value = data.total
    now.value = Date.now()
    // Deleted/filtered past the end: go to the last page that exists.
    const last = Math.max(1, Math.ceil(data.total / pageSize.value))
    if (page.value > last) { page.value = last; return } // the page watcher reloads
    if (scroller.value) scroller.value.scrollTop = 0
  } catch (e) {
    if (id === requestId && e.status !== 401) error.value = e.message
  } finally {
    if (id === requestId) loading.value = false
  }
}

watch(q, () => {
  clearTimeout(debounce)
  debounce = setTimeout(() => {
    if (page.value === 1) load()
    else page.value = 1 // the page watcher reloads
  }, 300)
})

// One load per change, even when page size and page change together.
watch([page, pageSize], load)
watch(pageSize, size => {
  try { localStorage.setItem(PAGE_SIZE_KEY, String(size)) } catch { /* not remembered */ }
})

async function copy(id) {
  try {
    await navigator.clipboard.writeText(id)
    copied.value = id
    setTimeout(() => { if (copied.value === id) copied.value = '' }, 1500)
  } catch {
    // clipboard blocked - full id is still visible in the tooltip
  }
}

onMounted(() => {
  load()
  ticker = setInterval(() => { now.value = Date.now() }, 30000)
})
onBeforeUnmount(() => {
  clearTimeout(debounce)
  clearInterval(ticker)
})
</script>

<template>
  <div class="page-fill">
    <div class="page-head">
      <div>
        <h1>Devices</h1>
        <p>{{ formatNumber(total) }} {{ total === 1 ? 'device' : 'devices' }} have used the app. Each is an anonymous install, not a person's identity.</p>
      </div>
    </div>

    <section class="glass table-card">
      <div class="toolbar table-toolbar">
        <input v-model="q" class="input" type="search" placeholder="Search by device ID…" aria-label="Search by device ID" />
        <span v-if="loading" class="spinner" style="width:18px;height:18px" />
      </div>

      <div v-if="error" class="table-state">
        <div class="alert alert-error" role="alert">
          {{ error }} <button class="btn btn-sm" style="margin-left:8px" @click="load">Retry</button>
        </div>
      </div>

      <div v-else-if="!loading && items.length === 0" class="table-state state">
        <strong>{{ q ? 'No matching devices' : 'No devices yet' }}</strong>
        {{ q ? 'Try a different ID fragment.' : 'Devices appear after their first app open.' }}
      </div>

      <div v-else ref="scroller" class="table-scroll" :class="{ busy: loading }">
        <table class="table">
          <thead>
            <tr>
              <th>Device</th>
              <th>Platform</th>
              <th>App</th>
              <th>Pair</th>
              <th>First seen</th>
              <th>Last seen</th>
              <th class="right">Pings</th>
              <th class="right">Opens</th>
              <th class="right">Taps</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="d in items" :key="d.device_id">
              <td class="nowrap">
                <span class="mono" :title="d.device_id">{{ shortId(d.device_id) }}</span>
                <button class="btn btn-ghost btn-sm copy" :title="`Copy ${d.device_id}`" :aria-label="`Copy device ID ${d.device_id}`" @click="copy(d.device_id)">
                  {{ copied === d.device_id ? 'Copied' : 'Copy' }}
                </button>
              </td>
              <td class="nowrap">
                {{ splitOs(d.os_version).platform }}
                <div class="faint small">{{ splitOs(d.os_version).detail }}</div>
              </td>
              <td class="nowrap">{{ d.app_version ? `v${d.app_version}` : '—' }}</td>
              <td class="nowrap" :title="d.pair || 'No pair reported (app v1.0)'">{{ d.pair ? pairLabel(d.pair) : '—' }}</td>
              <td class="nowrap muted">{{ formatDateTime(d.first_seen) }}</td>
              <td class="nowrap" :title="formatDateTime(d.last_seen)">{{ relativeTime(d.last_seen, now) }}</td>
              <td class="right num">{{ formatNumber(d.pings) }}</td>
              <td class="right num">{{ formatNumber(d.app_opens) }}</td>
              <td class="right num">{{ formatNumber(d.notif_taps) }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div v-if="!error && total > 0" class="table-footer">
        <Pagination v-model:page="page" v-model:page-size="pageSize" :total="total" />
      </div>
    </section>
  </div>
</template>

<style scoped>
.copy { margin-left: 4px; height: 24px; padding: 0 8px; font-size: 12px; }
</style>
