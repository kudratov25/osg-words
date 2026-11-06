<script setup>
import { computed, ref } from 'vue'
import { api } from '../api'

const MIN = 10

const current = ref('')
const next = ref('')
const repeat = ref('')
const show = ref(false)
const loading = ref(false)
const error = ref('')
const done = ref(false)

const tooShort = computed(() => next.value.length > 0 && next.value.length < MIN)
const mismatch = computed(() => repeat.value.length > 0 && next.value !== repeat.value)
const canSubmit = computed(() =>
  current.value && next.value.length >= MIN && next.value === repeat.value && !loading.value,
)

async function submit() {
  error.value = ''
  done.value = false
  if (!current.value) { error.value = 'Enter your current password.'; return }
  if (next.value.length < MIN) { error.value = `The new password needs at least ${MIN} characters.`; return }
  if (next.value !== repeat.value) { error.value = "The new passwords don't match."; return }
  if (next.value === current.value) { error.value = 'The new password must be different from the current one.'; return }
  loading.value = true
  try {
    await api.changePassword(current.value, next.value)
    done.value = true
    current.value = next.value = repeat.value = ''
  } catch (e) {
    if (e.status === 429) error.value = e.message || 'Too many wrong attempts. Wait 15 minutes and try again.'
    else if (e.status === 422) error.value = `The new password needs at least ${MIN} characters.`
    else error.value = e.message
    current.value = ''
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div>
    <div class="page-head">
      <div>
        <h1>Change password</h1>
        <p>Changing it signs you out everywhere else. This browser stays signed in.</p>
      </div>
    </div>

    <form class="card glass pw-card" novalidate @submit.prevent="submit">
      <div v-if="done" class="alert alert-success" role="status">Password changed. Other sessions have been signed out.</div>
      <div v-if="error" class="alert alert-error" role="alert">{{ error }}</div>

      <div class="field">
        <label for="pw-current">Current password</label>
        <input id="pw-current" v-model="current" class="input" :type="show ? 'text' : 'password'" autocomplete="current-password" />
      </div>
      <div class="field">
        <label for="pw-new">New password</label>
        <input id="pw-new" v-model="next" class="input" :type="show ? 'text' : 'password'" autocomplete="new-password" aria-describedby="pw-new-hint" />
        <span v-if="tooShort" id="pw-new-hint" class="error">At least {{ MIN }} characters ({{ next.length }}/{{ MIN }}).</span>
        <span v-else id="pw-new-hint" class="hint">At least {{ MIN }} characters.</span>
      </div>
      <div class="field">
        <label for="pw-repeat">Repeat new password</label>
        <input id="pw-repeat" v-model="repeat" class="input" :type="show ? 'text' : 'password'" autocomplete="new-password" />
        <span v-if="mismatch" class="error">Doesn't match the new password.</span>
      </div>

      <label class="show">
        <input v-model="show" type="checkbox" /> Show passwords
      </label>

      <div class="actions">
        <button class="btn btn-primary" type="submit" :disabled="!canSubmit">
          <span v-if="loading" class="spinner" style="width:16px;height:16px" />
          {{ loading ? 'Saving…' : 'Change password' }}
        </button>
      </div>
    </form>
  </div>
</template>

<style scoped>
.pw-card { max-width: 440px; display: flex; flex-direction: column; gap: 16px; }
.show { display: flex; align-items: center; gap: 8px; font-size: 14px; color: var(--text-2); cursor: pointer; }
.actions { display: flex; justify-content: flex-end; }
.actions .btn { height: 40px; }
@media (max-width: 800px) {
  .pw-card { max-width: none; }
  .actions .btn { width: 100%; }
}
</style>
