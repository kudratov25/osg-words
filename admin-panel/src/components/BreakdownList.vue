<script setup>
import { computed } from 'vue'
import { formatNumber } from '../format'

/** items: [{ label, value, detail? }] - a ranked list with proportional bars. */
const props = defineProps({
  items: { type: Array, required: true },
  unit: { type: String, default: '' },
  empty: { type: String, default: 'No data yet' },
})

const total = computed(() => props.items.reduce((s, i) => s + (i.value || 0), 0))
const max = computed(() => Math.max(1, ...props.items.map(i => i.value || 0)))
</script>

<template>
  <ul v-if="items.length" class="list">
    <li v-for="item in items" :key="item.label">
      <div class="row">
        <span class="name" :title="item.detail || item.label">{{ item.label }}</span>
        <span class="val num">
          {{ formatNumber(item.value) }}<span v-if="unit" class="faint unit">{{ unit }}</span>
          <span class="faint pct">{{ total ? Math.round((item.value / total) * 100) : 0 }}%</span>
        </span>
      </div>
      <div class="track" aria-hidden="true"><div v-if="item.value > 0" class="fill" :style="{ width: `${(item.value / max) * 100}%` }" /></div>
    </li>
  </ul>
  <p v-else class="faint small" style="margin:0">{{ empty }}</p>
</template>

<style scoped>
.list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 12px; }
.row { display: flex; justify-content: space-between; gap: 12px; font-size: 14px; margin-bottom: 5px; }
.name { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; min-width: 0; }
.val { white-space: nowrap; }
.unit { margin-left: 4px; }
.pct { display: inline-block; min-width: 40px; text-align: right; }
.track { height: 6px; border-radius: 3px; background: var(--track); overflow: hidden; }
.fill { height: 100%; border-radius: 3px; background: var(--chart); min-width: 4px; }
</style>
