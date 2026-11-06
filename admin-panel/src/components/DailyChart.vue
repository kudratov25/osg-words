<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { formatDayLabel, formatNumber } from '../format'

/**
 * Daily active devices, last 30 days (single series -> no legend; the card
 * title names it). Columns <= 24px wide with a 4px rounded cap, square at
 * the baseline, 2px surface gap between neighbours; hairline solid grid;
 * labels only on the latest and the peak day; hover/focus tooltip carries
 * the rest; a table view is one click away.
 */
const props = defineProps({
  daily: { type: Array, required: true }, // [{date, active_devices, app_opens, notif_taps}]
})

const HEIGHT = 220
const PAD = { top: 22, right: 8, bottom: 26, left: 34 }

const wrap = ref(null)
const width = ref(640)
const hover = ref(null) // index
const showTable = ref(false)
let ro = null

onMounted(() => {
  if (!wrap.value) return
  width.value = wrap.value.clientWidth || 640
  ro = new ResizeObserver(entries => {
    const w = entries[0]?.contentRect?.width
    if (w) width.value = w
  })
  ro.observe(wrap.value)
})
onBeforeUnmount(() => ro?.disconnect())

const values = computed(() => props.daily.map(d => d.active_devices || 0))
const hasData = computed(() => values.value.some(v => v > 0))

/** Smallest "nice" axis max (4 ticks of 1/2/5 x 10^k) that fits v. */
function niceMax(v) {
  if (v <= 4) return 4
  const raw = v / 4
  const pow = 10 ** Math.floor(Math.log10(raw))
  const step = [1, 2, 5, 10].map(m => m * pow).find(s => s >= raw)
  return Math.ceil(step) * 4
}

const yMax = computed(() => niceMax(Math.max(...values.value, 0)))
const innerW = computed(() => Math.max(10, width.value - PAD.left - PAD.right))
const innerH = HEIGHT - PAD.top - PAD.bottom
const band = computed(() => innerW.value / Math.max(1, props.daily.length))
const barW = computed(() => Math.max(2, Math.min(24, band.value - 2)))
const baseY = PAD.top + innerH

const yTicks = computed(() => {
  const step = yMax.value / 4
  return [0, 1, 2, 3, 4].map(i => {
    const v = Math.round(step * i)
    return { v, y: baseY - (v / yMax.value) * innerH }
  })
})

function barPath(x, y, w, h) {
  if (h <= 0) return ''
  const r = Math.min(4, h, w / 2)
  return `M${x},${baseY} V${y + r} Q${x},${y} ${x + r},${y} H${x + w - r} Q${x + w},${y} ${x + w},${y + r} V${baseY} Z`
}

const bars = computed(() =>
  props.daily.map((d, i) => {
    const v = d.active_devices || 0
    const h = (v / yMax.value) * innerH
    const cx = PAD.left + band.value * i + band.value / 2
    const x = cx - barW.value / 2
    const y = baseY - h
    return { ...d, i, v, cx, x, y, h, path: barPath(x, y, barW.value, h) }
  }),
)

// Selective direct labels: latest day + peak day (if different and non-zero).
const labelled = computed(() => {
  const set = new Set()
  if (!bars.value.length) return set
  const last = bars.value[bars.value.length - 1]
  if (last.v > 0) set.add(last.i)
  let peak = bars.value[0]
  for (const b of bars.value) if (b.v > peak.v) peak = b
  if (peak.v > 0) set.add(peak.i)
  return set
})

// X labels: every 7th day counted back from the latest, so "today" is always labelled.
const xLabels = computed(() => {
  const n = bars.value.length
  const every = band.value < 14 ? 7 : band.value < 26 ? 5 : 3
  return bars.value.filter(b => (n - 1 - b.i) % every === 0)
})

// Keep edge labels inside the plot instead of clipping them.
function xLabelPos(b) {
  const half = 20
  if (b.cx + half > width.value - PAD.right) return { x: b.x + barW.value, anchor: 'end' }
  if (b.cx - half < PAD.left) return { x: b.x, anchor: 'start' }
  return { x: b.cx, anchor: 'middle' }
}

const tooltip = computed(() => {
  if (hover.value == null) return null
  const b = bars.value[hover.value]
  if (!b) return null
  const left = Math.min(Math.max(b.cx, 90), width.value - 90)
  return { ...b, left }
})
</script>

