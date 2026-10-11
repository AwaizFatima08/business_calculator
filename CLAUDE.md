# Business Calculator: Tape & GT

Flutter, **Android only**, portrait. Package `com.homilabs.businesscalc` — never change it after the first Play upload. Developer: HomiLabs.
Purpose: a simple, sleek large-key calculator for business use, daylight (light) theme only.

## Locked decisions (2026-10-12)
- No login, no accounts, no network (release APK requests **no permissions**).
- **Standard precedence** (× ÷ before + −): `2+2+2+2+2+2−6×4 = −12`. The whole expression stays on screen; the total is shown large at the bottom; earlier results scroll above as a tape.
- Exact decimal arithmetic (`package:decimal` / `rational`); results kept to 12 places, half-up; display rounding via the Decimal places setting.
- Keys: M+ M− MR MC, GT (tap recall, long-press clear), TAX+ / TAX− (rate in Settings, default 18%), %, +/−, 00, ⌫ (long-press = AC).
  M+/M− and TAX finish the calculation first (like =). Tax on an already-taxed result does not compound. GT sums every finished result (tax amends the last one).
- Percent: `a + b%` / `a − b%` = percent of everything to the left; `× b%`, `÷ b%` use b/100.
- Tape (history) saved on the phone (max 500), shareable/copyable as text. Expression, memory, GT and tape survive restarts.
- Ads later: every slot goes through `lib/ads/ads.dart` (same seam as Beam). Debug/profile builds show placeholders; release shows nothing.

## Code map
- `lib/core/expression.dart` tokens + evaluator · `calculator.dart` state machine (pure, unit-tested) · `format.dart` · `tape_text.dart`
- `lib/services/storage.dart` Settings + CalculatorStore (shared_preferences)
- `lib/views/` calculator page, tape (history) page, settings sheet, about sheet (`appVersion` must match pubspec — a test checks)
- `lib/widgets/` display and keypad

## Status
- 2026-10-12: v1.0.0 (versionCode 1) built and signed: `releases/v1.0.0-1/`. Tested on the Galaxy A12 (release cold start ~0.75 s).
- Privacy/terms: https://tools.homilabs.org/privacy#businesscalc and /terms#businesscalc (source `/mnt/storage/projects/homilabs_tools/site/`, uploaded to Hostinger).
- Play listing kit: `docs/play-listing.md`.
- Play Console (HomiLabs org account, Chrome profile slot `/u/1/`): app id 4975201122639423080, created 2026-10-12.
  Done: all App content declarations (no ads, no data collected, rating All ages, audience 16+, not gov/financial/health), Business category,
  contact homilabs.smc@gmail.com, store listing + graphics, all 181 countries, Production release draft "1.0.0 (1)" with notes.
  2026-10-12: AAB uploaded (Homi dragged it in; browser upload tool is capped at 10 MB), 11 changes **sent for review**,
  Production full rollout, managed publishing off (goes live automatically when approved). Next versionCode ≥ 2.
  When live: swap the tools.homilabs.org card from "Coming soon" to the Play link (commented in index.html) and re-upload.

## Commands
- Tests: `flutter test` (34).
- Graphics: `flutter test tool/store_screens_test.dart && flutter test tool/make_graphics_test.dart` (icon, feature graphic, screenshots — drawn in code).
- Release: `flutter build appbundle --release` and `flutter build apk --release` (signs via `android/key.properties` → `.secrets/businesscalc-upload.keystore`). Bump `version:` in pubspec **and** `appVersion` in `about_sheet.dart`; next versionCode ≥ 2.
- Backup: `bash scripts/backup.sh` (commit first; the GitHub layer refuses untracked/uncommitted files).

## Locations
- Local backup: `/mnt/storage/project_backups/Business_Calculator/`
- Google Drive: folder `1YyVmI5jiCNA0lyS6rZ_BgFP9Gycy7m08` (rclone remote `gdrive`)
- GitHub (**public**): `https://github.com/AwaizFatima08/business_calculator`. `.secrets/`, `android/key.properties` and `releases/` are gitignored.

## Machine notes
- Test phone: Samsung Galaxy A12 SM-A125F, Android 12, id `R58R61F3FDK` (720×1600, 360 dp wide — the narrowest layout target). Also attached: Mi 9 Lite `54bee463`.
- Debug builds start slowly on the A12 (~15 s first run); release ~0.75 s.
