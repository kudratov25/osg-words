<script setup>
import ThemeToggle from '../components/ThemeToggle.vue'
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../api'
import BrandMark from '../components/BrandMark.vue'

const route = useRoute()
const router = useRouter()
const username = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')
const usernameInput = ref(null)

const expired = computed(() => route.query.expired === '1')

onMounted(() => usernameInput.value?.focus())

async function submit() {
  if (!username.value || !password.value) {
    error.value = 'Enter your username and password.'
    return
  }
  loading.value = true
  error.value = ''
  try {
    await api.login(username.value.trim(), password.value)
    const target = typeof route.query.redirect === 'string' && route.query.redirect.startsWith('/')
      ? route.query.redirect
      : '/'
    router.replace(target)
  } catch (e) {
    if (e.status === 401) error.value = 'Wrong username or password.'
    else if (e.status === 429) error.value = e.message || 'Too many attempts. Wait a few minutes and try again.'
    else error.value = e.message
    password.value = ''
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-page">
    <ThemeToggle class="login-theme" />
    <form class="login glass" novalidate @submit.prevent="submit">
      <div class="head">
        <BrandMark />
        <h1>Sign in</h1>
        <p class="muted">Sign in to manage words and see usage.</p>
      </div>

      <div v-if="expired && !error" class="alert alert-info">Your session ended. Please sign in again.</div>
      <div v-if="error" class="alert alert-error" role="alert">{{ error }}</div>

      <div class="field">
        <label for="username">Username</label>
        <input id="username" ref="usernameInput" v-model="username" class="input" autocomplete="username" autocapitalize="off" spellcheck="false" />
      </div>
      <div class="field">
        <label for="password">Password</label>
        <input id="password" v-model="password" class="input" type="password" autocomplete="current-password" />
      </div>

      <button class="btn btn-primary submit" type="submit" :disabled="loading">
        <span v-if="loading" class="spinner" style="width:16px;height:16px" />
        {{ loading ? 'Signing in…' : 'Sign in' }}
      </button>
    </form>
  </div>
</template>

<style scoped>
.login-theme { position: fixed; top: 14px; right: 14px; }
.login-page {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 24px 16px;
}
.login {
  width: 100%;
  max-width: 380px;
  padding: 32px 28px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.head { display: flex; flex-direction: column; align-items: center; gap: 8px; text-align: center; margin-bottom: 4px; }
.head h1 { font-size: 24px; margin-top: 6px; }
.head p { margin: 0; font-size: 14px; }
.submit { height: 44px; margin-top: 4px; }
</style>
