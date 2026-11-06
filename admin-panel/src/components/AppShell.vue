<script setup>
import { DEMO } from '../demo'
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { session, logout } from '../auth'
import BrandMark from './BrandMark.vue'
import ThemeToggle from './ThemeToggle.vue'

const route = useRoute()
const router = useRouter()

const COLLAPSE_KEY = 'osg_admin_sidebar_collapsed'
function readCollapsed() {
  try { return localStorage.getItem(COLLAPSE_KEY) === '1' } catch { return false }
}
const collapsed = ref(readCollapsed())   // desktop: icon-only rail
const drawerOpen = ref(false)            // phone: slide-in drawer
const menuOpen = ref(false)              // user menu in the header

const isPhone = ref(false)
const mq = window.matchMedia('(max-width: 800px)')
const syncPhone = () => { isPhone.value = mq.matches; if (!mq.matches) drawerOpen.value = false }
onMounted(() => { syncPhone(); mq.addEventListener('change', syncPhone) })

function toggleSidebar() {
  if (isPhone.value) {
    drawerOpen.value = !drawerOpen.value
  } else {
    collapsed.value = !collapsed.value
    try { localStorage.setItem(COLLAPSE_KEY, collapsed.value ? '1' : '0') } catch { /* not remembered */ }
  }
}

const ICONS = {
  dashboard: 'M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z',
  words: 'M4 5h16v2H4V5zm0 6h16v2H4v-2zm0 6h10v2H4v-2z',
  import: 'M5 20h14v-2H5v2zm7-18l-5.5 5.5 1.4 1.4L11 5.8V16h2V5.8l3.1 3.1 1.4-1.4L12 2z',
  coverage: 'M5 9.2h3V19H5V9.2zM10.6 5h2.8v14h-2.8V5zm5.6 8H19v6h-2.8v-6z',
  reports: 'M14.4 6L14 4H5v17h2v-7h5.6l.4 2h7V6h-5.6z',
  devices: 'M7 2h10a2 2 0 012 2v16a2 2 0 01-2 2H7a2 2 0 01-2-2V4a2 2 0 012-2zm0 3v13h10V5H7zm5 14.2a1 1 0 100 2 1 1 0 000-2z',
}
const sections = [
  { label: 'Overview', links: [{ name: 'dashboard', label: 'Dashboard' }] },
  { label: 'Content', links: [{ name: 'words', label: 'Words' }, { name: 'import', label: 'Import' }, { name: 'coverage', label: 'Coverage' }] },
  { label: 'Users', links: [{ name: 'devices', label: 'Devices' }, { name: 'reports', label: 'Reports' }] },
]

const pageTitle = computed(() => route.meta.title || '')
const username = computed(() => session.data?.username || '')
const initial = computed(() => (username.value || '?').slice(0, 1).toUpperCase())

watch(() => route.fullPath, () => { drawerOpen.value = false; menuOpen.value = false })

function onDocClick(e) {
  if (menuOpen.value && !e.target.closest('.user-menu')) menuOpen.value = false
}
function onKey(e) {
  if (e.key === 'Escape') { menuOpen.value = false; drawerOpen.value = false }
}
onMounted(() => { document.addEventListener('click', onDocClick); document.addEventListener('keydown', onKey) })
onBeforeUnmount(() => {
  document.removeEventListener('click', onDocClick)
  document.removeEventListener('keydown', onKey)
  mq.removeEventListener('change', syncPhone)
})

function signOut() {
  logout()
  router.replace({ name: 'login' })
}
</script>

