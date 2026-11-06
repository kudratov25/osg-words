# OSG — development guide

How the pieces work and how to run them. For the overview see the [README](../README.md).

## Layout

```
osg/
├── app/          Flutter client (Dart) — the actual product
├── backend/      FastAPI service (Python) — content, telemetry, reports, accounts, admin API
├── admin-panel/  Vue 3 + Vite admin panel, served at /panel/ (see admin-panel/README.md)
├── landing/      Static website at https://osg.kudratov.uz/
└── docs/         SPEC-v2.md (v2 decisions: pairs, accounts, reports)
```

## app/ — Flutter client

Local-first: SQLite via Drift, no network required to use it. Accounts are
optional (Settings → Account, only shown when the server enables them).

```
lib/
├── main.dart                       Entry point, DI wiring (Provider), init sequence
├── data/
│   ├── repository.dart             All app logic: word selection, reminders, history/streak
│   ├── languages.dart              Language codes, native names, flags, articles, pairs
│   └── db/
│       ├── tables.dart             Drift schema (v3): Reminders, Words (term + lang),
│       │                           FavoriteWords, LearnedWords, WordPlans, NotificationLogs
│       └── app_database.dart       Drift database + v1/v2 → v3 migrations (generated: .g.dart)
├── l10n/                           app_en/uz/ru.arb (~150 strings) + generated code, l10n.dart helpers
├── services/
│   ├── api_config.dart             Backend URL (from --dart-define), timeouts, appVersion
│   ├── language_settings.dart      Current pair (I speak / I'm learning), onboarding flag, switching
│   ├── content_sync.dart           Once-a-day word download per pair from /content/*
│   ├── auth_service.dart           Email-code sign-in, token in flutter_secure_storage
│   ├── feedback_api.dart           "Report a mistake" → /feedback/word-issue
│   ├── device_id.dart              Anonymous device UUID
│   └── telemetry.dart              Anonymous pings to /telemetry/ping (honors Settings opt-out)
├── notifications/
│   ├── notification_service.dart   Thin wrapper over flutter_local_notifications (OS calls only)
│   ├── scheduler.dart              Decides WHAT to schedule & merges reminders+vocab
│   ├── recurrence.dart             Pure date math: next-occurrence for once/daily/weekdays/weekly/monthly
│   └── widget_sync.dart            Pushes today's words to the native Home/Lock Screen widget
├── screens/                        onboarding (3 steps), home, schedule, vocabulary, history,
│                                   settings (Languages, Account), reminder_form
├── widgets/                        root_scaffold (bottom nav), glass_container, word_card,
│                                   report_sheet, language_card, reminder_tile, stat_tile
└── theme/glass_theme.dart          Glass look: soft colour glows + translucent cards

assets/words_seed.json              500 en-de words, generated from backend/content/de.json
                                    by tool/build_seed.dart (the original 60 keep their ids)
assets/icon/icon.png                App icon master (1024², opaque) — see "App icon" below
assets/icon/icon_foreground.png     Android adaptive-icon foreground layer (transparent bg)

ios/OsgWidgetExtension/             Native WidgetKit extension (Lock Screen + Home Screen widget) — see below
android/app/src/main/kotlin/com/osg/osg_app/OsgWidgetProvider.kt
                                     Native Home Screen widget (RemoteViews) — see below
```

### Core mechanics

**Week-ahead scheduling** (`NotificationScheduler.refreshAll`, on every
app open/resume and after any reminder change): everything is scheduled
**7 days ahead** (`scheduleHorizonDays`), so word notifications, reminders
and the widget keep working all week even if the app is never opened.
- Words: `repository.planWords` keeps a per-day plan (`WordPlans` table,
  schema v2): 3 words/day at 08:00 / 12:00 / 18:00 (`vocabSlotMinutes`).
  A day's plan never changes once made, so notification, widget and app
  always agree. Selection: never-used words first, then words not used for
  `reviewCooldownDays` (7), then least recently used; never twice a day.
  A day only counts into `LearnedWords` once it has arrived. Switching the
  target language replans today's and later slots with the new language's
  words (a counted slot that gets replaced is un-counted first).
- Reminders: once / daily / weekdays / weekly / monthly, all derived from
  `recurrence.occursOn` (monthly on the 31st → last day of shorter months).
  Every occurrence in the 7 days is scheduled, not just the next one.
- `buildSchedule` (pure, unit-tested) merges a reminder within 15 min
  (`mergeWindowMinutes`) of a word slot into one notification at the
  reminder's time; caps at 60 pending (iOS allows 64); adds a final
  "open OSG" nudge the day after the schedule runs out.
