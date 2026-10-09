# DigiRoutes app — working rules

## Version bump on every change (required)

The in-app updater (`lib/core/update_checker.dart`) compares the installed
version name with the latest GitHub release tag, and CI
(`.github/workflows/build-apk.yml`) builds that tag from the `version:` line in
`pubspec.yaml` — **the `+build` number is ignored**. If the version name does
not change, installed apps never see the "Update available" prompt, and the
release is silently overwritten.

So every change that will be merged to `main` MUST bump `version:` in
`pubspec.yaml` in the same branch/PR, using semantic versioning (`MAJOR.MINOR.PATCH+BUILD`):

| Change | Bump | Example |
| --- | --- | --- |
| Bug fix, copy/UI tweak, test or CI fix that ships in the APK | PATCH | 1.2.0 → 1.2.1 |
| New feature or noticeable user-facing change (new screen, favorites, deep links) | MINOR (reset PATCH to 0) | 1.2.1 → 1.3.0 |
| Breaking change: data/API incompatibility, removed features, major redesign, new signing key | MAJOR (reset MINOR and PATCH to 0) | 1.3.0 → 2.0.0 |

- Always increment `+BUILD` by 1 as well (e.g. `1.2.0+4` → `1.2.1+5`), even for a patch.
- Decide the level from the *largest* change in the PR; if unsure, ask.
- Docs-only or repo-only changes that do not affect the APK (README, CLAUDE.md,
  workflow tweaks that don't change the app) do not need a bump.
- Releases must stay signed with the same upload keystore, or installed apps
  cannot update in place.
- Before pushing: run `flutter analyze` and `flutter test` (CI runs the tests and
  a release build), and mention the new version in the commit/PR message.

## Test native-plugin features on a *release* build

Flutter release builds run R8 (code shrinking/renaming). Plugins that start
through reflection — currently the QR scanner (`mobile_scanner` → ML Kit +
CameraX) — can work in debug and then crash in release (v1.3.0: scan failed
with a `NullPointerException` in obfuscated code). Keep rules live in
`android/app/proguard-rules.pro`.

- After adding or upgrading a plugin with native code, run
  `flutter run --release` (or install the CI APK) and exercise that feature.
- If something fails only in release, check `adb logcat` for a
  `NullPointerException`/`ClassNotFoundException` in obfuscated frames and add
  keep rules before considering `isMinifyEnabled = false`.
