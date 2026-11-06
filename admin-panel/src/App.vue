<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import AppShell from './components/AppShell.vue'

const route = useRoute()
const isPublic = computed(() => route.meta.public === true)
</script>

<template>
  <div class="bg" aria-hidden="true"><span class="b1" /><span class="b2" /><span class="b3" /></div>
  <RouterView v-if="isPublic" />
  <AppShell v-else>
    <RouterView />
  </AppShell>
</template>
