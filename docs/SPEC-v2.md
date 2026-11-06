# OSG v2 spec — language pairs, onboarding, minimal accounts, word reports

Single source of truth for the v2 work (language pairs, onboarding,
accounts, word reports). Backend, app, admin panel and content all build to THIS file.
If something here is wrong or missing, fix this file first.

## 1. Languages

| code | native name | English name | flag | has articles |
|---|---|---|---|---|
| `en` | English | English | 🇬🇧 | no |
| `de` | Deutsch | German | 🇩🇪 | yes: `der` / `die` / `das` |
| `uz` | O'zbekcha | Uzbek | 🇺🇿 | no (Latin script) |
| `ru` | Русский | Russian | 🇷🇺 | no |

- **Target** languages (words to learn): `de`, `en`.
- **Source** languages (translations + app interface): `en`, `uz`, `ru`.
- A pair is `source-target`, e.g. `uz-de`. Source ≠ target.
- Pairs shipped in v2: `en-de` (existing), `uz-de`, `ru-de`, `uz-en`, `ru-en`.
- A pair is **available** when its target has ≥ `MIN_PAIR_WORDS` words that
  have a translation in the source (env, default `100`). **Exception:
  `en-de` is always available** (installed v1.0 apps depend on it).

## 2. Categories (fixed keys)

Keys are English and stored on words. UI shows a translated label.

| key | uz | ru |
|---|---|---|
| Daily Life | Kundalik hayot | Повседневная жизнь |
| Work | Ish | Работа |
| Food | Ovqat | Еда |
| Common Verbs | Asosiy fe'llar | Основные глаголы |
| Travel | Sayohat | Путешествия |
| Emotions | Hissiyotlar | Эмоции |
| Adjectives | Sifatlar | Прилагательные |
| Time | Vaqt | Время |
| Money | Pul | Деньги |
| Health | Sog'liq | Здоровье |
| Weather | Ob-havo | Погода |
| Social | Muloqot | Общение |
| Home | Uy | Дом |
| Family | Oila | Семья |
| Education | Ta'lim | Образование |
| Shopping | Xarid | Покупки |
| Nature | Tabiat | Природа |

Difficulty: `beginner` | `intermediate` | `advanced`.

## 3. Content files (backend/content/)

`backend/content/de.json` and `backend/content/en.json`, same shape:

```json
{
  "target": "de",
  "words": [
    {
      "external_id": "der_schluessel",
      "term": "Schlüssel",
      "article": "der",
      "example": "Wo ist mein Schlüssel?",
      "category": "Daily Life",
      "difficulty": "beginner",
      "pronunciation": null,
      "translations": {
        "en": { "translation": "key", "example_translation": "Where is my key?" },
        "uz": { "translation": "kalit", "example_translation": "Kalitim qayerda?" },
        "ru": { "translation": "ключ", "example_translation": "Где мой ключ?" }
      }
    }
  ]
}
```

Rules:
- `de.json`: 500 words. **The existing 60 words keep their exact
  `external_id`, `term`, `article`, `example`, `category`, `difficulty` and
  English translation** (from `backend/app/seed_words.py`). Translations:
  `en`, `uz`, `ru` for every word.
- `en.json`: 500 words, `article: null`, ids prefixed `en.` (e.g.
  `en.apple`). Translations: `uz`, `ru` for every word.
- New German ids follow the existing style: `<article>_<word>` for nouns,
  `<word>` otherwise; lowercase; `ä→ae ö→oe ü→ue ß→ss`; spaces → `_`.
  Globally unique.
- `article` required for German nouns, `null` otherwise.
- `example`: one natural, short sentence in the target language using the word.
- `translation`: short (1–3 words, `/` for alternatives), max 200 chars.
- Everyday, useful vocabulary; spread across the categories; roughly
  60% beginner / 30% intermediate / 10% advanced.

## 4. Backend data model

