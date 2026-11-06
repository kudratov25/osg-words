import { createRouter, createWebHistory } from 'vue-router'
import { isLoggedIn } from './auth'

const routes = [
  { path: '/login', name: 'login', component: () => import('./views/LoginView.vue'), meta: { public: true, title: 'Sign in' } },
  { path: '/', name: 'dashboard', component: () => import('./views/DashboardView.vue'), meta: { title: 'Dashboard' } },
  { path: '/devices', name: 'devices', component: () => import('./views/DevicesView.vue'), meta: { title: 'Devices' } },
  { path: '/words', name: 'words', component: () => import('./views/WordsView.vue'), meta: { title: 'Words' } },
  { path: '/import', name: 'import', component: () => import('./views/ImportView.vue'), meta: { title: 'Import' } },
  { path: '/coverage', name: 'coverage', component: () => import('./views/CoverageView.vue'), meta: { title: 'Coverage' } },
  { path: '/reports', name: 'reports', component: () => import('./views/ReportsView.vue'), meta: { title: 'Reports' } },
  { path: '/password', name: 'password', component: () => import('./views/PasswordView.vue'), meta: { title: 'Change password' } },
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

const router = createRouter({
  history: createWebHistory('/panel/'),
  routes,
})

router.beforeEach(to => {
  const loggedIn = isLoggedIn()
  if (!to.meta.public && !loggedIn) {
    return { name: 'login', query: to.fullPath !== '/' ? { redirect: to.fullPath } : {} }
  }
  if (to.name === 'login' && loggedIn) return { name: 'dashboard' }
})

router.afterEach(to => {
  document.title = to.meta.title ? `${to.meta.title} · OSG Admin` : 'OSG Admin'
})

export default router
