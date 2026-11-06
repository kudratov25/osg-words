<script setup>
import { computed } from 'vue'
import { formatNumber } from '../format'

/** Footer pager: rows-per-page, "1–25 of 60", page buttons. Pages are 1-based. */
const props = defineProps({
  total: { type: Number, required: true },
  page: { type: Number, required: true },
  pageSize: { type: Number, required: true },
  pageSizes: { type: Array, default: () => [25, 50, 100] },
})
const emit = defineEmits(['update:page', 'update:pageSize'])

const pages = computed(() => Math.max(1, Math.ceil(props.total / props.pageSize)))
const from = computed(() => (props.total === 0 ? 0 : (props.page - 1) * props.pageSize + 1))
const to = computed(() => Math.min(props.page * props.pageSize, props.total))

/** e.g. 1 … 4 5 [6] 7 8 … 20 */
const items = computed(() => {
  const n = pages.value
  const p = props.page
  if (n <= 7) return Array.from({ length: n }, (_, i) => i + 1)
  const out = [1]
  const start = Math.max(2, p - 1)
  const end = Math.min(n - 1, p + 1)
  if (start > 2) out.push('…')
  for (let i = start; i <= end; i++) out.push(i)
  if (end < n - 1) out.push('…')
  out.push(n)
  return out
})

function go(p) {
  const clamped = Math.min(Math.max(1, p), pages.value)
  if (clamped !== props.page) emit('update:page', clamped)
}
function setSize(e) {
  emit('update:pageSize', Number(e.target.value))
  emit('update:page', 1)
}
</script>

<template>
  <div class="pager">
    <label class="size muted small">
      Rows per page
      <select class="input input-sm" :value="pageSize" @change="setSize">
        <option v-for="s in pageSizes" :key="s" :value="s">{{ s }}</option>
      </select>
    </label>

    <span class="muted small num range">{{ formatNumber(from) }}–{{ formatNumber(to) }} of {{ formatNumber(total) }}</span>

    <nav class="pages" aria-label="Pagination">
      <button class="pg" :disabled="page <= 1" aria-label="Previous page" @click="go(page - 1)">‹</button>
      <template v-for="(it, i) in items" :key="i">
        <span v-if="it === '…'" class="gap faint" aria-hidden="true">…</span>
        <button v-else class="pg num" :class="{ on: it === page }" :aria-current="it === page ? 'page' : undefined" @click="go(it)">{{ it }}</button>
      </template>
      <button class="pg" :disabled="page >= pages" aria-label="Next page" @click="go(page + 1)">›</button>
    </nav>
  </div>
</template>

<style scoped>
.pager { display: flex; align-items: center; gap: 16px; flex-wrap: wrap; }
.size { display: flex; align-items: center; gap: 8px; white-space: nowrap; }
.input-sm { width: auto; height: 32px; padding: 0 28px 0 10px; font-size: 13px; }
.range { margin-left: auto; white-space: nowrap; }
.pages { display: flex; align-items: center; gap: 4px; }
.pg {
  min-width: 32px;
  height: 32px;
  padding: 0 8px;
  border-radius: 8px;
  border: 1px solid transparent;
  background: transparent;
  color: var(--text-2);
  font: inherit;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}
.pg:hover:not(:disabled) { background: var(--glass-fill); color: var(--text); }
.pg.on { background: var(--accent-tint); color: var(--accent); border-color: var(--accent-ring); }
.pg:disabled { opacity: 0.35; cursor: default; }
.pg:focus-visible { outline: 2px solid var(--accent); outline-offset: 1px; }
.gap { padding: 0 2px; }
@media (max-width: 560px) {
  .size { display: none; }
  .range { margin-left: 0; }
  .pager { justify-content: space-between; }
}
</style>