- `Word`: `id`, `external_id` (unique), `lang` (target, indexed, default `de`),
  `term`, `article?`, `example`, `pronunciation?`, `category`, `difficulty`,
  `created_at`, `updated_at`.
  (Existing column `german` is renamed to `term`; existing `translation`
  moves to `WordTranslation(lang='en')`.)
- `WordTranslation`: `id`, `word_id` (FK, cascade), `lang`, `translation`,
  `example_translation?`; unique (`word_id`, `lang`).
- `PackMeta`: `id`, `target`, `source`, `version`, `updated_at`; unique
  (`target`, `source`). Existing single row becomes (`de`, `en`).
  - A change to a word's target-side fields bumps **every** pack of that target.
  - A change to a translation bumps only (`target`, that `source`).
- `DevicePing`: add `pair?` (`^[a-z]{2}-[a-z]{2}$`).
- `WordIssue`: `id`, `device_id`, `external_id`, `source`, `target`,
  `kind` (`wrong_translation` | `wrong_article` | `wrong_example` | `other`),
  `note?` (≤300), `status` (`open` | `resolved`), `created_at`.
- `User`: `id`, `email` (unique, lowercased), `name?`, `age_range?`,
  `created_at`. (`name`/`age_range` exist but are never asked for in v2.)
- `LoginCode`: `id`, `email`, `code_hash`, `expires_at` (10 min),
  `attempts` (max 5), `used_at?`, `created_at`.
- `AuthSession`: `id`, `user_id` (FK cascade), `token_hash`, `created_at`,
  `expires_at` (180 days), `revoked_at?`.
- `DeviceLink`: `user_id` (FK cascade), `device_id`; unique pair.
- Schema changes go through **Alembic** migrations (first migration =
  current production schema, so existing databases upgrade in place).

## 5. Public API

All existing behaviour without new parameters is unchanged (old app
versions keep working).

- `GET /content/pairs` →
  `{"pairs": [{"source": "uz", "target": "de", "words": 500, "version": 3}]}`
  (available pairs only).
- `GET /content/meta?source=en&target=de` → `{"version", "updated_at", "source", "target"}`.
  Defaults `source=en`, `target=de`. Unknown/unavailable pair → 404 (also for `/content/words`).
- `GET /content/words?source=en&target=de` →
  ```json
  {"version": 3, "source": "en", "target": "de",
   "words": [{"external_id": "...", "lang": "de", "term": "Schlüssel",
              "german": "Schlüssel", "article": "der",
              "translation": "key", "example": "...",
              "example_translation": "...", "pronunciation": null,
              "category": "Daily Life", "difficulty": "beginner",
              "created_at": "..."}]}
  ```
  Only words with a translation in `source`. `german` is an alias of `term`
  kept for app v1.0.x (always present).
- `POST /telemetry/ping`: unchanged + optional `pair`.
- `POST /feedback/word-issue`
  `{"device_id", "external_id", "source", "target", "kind", "note?"}` → 204.
  Max 20 per device per day (429 after). Unknown `external_id` → 404.

### Auth (minimal accounts — email code)

- Enabled only when an email sender is configured: env
  `EMAIL_BACKEND=smtp` (+ `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`,
  `SMTP_PASSWORD`, `SMTP_FROM`) or `EMAIL_BACKEND=console` (dev/tests: code
  printed to the log). Otherwise every `/auth/*` returns 503.
- `GET /auth/config` → `{"enabled": bool, "methods": ["email_code"]}` (always 200).
- `POST /auth/email/start` `{"email"}` → 204 always (no account
  enumeration). Rate limit: 3 per email per 15 min, 10 per IP per 15 min (429).
- `POST /auth/email/verify` `{"email", "code", "device_id?"}` →
  `{"token", "user": {"id", "email", "created_at"}}`. Creates the user on
  first verify. Links `device_id` if given. Wrong code → 400; expired / too
  many attempts → 400 with a clear `detail`.