<template>
  <div>
    <div class="chart-actions">
      <button class="btn btn-ghost btn-sm" :aria-pressed="showTable" @click="showTable = !showTable">
        {{ showTable ? 'Show chart' : 'Show table' }}
      </button>
    </div>

    <div v-show="!showTable" ref="wrap" class="chart" @mouseleave="hover = null">
      <svg :width="width" :height="HEIGHT" role="img" :aria-label="`Daily active devices over the last ${daily.length} days`">
        <!-- grid + y ticks -->
        <g>
          <g v-for="t in yTicks" :key="t.v">
            <line :x1="PAD.left" :x2="width - PAD.right" :y1="t.y" :y2="t.y" class="grid" :class="{ base: t.v === 0 }" />
            <text :x="PAD.left - 8" :y="t.y + 4" class="tick" text-anchor="end">{{ formatNumber(t.v) }}</text>
          </g>
        </g>

        <!-- hover band -->
        <rect v-if="tooltip" :x="PAD.left + band * tooltip.i" :y="PAD.top" :width="band" :height="innerH" class="hover-band" />

        <!-- bars -->
        <path v-for="b in bars" :key="b.date" :d="b.path" class="bar" :class="{ dim: hover != null && hover !== b.i }" />

        <!-- direct labels -->
        <text v-for="b in bars.filter(b => labelled.has(b.i))" :key="'l' + b.date" :x="b.cx" :y="b.y - 6" class="value-label" text-anchor="middle">{{ formatNumber(b.v) }}</text>

        <!-- x labels -->
        <text v-for="b in xLabels" :key="'x' + b.date" :x="xLabelPos(b).x" :y="HEIGHT - 6" class="tick" :text-anchor="xLabelPos(b).anchor">{{ formatDayLabel(b.date) }}</text>

        <!-- hit targets (full band height, bigger than the mark) -->
        <rect
          v-for="b in bars"
          :key="'h' + b.date"
          :x="PAD.left + band * b.i"
          :y="PAD.top"
          :width="band"
          :height="innerH"
          fill="transparent"
          tabindex="0"
          :aria-label="`${formatDayLabel(b.date, true)}: ${b.v} active devices, ${b.app_opens} app opens, ${b.notif_taps} notification taps`"
          @mouseenter="hover = b.i"
          @focus="hover = b.i"
          @blur="hover = null"
        />
      </svg>

      <div v-if="!hasData" class="empty-overlay">No activity in the last 30 days yet</div>

      <div v-if="tooltip" class="tooltip glass" :style="{ left: tooltip.left + 'px' }" role="status">
        <div class="tt-date">{{ formatDayLabel(tooltip.date, true) }}</div>
        <div class="tt-row"><span class="sw" />Active devices <strong class="num">{{ formatNumber(tooltip.active_devices) }}</strong></div>
        <div class="tt-row muted">App opens <strong class="num">{{ formatNumber(tooltip.app_opens) }}</strong></div>
        <div class="tt-row muted">Notification taps <strong class="num">{{ formatNumber(tooltip.notif_taps) }}</strong></div>
      </div>
    </div>

    <div v-if="showTable" class="table-wrap">
      <table class="table">
        <thead>
          <tr><th>Day (UTC)</th><th class="right">Active devices</th><th class="right">App opens</th><th class="right">Notification taps</th></tr>
        </thead>
        <tbody>
          <tr v-for="d in [...daily].reverse()" :key="d.date">
            <td class="nowrap">{{ formatDayLabel(d.date, true) }}</td>
            <td class="right num">{{ formatNumber(d.active_devices) }}</td>
            <td class="right num">{{ formatNumber(d.app_opens) }}</td>
            <td class="right num">{{ formatNumber(d.notif_taps) }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<style scoped>
.chart-actions { position: absolute; top: 14px; right: 14px; }
.chart { position: relative; width: 100%; overflow: hidden; }
svg { display: block; }
.grid { stroke: var(--grid); stroke-width: 1; shape-rendering: crispEdges; }
.grid.base { stroke: var(--axis); }
.tick { fill: var(--text-3); font-size: 11px; font-family: var(--font); }
.value-label { fill: var(--text); font-size: 11px; font-weight: 600; font-family: var(--font); }
.bar { fill: var(--chart); transition: opacity 0.12s; }
.bar.dim { opacity: 0.45; }
.hover-band { fill: var(--hover-band); }
rect[tabindex]:focus { outline: none; }
.empty-overlay {
  position: absolute;
  inset: 0 0 26px 34px;
  display: grid;
  place-items: center;
  color: var(--text-2);
  font-size: 14px;
  pointer-events: none;
}
.tooltip {
  position: absolute;
  top: 4px;
  transform: translateX(-50%);
  padding: 10px 12px;
  border-radius: var(--radius-sm);
  font-size: 13px;
  pointer-events: none;
  min-width: 170px;
  background: var(--popover);
}
.tt-date { font-weight: 700; margin-bottom: 4px; }
.tt-row { display: flex; align-items: center; gap: 6px; }
.tt-row strong { margin-left: auto; color: var(--text); }
.sw { width: 10px; height: 10px; border-radius: 3px; background: var(--chart); flex: none; }
</style>
