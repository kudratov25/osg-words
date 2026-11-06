# OSG Admin panel

Vue 3 + Vite single-page app for managing words and viewing usage. Served
in production at **https://osg.kudratov.uz/panel/** (same origin as the API,
so no CORS). Talks to the backend's `/admin/*` endpoints with a Bearer token
from `POST /admin/login`.

## Develop

```bash
# backend on :8000 (in another terminal), with admin login configured
cd ../backend && uvicorn app.main:app --reload

cd admin-panel
npm install
npm run dev        # http://localhost:5173/panel/  (proxies /admin, /health, /content to :8000)
```

## Build

```bash
npm run build      # -> dist/  (static files; base path /panel/)
```

Serve `dist/` at `/panel/` with an SPA fallback to `/panel/index.html`.

## Structure

```
src/
  api.js          fetch wrapper: Bearer auth, error parsing, 401 -> back to login
  auth.js         session { token, expires_at, username } in localStorage
  router.js       routes + login guard
  format.js       dates (UTC-safe), numbers, external_id suggestion (de: der_schluessel, en: en.apple)
  languages.js    targets (de, en), sources (en, uz, ru), the 17 categories, pair labels
  styles.css      design tokens (match the Flutter app's dark glass theme)
  views/          Login, Dashboard, Words (per target language), Import (dry-run check
                  then apply), Coverage (translations per language + pair availability),
                  Devices, Reports (word issues from "Report a mistake"),
                  Change password (user menu; signs out every other session)
  components/     AppShell (sidebar), DailyChart (SVG), StatTile, BreakdownList,
                  Modal, WordForm (target fields + a tab per translation language),
                  Pagination, BrandMark
```
