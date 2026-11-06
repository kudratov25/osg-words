<script setup>
defineProps({ compact: { type: Boolean, default: false } })
</script>

<template>
  <span class="brand-mark" :class="{ compact }">
    <span class="osg">OSG</span><span v-if="!compact" class="sub">Admin</span>
  </span>
</template>

<style scoped>
.brand-mark { display: inline-flex; align-items: baseline; gap: 6px; white-space: nowrap; line-height: 1; }
.osg {
  font-size: 20px;
  font-weight: 800;
  letter-spacing: 0.04em;
  background: linear-gradient(120deg, var(--accent), var(--blob-2));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.compact .osg { font-size: 15px; letter-spacing: 0.02em; }
.sub { font-size: 14px; font-weight: 600; color: var(--text-2); }
</style>
