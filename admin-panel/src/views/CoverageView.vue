<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../api'
import { formatNumber } from '../format'
import { LANGS } from '../languages'

const data = ref(null)
const loading = ref(true)
const error = ref('')

async function load() {
  loading.value = true
  error.value = ''
  try {
    data.value = await api.coverage()
  } catch (e) {
    if (e.status !== 401) error.value = e.message
  } finally {
    loading.value = false
  }
}
onMounted(load)

/** Rounded down, so 500 of 501 never reads as 100%. */
function pct(n, total) {
  return total ? Math.floor((n / total) * 100) : 0
}
const isDefault = p => p.source === 'en' && p.target === 'de'
</script>

<template>
  <div>
    <div class="page-head">
      <div>
        <h1>Coverage</h1>
        <p>How many words of each language have a translation, and which language pairs the app offers.</p>
      </div>
      <button class="btn btn-sm" :disabled="loading" @click="load">
        <span v-if="loading" class="spinner" style="width:14px;height:14px" /> Refresh
      </button>
    </div>

    <div v-if="error" class="alert alert-error" role="alert">
      Couldn't load coverage: {{ error }} <button class="btn btn-sm" style="margin-left:8px" @click="load">Retry</button>
    </div>
    <div v-else-if="loading && !data" class="state"><span class="spinner" /></div>

    <div v-else-if="data" class="stack">
      <div class="targets">
        <section v-for="t in data.targets" :key="t.target" class="card glass">
          <div class="card-head">
            <h2>{{ LANGS[t.target]?.flag }} {{ LANGS[t.target]?.native ?? t.target }}</h2>
            <span class="badge">{{ formatNumber(t.words) }} words</span>
          </div>
          <ul class="rows">
            <li v-for="(n, s) in t.translations" :key="s">
              <div class="row">
                <span>{{ LANGS[s]?.flag }} {{ LANGS[s]?.english ?? s }}</span>
                <span class="num">
                  {{ formatNumber(n) }} <span class="faint">/ {{ formatNumber(t.words) }}</span>
                  <span class="pct" :class="{ full: t.words && n === t.words }">{{ pct(n, t.words) }}%</span>
                </span>
              </div>
              <div class="progress" :class="{ ok: t.words && n === t.words }" role="progressbar" :aria-valuenow="pct(n, t.words)" aria-valuemin="0" aria-valuemax="100" :aria-label="`${LANGS[s]?.english} translations`">
                <span :style="{ width: `${pct(n, t.words)}%` }" />
              </div>
            </li>
          </ul>
          <p v-if="t.words === 0" class="faint small" style="margin:12px 0 0">No words yet — add them on the Words page or import a content file.</p>
        </section>
      </div>

      <section class="glass table-card pairs">
        <div class="table-toolbar">
          <h2>Language pairs</h2>
          <div class="faint small" style="margin-top:2px">
            A pair is offered in the app once it has at least <strong class="muted">{{ formatNumber(data.min_pair_words) }}</strong> translated words
            (<span class="mono">MIN_PAIR_WORDS</span>). English → German is always offered: installed v1.0 apps depend on it.
          </div>
        </div>
        <div class="table-scroll">
          <table class="table">
            <thead>
              <tr>
                <th>I speak → I learn</th>
                <th class="right">Words</th>
                <th>Threshold</th>
                <th>In the app</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="p in data.pairs" :key="`${p.source}-${p.target}`">
                <td class="nowrap">
                  {{ LANGS[p.source]?.flag }} {{ LANGS[p.source]?.english }} → {{ LANGS[p.target]?.flag }} {{ LANGS[p.target]?.english }}
                  <div class="faint mono" style="font-size:12px">{{ p.source }}-{{ p.target }}</div>
                </td>
                <td class="right num">{{ formatNumber(p.words) }}</td>
                <td class="thr">
                  <div class="progress" :class="{ ok: p.words >= data.min_pair_words }" aria-hidden="true">
                    <span :style="{ width: `${Math.min(100, pct(p.words, data.min_pair_words))}%` }" />
                  </div>
                  <div class="faint small num">
                    {{ p.words >= data.min_pair_words ? 'reached' : `${formatNumber(data.min_pair_words - p.words)} more needed` }}
                  </div>
                </td>
                <td class="nowrap">
                  <span class="badge" :class="p.available ? 'badge-beginner' : 'badge-advanced'">{{ p.available ? 'Yes' : 'No' }}</span>
                  <span v-if="isDefault(p) && p.words < data.min_pair_words" class="faint small" style="margin-left:6px">always on</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.targets { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(320px, 100%), 1fr)); gap: 16px; }
.rows { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 14px; }
.row { display: flex; justify-content: space-between; gap: 12px; font-size: 14px; margin-bottom: 6px; }
.pct { display: inline-block; min-width: 44px; text-align: right; font-weight: 700; color: var(--text-2); }
.pct.full { color: var(--success); }
.pairs { min-height: 0; }
.pairs h2 { margin: 0; }
.thr { min-width: 160px; }
.thr .progress { margin: 6px 0 4px; }
</style>