- Notification ids are derived from the date (vocab `300M + day*10 +
  slot`, reminders `400M + (day%100)*100000 + id`, nudge `299999999`);
  anything pending that isn't in the new schedule is cancelled (incl. the
  old 100000+/800000+ ids). Runs are serialized.
- Without Android's exact-alarm permission it falls back to inexact
  timing instead of failing.
- Release builds need `android/app/proguard-rules.pro` (Gson keep rules):
  without it R8 breaks flutter_local_notifications with
  "Missing type parameter".

**History/streak**: `NotificationLogs` holds every scheduled notification
(no reliable OS "was it shown" callback exists for local notifications, so
`deliveredAt` = `scheduledAt`). Each refresh replaces the future rows, and
History only lists ones whose time has passed.
`currentStreakDays` counts consecutive days with ≥1 delivered notification,
not broken until a full day is missed.

### Screens (via bottom nav in `root_scaffold.dart`)

Home → Schedule → Vocabulary → History → Settings. First launch shows the
onboarding (I speak → I'm learning → notifications preview); installs that
already have progress skip it and keep en-de.

**Performance note:** don't put `BackdropFilter` (live blur) on cards, the
background or the nav bar. Each one is re-rendered on every scroll frame:
with them, scrolling ran at ~40 fps on a 120 Hz phone (every frame late);
without, 120 fps with no late frames. The glass look comes from translucent
gradients over the static background instead.

### Widgets: iOS Lock Screen + Android Home Screen

Both read the same data, written once from Dart, by `widget_sync.dart`
running inside `NotificationScheduler.refreshAll` (app launch + every
resume): *all* of today's words tagged with their slot minute
(08:00/12:00/18:00) — German word, translation, **and example sentence**
— saved as JSON via the `home_widget` package (`HomeWidget.saveWidgetData`
+ `HomeWidget.updateWidget`). Android has no lock-screen widget API at all
(Google removed it in Android 5.0), so the two platforms land on different
native surfaces:

**iOS — Lock Screen widget** (`ios/OsgWidgetExtension/OsgWidget.swift`):
a `TimelineProvider` reads the JSON and builds one timeline entry per slot.
WidgetKit then switches between them automatically at each slot's clock
time — this happens at the OS level, the app does **not** need to be
reopened during the day for the widget to advance from the 8am word to the
12pm word, etc. Reopening the app only refreshes *which* words today's
payload contains. Supports `accessoryRectangular`/`accessoryInline` (Lock
Screen) plus a bonus `systemSmall` Home Screen variant. `accessoryRectangular`
and `systemSmall` show word + translation + the example sentence (italic,
secondary/tertiary style); `accessoryInline` stays word + translation only
— it's a single OS-constrained text line next to the clock, no room for a
third field.
- The `OsgWidgetExtension` Xcode target + App Group entitlements (on both
  it and `Runner`) were added by script using the `xcodeproj` Ruby gem
  (bundled with CocoaPods) rather than the Xcode GUI — verified with
  `xcodebuild -list` and a standalone `xcodebuild … -target
  OsgWidgetExtension build`, which succeeds (`** BUILD SUCCEEDED **`).
- **Manual step still required before this runs on a device**: App Groups
  need a paid Apple Developer account. Open `ios/Runner.xcworkspace` in
  Xcode, pick your team for *both* the `Runner` and `OsgWidgetExtension`
  targets (Signing & Capabilities), let Xcode auto-provision the
  `group.com.osg.osgApp` App Group capability, then run on a real device (or
  iOS 17+ simulator) and add the widget from the Lock Screen editor.
  `DEVELOPMENT_TEAM` isn't set anywhere yet — signing has never been
  configured on this project.

**Android — Home Screen widget** (`OsgWidgetProvider.kt`, package
`com.osg.osg_app`): classic `AppWidgetProvider`/`RemoteViews` (via
`home_widget`'s `HomeWidgetProvider` base class), *not* Jetpack Glance —
kept to the simpler API since `home_widget`'s own Android module already
pulls in Glance transitively either way, so nothing was gained by using it
directly for a plain-text widget. RemoteViews has no OS-level scheduling
like WidgetKit's timelines, so `onUpdate` recomputes which slot is current
itself (mirrors `WidgetSync.currentWord`'s selection rule) every time it
runs: the OS-enforced periodic tick (`updatePeriodMillis`, 30 min minimum)
and every explicit `HomeWidget.updateWidget()` call from Dart. Tapping the
widget opens the app (`HomeWidgetLaunchIntent`). Shows word, translation,
and the example sentence (`widget_example`, italic, 3rd line — widget's
`minHeight`/`targetCellHeight` were bumped to fit it). No signing/account
needed — **this one is fully testable today**:
```bash
cd app
flutter build apk --debug   # verified: builds clean
flutter install             # or drag build/app/outputs/flutter-apk/app-debug.apk onto an emulator
```
then long-press the home screen → Widgets → OSG App to add it.

### App icon

User-supplied artwork (a frosted glass rounded-square with a glowing
speech-bubble + checkmark, neon blue on near-black) — not the hand-built
SVG glass-card/flag design from earlier iteration; that one was swapped out
once real artwork was provided.

- Source: `assets/icon/icon.png` = `assets/icon/icon_foreground.png`
  (currently identical — both 1024², opaque, no true alpha cutout; see
  caveat below).
- `adaptive_icon_background` in `pubspec.yaml` (`#03060D`) was sampled
  directly from the source image's own corner pixels so Android's adaptive
  background layer blends seamlessly behind the (non-transparent)
  foreground rather than showing a mismatched color at the edges.
- **Caveat**: because the foreground isn't a real alpha-cutout PNG (just
  the flat square with its own dark backdrop baked in), Android's adaptive
  icon parallax/mask effects won't cleanly separate the card from its
  background the way a true cutout would — it just looks right because the
  two background colors match closely. If Android launcher icon masking
  ever looks slightly off, that's why; fixing it properly means asking for
  (or cutting out) a transparent-background version of just the card.
- Generation config lives in `pubspec.yaml` under `flutter_launcher_icons:`.
  After replacing either PNG, regenerate every platform size with:
  ```bash
  dart run flutter_launcher_icons
  ```
  This writes iOS's `AppIcon.appiconset` (alpha stripped, per Apple's
  requirement — `remove_alpha_ios: true`) and Android's legacy `mipmap-*`
  icons + `mipmap-anydpi-v26/ic_launcher.xml` adaptive icon.

### Backend sync (content + telemetry)

On launch and every resume (in the background, never blocking startup):
- **Content sync** (`ContentSync.syncIfDue`): at most once per calendar day,
  `GET /content/meta`; if the server's pack version is newer than the last
  merged one, `GET /content/words` and `repository.mergeContentPack`. Merge
  inserts new words and updates edited ones *in place* (same local id, so
  progress/favorites survive); words deleted on the server are kept locally.
  Any failure is silent; the day is only marked synced on success, so it
  retries on the next open.
- **Telemetry** (`Telemetry.send`): `app_open` on launch/resume,
  `notif_tapped` when a notification is tapped (including cold start).
  Random UUID device id stored in `shared_preferences`. Skipped when the
  Settings "Share anonymous usage data" switch is off. `notif_delivered`
  is never sent: local notifications have no reliable "was shown" callback.

### Run it

```bash
cd app
flutter pub get
flutter run                                                  # offline, no backend
flutter run --dart-define=API_BASE_URL=http://<mac-ip>:8000  # with local backend
flutter test
```

Local backend on a USB-connected Android phone (works for release builds
too; no Wi-Fi/IP needed):
```bash
adb reverse tcp:8011 tcp:8011
flutter build apk --release --dart-define=API_BASE_URL=http://127.0.0.1:8011
adb install -r build/app/outputs/flutter-apk/app-release.apk   # -r keeps the app's data
```
On iOS, plain http to a LAN IP may be blocked by App Transport Security,
so test the local backend on Android, or use the deployed https URL.

**Before building a release, clear Flutter's build cache** (`rm -rf .dart_tool/flutter_build build/app/intermediates/flutter`): a release build can otherwise reuse stale compiled Dart code.

If a Gradle build gets killed (exit 137 = out of memory), stop leftover
daemons with `cd android && ./gradlew --stop` and retry; the heap is set in
`android/gradle.properties`.

Drift code is generated (`app_database.g.dart` already committed); if you
change `tables.dart`, regenerate with:
```bash
dart run build_runner build --delete-conflicting-outputs --force-jit
```

## landing/ — website 

Static HTML/CSS/JS, no build step, same glass design and day/night theme
as the app and admin panel. `index.html` (landing), `privacy.html`
(served at `/privacy` — needed for the Play Store listing; describes
exactly what the app/backend collect), `robots.txt`, `site/` (css, js,
favicon). Download buttons say "Coming soon" until store links exist.

Served by nginx from `/srv/osg-site` (`location = /`, `= /privacy`,
`= /robots.txt`, `^~ /site/`); all API paths are untouched. Deploy:
```bash
cd landing && COPYFILE_DISABLE=1 tar czf - --no-xattrs index.html privacy.html robots.txt site | \
  ssh <server> 'rm -rf /srv/osg-site.new && mkdir -p /srv/osg-site.new && tar xzf - --no-same-owner -C /srv/osg-site.new && rm -rf /srv/osg-site && mv /srv/osg-site.new /srv/osg-site'
```
If the app's data collection changes, update `privacy.html` too.

## backend/ — FastAPI service

Content (word packs per language pair) + anonymous telemetry + word reports
+ optional email-code accounts + admin API.

```
app/
├── main.py            App setup; on start: Alembic upgrade + seed if empty
├── config.py          Env settings (table below)
├── models.py          Word, WordTranslation, PackMeta (per pair), DevicePing, WordIssue,
│                      User, LoginCode, AuthSession, DeviceLink, AdminCredential
├── schemas.py         Request/response models + validation
├── languages.py       Sources (en, uz, ru), targets (de, en), pairs
├── packs.py           Pack version bump rules
├── security.py        Admin password hashing (scrypt), signed tokens, login throttle
├── emailer.py         Login-code email (smtp | console | off)
├── import_content.py  python -m app.import_content [--apply] [file]   (dry run by default)
├── set_password.py    python -m app.set_password [--reset]
├── migrate.py         Runs Alembic programmatically (migrations/versions/0001-0003)
└── routers/           content, telemetry, feedback, auth, admin
content/               de.json, en.json (500 words each with translations) + validate.py
tests/                 85 tests (pytest)
Dockerfile             Production image; listens on $PORT
```

### Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/health` | none | Liveness check |
| GET | `/content/pairs` | none | Pairs with enough words (`MIN_PAIR_WORDS`) |
| GET | `/content/meta?source=&target=` | none | Pack version of a pair |
| GET | `/content/words?source=&target=` | none | Full pack of a pair |
| POST | `/telemetry/ping` | none | Anonymous app_open / notif_tapped (+ pair) → 204 |
| POST | `/feedback/word-issue` | none | "Report a mistake" from a word card → 204 |
| GET | `/auth/config` | none | Are accounts enabled, which methods |
| POST | `/auth/email/start`, `/auth/email/verify` | none | Send / check a 6-digit code → user token |
| POST | `/auth/logout`; GET/DELETE `/me` | user token | Sign out; account info; delete account |
| POST | `/admin/login` | none | Panel login → admin token |
| POST | `/admin/password` | admin | Change the panel password (signs out other sessions) |
| GET/POST/PATCH/DELETE | `/admin/words[/{external_id}]` | admin | Word management |
| POST | `/admin/import?dry_run=` | admin | Bulk import (dry run by default) |
| GET | `/admin/coverage`, `/admin/stats`, `/admin/devices` | admin | Panel data |
| GET/PATCH | `/admin/word-issues[/{id}]` | admin | Reports inbox |

Admin auth: `Authorization: Bearer <token>` from `/admin/login` (panel) or
`X-Admin-Key: <ADMIN_API_KEY>` (scripts/curl). Every word change bumps the
affected pack versions, so phones pick it up on their next daily check.
Interactive docs: `/docs`.

### Environment variables

| Var | Default | Notes |
|---|---|---|
| `DATABASE_URL` | `sqlite:///./osg.db` | `postgres://…` accepted as-is |
| `ADMIN_API_KEY` | *(unset → key auth off)* | `python3 -c "import secrets;print(secrets.token_urlsafe(32))"` |
| `ADMIN_USERNAME`, `ADMIN_PASSWORD_HASH` | `admin`, *(unset → panel login off)* | From `python -m app.set_password`. A password changed in the panel is stored in the DB and wins; `--reset` removes it |
| `SECRET_KEY` | random per start | Signs admin tokens: set it, or every restart logs the panel out |
| `TOKEN_TTL_HOURS` | `12` | Admin session length |
| `MIN_PAIR_WORDS` | `100` | A pair is offered once it has this many translated words |
| `CONTENT_DIR` | `backend/content` | Seed/import source |
| `EMAIL_BACKEND` | *(unset → accounts off)* | `smtp` (needs `SMTP_HOST/PORT/USER/PASSWORD/FROM`, `SMTP_STARTTLS`) or `console` (dev: code printed to the log) |
| `AUTH_CODE_SECRET` | `SECRET_KEY` | Hashes login codes |
| `USER_SESSION_DAYS` | `180` | App account session length |
| `PORT` | `8000` | Set by the host in Docker |

### Run it locally

```bash
cd backend
source .venv/bin/activate          # or: python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
ADMIN_API_KEY=dev-key EMAIL_BACKEND=console uvicorn app.main:app --reload --host 0.0.0.0
python -m app.import_content --apply   # load content/de.json + en.json
pytest -q
python content/validate.py             # check the word files
```

`external_id` is a word's permanent key; never reuse or change it. German:
`article_word`, lowercase, ä/ö/ü/ß → ae/oe/ue/ss (e.g. `der_schluessel`);
English: `en.word` (e.g. `en.apple`).
