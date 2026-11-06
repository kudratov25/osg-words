<script setup>
import { formatNumber } from '../format'

defineProps({
  label: { type: String, required: true },
  value: { type: Number, default: null },
  hint: { type: String, default: '' },
})
</script>

<template>
  <div class="tile glass">
    <div class="label">{{ label }}</div>
    <div class="value num">{{ formatNumber(value) }}</div>
    <div v-if="hint" class="hint">{{ hint }}</div>
  </div>
</template>

<style scoped>
.tile { padding: 16px 18px; display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.label { font-size: 13px; color: var(--text-2); font-weight: 600; }
.value { font-size: clamp(22px, 6vw, 30px); font-weight: 700; letter-spacing: -0.02em; line-height: 1.2; }
.hint { font-size: 12px; color: var(--text-3); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
</style>
