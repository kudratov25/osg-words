<script setup>
import { onMounted, onBeforeUnmount, ref, nextTick } from 'vue'

const props = defineProps({
  title: { type: String, required: true },
  width: { type: String, default: '560px' },
})
const emit = defineEmits(['close'])
const panel = ref(null)
let previouslyFocused = null

function onKey(e) {
  if (e.key === 'Escape') emit('close')
}

onMounted(async () => {
  previouslyFocused = document.activeElement
  document.addEventListener('keydown', onKey)
  document.body.style.overflow = 'hidden'
  await nextTick()
  const first = panel.value?.querySelector('input:not([readonly]), select, textarea, button.btn-primary, button.btn-danger')
  first?.focus()
})

onBeforeUnmount(() => {
  document.removeEventListener('keydown', onKey)
  document.body.style.overflow = ''
  previouslyFocused?.focus?.()
})
</script>

<template>
  <Teleport to="body">
    <div class="overlay" @mousedown.self="emit('close')">
      <div ref="panel" class="panel glass" role="dialog" aria-modal="true" :aria-label="props.title" :style="{ maxWidth: props.width }">
        <div class="panel-head">
          <h2>{{ props.title }}</h2>
          <button class="btn btn-ghost btn-sm btn-icon" aria-label="Close" @click="emit('close')">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M18.3 5.7L12 12l6.3 6.3-1.4 1.4L10.6 13.4 4.3 19.7 2.9 18.3 9.2 12 2.9 5.7l1.4-1.4 6.3 6.3 6.3-6.3z" /></svg>
          </button>
        </div>
        <slot />
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  z-index: 50;
  background: var(--overlay);
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding: 6vh 16px 24px;
  overflow-y: auto;
}
.panel {
  width: 100%;
  padding: 22px;
  background: linear-gradient(140deg, var(--modal-a), var(--modal-b));
}
.panel-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; gap: 12px; }
</style>
