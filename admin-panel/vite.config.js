import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// Served in production at https://osg.kudratov.uz/panel/ (same origin as the API).
const backend = 'http://127.0.0.1:8000'

export default defineConfig({
  base: '/panel/',
  plugins: [vue()],
  server: {
    proxy: {
      '/admin': backend,
      '/health': backend,
      '/content': backend,
    },
  },
})
