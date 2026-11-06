<script setup>
import { computed, onMounted, ref } from 'vue'
import { api } from '../api'
import { formatDateTime, formatNumber, splitOs } from '../format'
import StatTile from '../components/StatTile.vue'
import DailyChart from '../components/DailyChart.vue'
import BreakdownList from '../components/BreakdownList.vue'
import { pairLabel } from '../languages'

const stats = ref(null)
const loading = ref(true)
const error = ref('')

async function load() {
  loading.value = true
  error.value = ''
  try {
    stats.value = await api.stats()
  } catch (e) {
    if (e.status !== 401) error.value = e.message
  } finally {
    loading.value = false
  }
}
onMounted(load)

const platforms = computed(() => {
  // Group "android TP1A..." style strings by platform; keep raw strings as detail.
  const groups = new Map()
  for (const p of stats.value?.platforms ?? []) {
    const { platform } = splitOs(p.os)
    const g = groups.get(platform) ?? { label: platform, value: 0, details: [] }
    g.value += p.devices
    if (p.os) g.details.push(p.os)
    groups.set(platform, g)
  }
  return [...groups.values()]
    .sort((a, b) => b.value - a.value)
    .map(g => ({ label: g.label, value: g.value, detail: g.details.join(', ') }))
})

const versions = computed(() =>
  (stats.value?.app_versions ?? [])
    .map(v => ({ label: v.version ? `v${v.version}` : 'Unknown', value: v.devices }))
    .sort((a, b) => b.value - a.value),
)

const pairs = computed(() =>
  (stats.value?.pairs ?? [])
    .map(p => ({ label: pairLabel(p.pair), value: p.devices, detail: p.pair }))
    .sort((a, b) => b.value - a.value),
)

const events = computed(() => {
  const e = stats.value?.events ?? {}
  return [
    { label: 'App opens', value: e.app_open ?? 0 },
    { label: 'Notification taps', value: e.notif_tapped ?? 0 },
    { label: 'Notifications delivered', value: e.notif_delivered ?? 0 },
  ]
})
</script>

<template>
  <div>
    <div class="page-head">
      <div>
        <h1>Dashboard</h1>
        <p>How many people use OSG, and how.</p>
      </div>
      <button class="btn btn-sm" :disabled="loading" @click="load">
        <span v-if="loading" class="spinner" style="width:14px;height:14px" /> Refresh
      </button>
    </div>

    <div v-if="error" class="alert alert-error" role="alert">
      Couldn't load stats: {{ error }} <button class="btn btn-sm" style="margin-left:8px" @click="load">Retry</button>
    </div>

    <div v-else-if="loading && !stats" class="state"><span class="spinner" /></div>

    <div v-else-if="stats" class="stack">
      <div class="tiles">
        <StatTile label="Total users (devices)" :value="stats.devices_total" :hint="`${formatNumber(stats.pings_total)} pings in total`" />
        <StatTile label="Active today" :value="stats.active_today" hint="UTC day" />
        <StatTile label="Active 7 days" :value="stats.active_7d" />
        <StatTile label="Active 30 days" :value="stats.active_30d" />
        <StatTile label="New this week" :value="stats.new_7d" hint="first seen in last 7 days" />
        <StatTile label="Users with accounts" :value="stats.users_total ?? 0" hint="signed in with email" />
        <StatTile label="Words (all languages)" :value="stats.words_total" :hint="`en-de pack v${stats.pack_version}`" :title="`en-de pack updated ${formatDateTime(stats.pack_updated_at)}`" />
      </div>

      <div v-if="stats.devices_total === 0" class="alert alert-info">
        No devices have reported yet. Usage appears here once someone opens the app with "Share anonymous usage data" switched on.
      </div>

      <section class="card glass chart-card">
        <div class="card-head">
          <div>
            <h2>Daily active devices</h2>
            <div class="faint small">Last 30 days · devices that opened the app or tapped a notification</div>
          </div>
        </div>
        <DailyChart :daily="stats.daily ?? []" />
      </section>

      <div class="grid3">
        <section class="card glass">
          <h2 class="sub">Platforms</h2>
          <BreakdownList :items="platforms" unit="devices" />
        </section>
        <section class="card glass">
          <h2 class="sub">App versions</h2>
          <BreakdownList :items="versions" unit="devices" />
        </section>
        <section class="card glass">
          <h2 class="sub">Language pairs in use</h2>
          <BreakdownList :items="pairs" unit="devices" empty="No device has reported a pair yet (app v2+)" />
        </section>
        <section class="card glass">
          <h2 class="sub">Events (all time)</h2>
          <BreakdownList :items="events" empty="No events yet" />
        </section>
      </div>
    </div>
  </div>
</template>

<style scoped>
.tiles {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(150px, 100%), 1fr));
  gap: 12px;
}
@media (max-width: 520px) {
  .tiles { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; }
}
.chart-card { position: relative; }
.grid3 {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(320px, 100%), 1fr));
  gap: 16px;
}
.sub { margin-bottom: 14px; }
</style>