<template>
  <div class="shell" :class="{ collapsed: collapsed && !isPhone }">
    <aside id="sidebar" class="sidebar" :class="{ open: drawerOpen }" aria-label="Main navigation">
      <div class="side-brand">
        <RouterLink :to="{ name: 'dashboard' }" class="brand-link" aria-label="OSG Admin home">
          <BrandMark :compact="collapsed && !isPhone" />
        </RouterLink>
      </div>

      <nav class="side-nav">
        <div v-for="s in sections" :key="s.label" class="nav-section">
          <div class="nav-label">{{ s.label }}</div>
          <RouterLink
            v-for="l in s.links"
            :key="l.name"
            :to="{ name: l.name }"
            class="nav-link"
            :class="{ active: route.name === l.name }"
            :aria-current="route.name === l.name ? 'page' : undefined"
            :title="collapsed && !isPhone ? l.label : undefined"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path :d="ICONS[l.name]" /></svg>
            <span class="nav-text">{{ l.label }}</span>
          </RouterLink>
        </div>
      </nav>

      <div class="side-foot faint small">
        <span class="nav-text">Words every day</span>
      </div>
    </aside>

    <div v-if="drawerOpen" class="scrim" @click="drawerOpen = false" />

    <div class="main-col">
      <header class="header">
        <button
          class="btn btn-ghost btn-icon"
          :aria-label="isPhone ? 'Open menu' : collapsed ? 'Expand sidebar' : 'Collapse sidebar'"
          :aria-expanded="isPhone ? drawerOpen : !collapsed"
          aria-controls="sidebar"
          @click="toggleSidebar"
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M3 6h18v2H3V6zm0 5h18v2H3v-2zm0 5h18v2H3v-2z" /></svg>
        </button>
        <div class="crumbs">
          <span class="faint crumb-root">OSG Admin</span>
          <span class="faint crumb-sep" aria-hidden="true">/</span>
          <span class="crumb-page">{{ pageTitle }}</span>
        </div>

        <div class="header-actions">
          <ThemeToggle />
          <div class="user-menu">
            <button class="user-btn" :aria-expanded="menuOpen" aria-haspopup="menu" @click="menuOpen = !menuOpen">
              <span class="avatar" aria-hidden="true">{{ initial }}</span>
              <span class="user-name">{{ username }}</span>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M7 10l5 5 5-5H7z" /></svg>
            </button>
            <div v-if="menuOpen" class="menu" role="menu">
              <div class="menu-head">
                <div class="faint small">Signed in as</div>
                <div class="menu-user">{{ username }}</div>
              </div>
              <RouterLink class="menu-item menu-item-plain" role="menuitem" :to="{ name: 'password' }">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 17a2 2 0 100-4 2 2 0 000 4zm6-9h-1V6A5 5 0 007 6v2H6a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V10a2 2 0 00-2-2zM9 6a3 3 0 016 0v2H9V6zm9 14H6V10h12v10z" /></svg>
                Change password
              </RouterLink>
              <button class="menu-item" role="menuitem" @click="signOut">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M10 17l1.4-1.4-2.6-2.6H20v-2H8.8l2.6-2.6L10 7l-5 5 5 5zM4 5h7V3H4a2 2 0 00-2 2v14a2 2 0 002 2h7v-2H4V5z" /></svg>
                Log out
              </button>
            </div>
          </div>
        </div>
      </header>

      <div v-if="DEMO" class="demo-bar" role="note">
        <strong>Demo</strong> · sample data, read-only ·
        <a href="https://osg.kudratov.uz" target="_blank" rel="noopener">About OSG</a> ·
        <a href="https://github.com/kudratov25/osg-words" target="_blank" rel="noopener">Source on GitHub</a>
      </div>
      <main class="content">
        <slot />
      </main>
    </div>
  </div>
</template>