- `GET /me` (Bearer user token) → `{"id", "email", "created_at"}`.
- `POST /auth/logout` → 204 (revokes this session).
- `DELETE /me` → 204: deletes the user, sessions, login codes, device links
  **and the pings of linked devices**; word issues from linked devices are
  kept but anonymized (`device_id = "deleted"`). Works even when sign-in is
  disabled (`/auth/*` → 503, `/auth/config` → `enabled: false, methods: []`).
  User tokens start with `osgu_`.
- User tokens are random opaque strings (stored hashed) — never valid for `/admin/*`.

## 6. Admin API (Bearer admin token or X-Admin-Key, as today)

- `GET /admin/words?target=de` → `[AdminWord]` where AdminWord =
  `{"external_id", "lang", "term", "article", "example", "pronunciation",
    "category", "difficulty", "created_at", "updated_at",
    "translations": {"en": {"translation", "example_translation"}, ...}}`.
  No `target` = all words.
- `POST /admin/words` AdminWord-without-timestamps → 201 AdminWord (409 duplicate id).
- `PATCH /admin/words/{external_id}` partial; `translations` merged per
  language; `{"translations": {"uz": null}}` removes that language.
- `DELETE /admin/words/{external_id}` → 204.
- `POST /admin/import?dry_run=true|false` `{"words": [AdminWord-input]}`
  (upsert by `external_id`, same shape as content files) →
  `{"created", "updated", "unchanged", "errors": [{"index", "external_id", "error"}], "bumped": ["uz-de", ...]}`.
  Dry run writes nothing. **`dry_run` defaults to `true`.** Max 2000 words
  per request (413). Body may include `target` so a content file can be
  posted as-is. Validation: category ∈ the 17 keys; `article` ∈ der/die/das
  for `de`, `null` for `en`; translation languages ∈ sources ≠ word lang.
  The v1 word shape (`german`, `translation`) is still accepted.
  CLI: `python -m app.import_content [--apply] [files]` (dry run by default).
- `GET /admin/coverage` →
  `{"targets": [{"target": "de", "words": 500, "translations": {"en": 500, "uz": 500, "ru": 500}}],
    "pairs": [{"source", "target", "words", "available"}], "min_pair_words": 100}`.
- `GET /admin/word-issues?status=open` → list; `PATCH /admin/word-issues/{id}` `{"status"}`.
- `GET /admin/stats`: add `"pairs": [{"pair": "uz-de", "devices": 12}]` (from
  each device's latest ping with a pair) and `"users_total"`.
- `GET /admin/devices`: add `pair?` (latest).

## 7. App (Flutter)

- **Onboarding**: 3 steps (5 since v2.1: + level, work area) — I speak (en/uz/ru) → I
  want to learn (targets available for that source) → how it works
  (preview + notification permission). Native names + flags. System
  language preselected. Saved in `shared_preferences`:
  `lang_source`, `lang_target`, `onboarding_done`. Existing installs
  (any word already learned/planned) skip onboarding with `en`/`de`.
- Built-in offline pair: `en-de` (bundled `assets/words_seed.json`,
  regenerated from `backend/content/de.json` with English translations —
  500 words). Other pairs download on pick.
- Drift schema v3: `Words.lang` (default `de`), rename `german` → `term`,
  add `exampleTranslation?`. Planner only uses words of the current target.
  Switching target: drop unrecorded plans from today on and replan.
  Switching source: force a content sync so translations update in place
  (progress kept).
- Flags: target flag everywhere the hard-coded 🇩🇪 was (Dart puts the flag
  into the widget payload `title`; native widgets stop adding their own).
- Interface language = source language (`en`/`uz`/`ru`), via
  `flutter_localizations` + ARB files; all UI strings, notification texts,
  category labels. Android widget strings in `values-uz`/`values-ru`.
- Telemetry pings include `pair`.
- "Report a mistake" on the word card → bottom sheet with the 4 kinds +
  optional note → `POST /feedback/word-issue`.
- Accounts (only when `GET /auth/config` says enabled): Settings → Account
  → email → 6-digit code → signed in (email shown), Sign out, Delete account
  (confirm). Token in secure storage. Nothing else asked.
