import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// Served in production at https://osg.kudratov.uz/panel/ (same origin as the API).
const backend = 'http://127.0.0.1:8000'

// `npm run build:demo` (mode "demo", VITE_DEMO=1): read-only demo with static
// data from demo-public/, served at the site root, no backend needed.
export default defineConfig(({ mode }) => ({
  base: mode === 'demo' ? '/' : '/panel/',
  publicDir: mode === 'demo' ? 'demo-public' : 'public',
  build: { outDir: mode === 'demo' ? 'dist-demo' : 'dist' },
  plugins: [vue()],
  server: {
    proxy: {
      '/admin': backend,
      '/health': backend,
      '/content': backend,
    },
  },
}))
