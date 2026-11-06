<script setup>
import { theme, setTheme } from '../theme'

const SUN = 'M12 7a5 5 0 100 10 5 5 0 000-10zm0-5a1 1 0 011 1v2a1 1 0 11-2 0V3a1 1 0 011-1zm0 17a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM4.2 4.2a1 1 0 011.4 0l1.4 1.4a1 1 0 01-1.4 1.4L4.2 5.6a1 1 0 010-1.4zm12.8 12.8a1 1 0 011.4 0l1.4 1.4a1 1 0 01-1.4 1.4L17 18.4a1 1 0 010-1.4zM2 12a1 1 0 011-1h2a1 1 0 110 2H3a1 1 0 01-1-1zm17 0a1 1 0 011-1h1a1 1 0 110 2h-1a1 1 0 01-1-1zM5.6 17a1 1 0 011.4 1.4l-1.4 1.4a1 1 0 01-1.4-1.4L5.6 17zM18.4 4.2a1 1 0 011.4 1.4L18.4 7A1 1 0 0117 5.6l1.4-1.4z'
const MOON = 'M21 14.5A9 9 0 019.5 3a.9.9 0 00-1.1-1.1A10 10 0 1022.1 15.6a.9.9 0 00-1.1-1.1z'
</script>

<template>
  <button
    type="button"
    class="btn btn-ghost btn-icon"
    :aria-label="theme.value === 'dark' ? 'Switch to day theme' : 'Switch to night theme'"
    :title="theme.value === 'dark' ? 'Day theme' : 'Night theme'"
    @click="setTheme(theme.value === 'dark' ? 'light' : 'dark')"
  >
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path :d="theme.value === 'dark' ? SUN : MOON" /></svg>
  </button>
</template>
