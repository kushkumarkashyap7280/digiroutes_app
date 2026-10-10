# DigiRoutes

**Share your exact doorstep.** DigiRoutes turns a location into a precise
10-character [DIGIPIN](https://www.indiapost.gov.in/) (India Post's ~4 m grid
code) and wraps it in a shareable **address card** — entrance photos, delivery
notes, a phone number and a QR code — so visitors and delivery people always
find the right door.

- **Android app** (this repo): Flutter
- **Backend + website**: Next.js / MongoDB / Cloudinary →
  [`kushkumarkashyap7280/digiroute`](https://github.com/kushkumarkashyap7280/digiroute)
- **Live site / link host:** <https://digiroutes.vercel.app>
- **Download:** the latest `digiroutes-vX.Y.Z.apk` on the
  [Releases page](https://github.com/kushkumarkashyap7280/digiroutes_app/releases/latest)

---

## Documentation

| Guide | For | Format |
| --- | --- | --- |
| **User Guide** — install, create a card, share it safely, scan a QR, route planner, FAQ | Anyone using DigiRoutes | [PDF](DigiRoutes_User_Guide.pdf) · [Markdown](DigiRoutes_User_Guide.md) · also on the [website](https://digiroutes.vercel.app/guide/DigiRoutes_User_Guide.pdf) |
| **Project Guide** — problem, architecture, DIGIPIN maths, all 29 features, API, database, demo script | The project team, teachers, reviewers | [PDF](DigiRoutes_Project_Guide.pdf) · [Markdown](DigiRoutes_Project_Guide.md) |

Both PDFs are generated from the Markdown files next to them (`tools/guide-pdf/regen.sh`
in the maintainer's workspace); edit the `.md`, then regenerate. Documentation-only
commits don't trigger a release build (see *Tests, CI and releases*).

---

## Features

### Address cards
- **Create** a card in two taps: the **+** button opens the form and grabs your
  GPS location automatically; type a title and save.
- **Details:** title, human-readable address, up to **2 entrance photos**
  (max 4 MB each, uploaded straight to Cloudinary), **category**
  (Home · Work · Shop · Family · Other), **delivery note** (≤ 300 chars, e.g.
  "Ring twice, call before entering") and **contact phone**.
- **Edit / delete** any card (location is fixed once created).
- **Photos never pile up:** replacing or removing a photo, deleting a card,
  changing/removing your profile picture or deleting your account all delete the
  images from Cloudinary. If a save fails after photos were uploaded, the app
  discards those uploads (`/api/upload/cleanup`), and the server refuses to
  delete any image that isn't in the caller's own folder.
- **Favorites:** star a card; favorites float to the top.
- **Search & filter on the server:** search by title, address or DIGIPIN and
  filter by *All*, *Favorites* or a category. Both run on the backend, so they
  cover **all** your cards, not just the ones already loaded.
- **Pagination:** cards load 12 at a time (cursor-based) as you scroll; the
  saved-cards list in the route picker pages with a *Show more* button.
- Long-press a card for quick actions (favorite, edit, share, QR, delete).

### Sharing & opening
- **Private share links:** every card has its own random link,
  `https://digiroutes.vercel.app/c/<token>`, and the QR code contains that link.
  A DIGIPIN can be computed by anyone from a location, so it **never** unlocks
  a card's photos, phone or notes — only the link does. On each card the owner
  can **switch sharing off**, **reset the link** (old links and QR codes stop
  working), set an **expiry** (24 h / 7 days / never), **hide the phone number**
  and see how many times the link was opened. Links that are off, expired or
  reset all show the same "This link isn't available" screen.
- **QR code per card** — shown in a sheet, shareable as an image or copyable
  as a link. The code contains the card's web link.
- **Scan tab — three ways to open a card from a code:**
  1. point the **camera** at a QR,
  2. **pick a QR image from the gallery** (screenshot / saved QR / photo),
  3. **type or paste** a DIGIPIN or DigiRoutes link.
- **Rich share:** one tap sends the entrance photo, DIGIPIN, address, note,
  phone, Google Maps link and the DigiRoutes link together.
- **Call / WhatsApp** buttons on a card (when a phone number is set), plus
  **Navigate with Google Maps**.
- **Links open in the app** when it's installed (Android App Links for
  `https://digiroutes.vercel.app/c/<token>`, `/card/<PIN>` and `/digipin/<PIN>`); otherwise
  they open on the website, which also offers an "Open in app" banner on
  Android.

### Tools
- **Where to? (route planner):** a search bar on Home opens a screen where you
  pick a **start** and a **destination**. Each can be your **current location**,
  a **saved card**, a **DIGIPIN / DigiRoutes link**, **coordinates** (`28.61, 77.20`),
  a **QR code** (camera or gallery) or a **place name**. You get the **road route
  on a map, road distance and travel time** (drive / bike / walk), the
  **straight-line distance**, and a *Navigate in Google Maps* button. Straight-line
  distance is computed offline; road routes and place search use the free
  OpenRouteService API (key required, see below).
- **Home:** full-screen map, "Get My DIGIPIN" for your current location with
  copy / share / Google Maps link.
- **Compass:** point-to-location compass for a DIGIPIN or coordinates, paste
  coordinates from the clipboard.
- **Quick shortcuts:** long-press the app icon → *New card here* / *Scan QR*.

### Account & settings
- Sign up / log in; the session token is kept in the **Android Keystore**
  (`flutter_secure_storage`). Staying offline never logs you out.
- **Profile page:** profile photo upload (camera / gallery / remove, ≤ 4 MB),
  edit name, card & favorite counts.
- **Settings page:** theme (Light default · Dark · Auto), sound & haptics,
  check for updates, version, log out (always confirmed) and **Delete account**
  (password required; removes your profile, every card, all photos and your
  avatar — irreversible).
- **In-app updates:** the app compares its version with the latest GitHub
  release and offers to download and install the new APK.

### Look & feel
Light theme by default, soft orange brand, animated onboarding illustrations
drawn in code (no stock photos), slide/fade page transitions, floating bottom
bar with a raised **+**, glassy surfaces and spring animations.

---

## Navigation

```
 ┌─────────────────────────────────────────────────────┐
 │  Home     Scan     ( + )     Cards     Compass      │   bottom bar
 └─────────────────────────────────────────────────────┘
   map &     camera /   new      all your   compass
   my pin    gallery /  card     cards
             type code

 ☰ Sidebar:  Profile · Settings · Share DigiRoutes · Log out (bottom, confirmed)
```

The centre **+** is an action (creates a card), not a tab. The sidebar holds
only account items — nothing duplicates the bottom bar.

---

## Tech stack

| Area | Choice |
| --- | --- |
| UI | Flutter (Material 3), `flutter_animate`, `google_fonts`, `lucide_icons_flutter` |
| State | `flutter_riverpod` (`StateNotifier`s) |
| Routing | `go_router` (shell route with 4 tabs, deep links) |
| Networking | `http` through `ApiHttp` (timeouts + readable errors) |
| Storage | `flutter_secure_storage` (token), `shared_preferences` (settings, last-known profile) |
| Maps / routing | `flutter_map` + OpenStreetMap tiles, OpenRouteService (routes, place search) |
| Images | `image_picker`, `cached_network_image`, Cloudinary signed uploads |
| QR | `qr_flutter` (generate), `mobile_scanner` (camera + image analysis) |
| Sharing / launch | `share_plus`, `url_launcher`, `quick_actions` |
| Backend | Next.js (App Router) · MongoDB/Mongoose · Cloudinary · JWT (`jose`) |

---

## Project structure

```
lib/
├── main.dart                     App root, theme, launcher shortcuts
├── core/
│   ├── routing_service.dart      OpenRouteService: road route + place search (+ parsing)
│   ├── location.dart             Current GPS position with friendly errors
│   ├── api_http.dart             HTTP wrapper: timeout, NetworkException, error messages
│   ├── card_categories.dart      Home / Work / Shop / Family / Other
│   ├── card_share.dart           Rich share text + photo, QR image share
│   ├── constants.dart            API base URL (--dart-define), endpoints, keys
│   ├── router/app_router.dart    Routes, auth redirect, page transitions
│   ├── theme/app_theme.dart      Light/dark themes, colours, shared decorations
│   ├── update_checker.dart       GitHub-release update check + APK install
│   ├── map_widgets.dart · maps_share.dart · sound.dart
│   └── widgets/                  AppBackdrop, BrandMark, GlassContainer
├── data/
│   ├── models/                   AddressCard, AppUser
│   ├── repositories/             AuthRepository, CardsRepository (+ image upload)
│   └── local/                    TokenStorage (secure) + UserCache, SettingsStorage
├── logic/
│   ├── providers.dart            Riverpod providers: auth, cards, theme, sound
│   ├── digipin.dart              DIGIPIN encode/decode (offline)
│   ├── qr_link.dart              QR / pasted text → DIGIPIN parser
│   └── geo.dart                  Haversine distance, lat/lon parsing, formatting
└── ui/
    ├── shell/app_shell.dart      Bottom bar with raised "+"
    ├── screens/                  home, scan, route (Where to?), dashboard (Cards), compass, create/edit,
    │                             card detail, profile, settings, drawer, auth, onboarding
    └── widgets/                  QR sheet, start/end point picker, UserAvatar, logout confirmation
test/                             DIGIPIN, models, HTTP errors, QR parsing, onboarding smoke
```

### Data flow

```
Screen ──► Riverpod notifier ──► Repository ──► ApiHttp ──► Next.js API ──► MongoDB
  ▲              │                                              │
  └── state ◄────┘                         Cloudinary ◄─ signed upload (client → CDN)
```

Models are hand-written (`fromJson` / `toJson` / `copyWith`) — no code
generation is used.

---

## Backend API (summary)

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/api/auth/signup` · `/login` | Create account / sign in → JWT (rate-limited) |
| GET · PUT · DELETE | `/api/auth/me` | Current user · update name / avatar · delete account (password) |
| GET · POST | `/api/cards` | List own cards (cursor pagination, `q`, `category`, `favorite`; first page returns `total` + facets) · create |
| PUT · DELETE | `/api/cards/:id` | Update (favorite, category, note, phone, **sharing**: on/off, expiry, hide phone, reset link) · delete |
| GET | `/api/cards/shared/:token` | **Public** card lookup for a private share link (404 when off / expired / reset) |
| GET | `/api/cards/:id` | Own card incl. sharing settings |
| GET | `/api/cards/digipin/:pin` | Owner's own card, or an older card until its link is reset — never card data for strangers |
| POST | `/api/upload/sign` | Signed Cloudinary upload parameters |
| POST | `/api/upload/cleanup` | Discard uploads whose save failed (only unused images in the caller's folder) |

Auth is `Authorization: Bearer <token>` for the app (cookie for the website).

---

## Getting started

```bash
flutter pub get
flutter run                                       # uses https://digiroutes.vercel.app
flutter run --dart-define=API_BASE_URL=http://<your-lan-ip>:3000   # local backend
```

### Route planner key (free)
Road routes and place-name search need a free
[OpenRouteService](https://openrouteservice.org) key (no card). Without one the app
still works and shows straight-line distance.

```bash
# env.local.json (git-ignored):  { "ORS_API_KEY": "your-key" }
flutter run --dart-define-from-file=env.local.json
```

For CI releases add the key as the GitHub Actions secret **`ORS_API_KEY`**
(the workflow passes it to `flutter build` as a `--dart-define`). The key ends up
inside the APK, so use a free-tier key and never a paid one.

Run the backend from the `digiroute` repo (`npm run dev -- -H 0.0.0.0`, MongoDB
via `docker compose up -d`, `.env.local` with Mongo + Cloudinary + `SESSION_SECRET`).
**Scanner / native plugins must be tested in release mode** (`flutter run --release`): R8 shrinking can break them, see `android/app/proguard-rules.pro`.
A debug build can't be installed over a release-signed install (different
signing key) — uninstall first, or test with a release build.

Permissions used: location, camera (QR scan / photos), internet, install
packages (in-app update).

---

## Tests, CI and releases

```bash
flutter analyze
flutter test
```

GitHub Actions (`.github/workflows/build-apk.yml`) runs on every push to
`main`: tests → release build signed with the upload keystore (secrets
`RELEASE_KEYSTORE_BASE64`, `RELEASE_KEYSTORE_PASSWORD`, `RELEASE_KEY_ALIAS`,
`RELEASE_KEY_PASSWORD`) → publishes release **`vX.Y.Z`** with the file
**`digiroutes-vX.Y.Z.apk`**.

Pushes that only touch docs (`*.md`, `*.pdf`, `docs/`) are ignored by the workflow
(`paths-ignore`), so editing a README or guide never rebuilds or overwrites a release.

**Versioning rule:** every change that ships in the APK must bump `version:` in
`pubspec.yaml` (semver: patch = fix, minor = feature, major = breaking) — the
updater only compares the version name, so an unchanged version means installed
apps never see the update. Details in [`CLAUDE.md`](CLAUDE.md).

### App Links
`https://digiroutes.vercel.app/.well-known/assetlinks.json` (served by the
website) lists this app's package and signing-key SHA-256 fingerprints; the
manifest declares the matching intent filters. If the signing key ever changes,
add the new fingerprint there.

---

## Not done yet / ideas

- Real home-screen **widget** (launcher shortcuts exist; a widget needs native code)
- Receive a QR image via Android's **Share → DigiRoutes** (today: pick it from the Scan tab)
- Offline cache of cards and photos
- Admin panel (users, analytics, moderation) on the web
- Signed, short-lived photo URLs (today photo URLs are unguessable but not signed)
- Multiple captions per photo
- Change the package name from `com.example.digiroutes_app` before a Play Store release
- Per-ABI APKs to shrink the download (~75 MB universal today)