<style scoped>
.demo-bar { padding: 8px 20px; font-size: 13px; color: var(--text-secondary, #555); border-bottom: 1px solid var(--border, rgba(127,127,127,.2)); background: var(--surface-2, rgba(127,127,127,.06)); }
.demo-bar a { color: inherit; text-decoration: underline; }
.shell { --side-w: 272px; --header-h: 64px; min-height: 100vh; }
.shell.collapsed { --side-w: 76px; }

/* ---------- sidebar ---------- */
.sidebar {
  position: fixed;
  inset: 0 auto 0 0;
  width: var(--side-w);
  display: flex;
  flex-direction: column;
  /* Same frosted glass as the cards: translucent gradient + blur, so the
     background color glow shows through. */
  background: linear-gradient(160deg, var(--chrome-a), var(--chrome-b));
  border-right: 1px solid var(--glass-border);
  box-shadow: inset -1px 0 0 var(--glass-border-soft);
  backdrop-filter: blur(30px) saturate(140%);
  -webkit-backdrop-filter: blur(30px) saturate(140%);
  z-index: 20;
  transition: width 0.2s ease;
  overflow: hidden;
}
.side-brand {
  flex: none;
  height: var(--header-h);
  display: flex;
  align-items: center;
  padding: 0 24px;
  border-bottom: 1px solid var(--glass-border-soft);
}
.collapsed .side-brand { padding: 0; justify-content: center; }
.brand-link:hover { text-decoration: none; }

.side-nav { flex: 1; overflow-y: auto; padding: 18px 14px; display: flex; flex-direction: column; gap: 18px; }
.nav-section { display: flex; flex-direction: column; gap: 4px; }
.nav-label {
  padding: 0 12px 4px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-3);
  white-space: nowrap;
}
.nav-link {
  display: flex;
  align-items: center;
  gap: 12px;
  height: 42px;
  padding: 0 12px;
  border-radius: var(--radius-sm);
  color: var(--text-2);
  font-weight: 600;
  font-size: 14px;
  white-space: nowrap;
}
.nav-link svg { flex: none; }
.nav-link:hover { background: var(--glass-fill); color: var(--text); text-decoration: none; }
.nav-link.active { background: var(--accent-tint); color: var(--accent); }

.collapsed .side-nav { padding: 18px 12px; }
.collapsed .nav-label { visibility: hidden; height: 1px; padding: 0; overflow: hidden; border-top: 1px solid var(--glass-border-soft); }
.collapsed .nav-section:first-child .nav-label { border-top: 0; }
.collapsed .nav-link { justify-content: center; padding: 0; }
.collapsed .nav-text { display: none; }

.side-foot {
  flex: none;
  padding: 14px 24px;
  border-top: 1px solid var(--glass-border-soft);
  white-space: nowrap;
}
.collapsed .side-foot { visibility: hidden; }

/* ---------- header ---------- */
.main-col { margin-left: var(--side-w); transition: margin-left 0.2s ease; min-width: 0; }
.header {
  position: sticky;
  top: 0;
  z-index: 15;
  height: var(--header-h);
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 20px 0 14px;
  background: linear-gradient(90deg, var(--chrome-b), var(--chrome-a));
  border-bottom: 1px solid var(--glass-border);
  backdrop-filter: blur(30px) saturate(140%);
  -webkit-backdrop-filter: blur(30px) saturate(140%);
}
.crumbs { display: flex; align-items: center; gap: 8px; min-width: 0; font-weight: 600; }
.crumb-page { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.header-actions { margin-left: auto; display: flex; align-items: center; gap: 8px; }

.user-menu { position: relative; }
.user-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 40px;
  padding: 0 8px 0 4px;
  border-radius: 999px;
  border: 1px solid var(--glass-border-soft);
  background: var(--glass-fill);
  color: var(--text);
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}
.user-btn:hover { border-color: var(--glass-border); }
.user-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-weight: 700;
  font-size: 13px;
  background: var(--accent-tint-strong);
  color: var(--accent);
}
.menu {
  position: absolute;
  right: 0;
  top: calc(100% + 8px);
  min-width: 200px;
  padding: 6px;
  border-radius: var(--radius-sm);
  background: var(--menu-bg);
  border: 1px solid var(--glass-border);
  box-shadow: var(--shadow);
  z-index: 30;
}
.menu-head { padding: 8px 10px 10px; border-bottom: 1px solid var(--glass-border-soft); margin-bottom: 4px; }
.menu-user { font-weight: 600; overflow: hidden; text-overflow: ellipsis; }
.menu-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 9px 10px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: var(--danger);
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  text-align: left;
}
.menu-item:hover, .menu-item:focus-visible { background: var(--danger-fill); outline: none; }
.menu-item-plain { color: var(--text); text-decoration: none; }
.menu-item-plain:hover, .menu-item-plain:focus-visible { background: var(--glass-fill); }

/* ---------- content ---------- */
.content {
  height: calc(100dvh - var(--header-h));
  overflow-y: auto;
  padding: 24px 28px 28px;
}

.scrim { display: none; }

@media (max-width: 800px) {
  .shell, .shell.collapsed { --side-w: 280px; --header-h: 56px; }
  .sidebar {
    transform: translateX(-105%);
    transition: transform 0.2s ease;
    background: var(--drawer);
    box-shadow: var(--shadow);
  }
  .sidebar.open { transform: none; }
  .scrim { display: block; position: fixed; inset: 0; background: var(--scrim); z-index: 19; }
  .main-col { margin-left: 0; }
  .header { padding: 0 12px 0 8px; }
  .crumb-root, .crumb-sep, .user-name { display: none; }
  .user-btn { padding: 0 4px; }
  .content { padding: 18px 14px 20px; }
}
</style>
