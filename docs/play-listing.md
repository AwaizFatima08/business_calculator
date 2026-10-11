# Business Calculator: Google Play listing kit (v1.0.0)

Copy-paste values for Play Console. v1.0.0 (versionCode 1) ships **without ads**.
When an ad SDK is added, update the items marked **[ADS]** before that release goes out.

## App details
| Field | Value |
|---|---|
| App name (≤30) | `Business Calculator: Tape & GT` |
| Package | `com.homilabs.businesscalc` (locked after first upload) |
| Default language | English (United Kingdom) |
| App or game | App |
| Free or paid | Free |
| Category | Business |
| Tags (suggested) | Calculator, Business, Productivity |
| Contact email | `homilabs.smc@gmail.com` |
| Privacy policy URL | `https://tools.homilabs.org/privacy#businesscalc` |
| Website (optional) | `https://tools.homilabs.org/#businesscalc` |

## Short description (≤80)
```
Big-key calculator: see every figure, M+ M− MR, GT, tax keys & a saved tape.
```

## Full description (≤4000)
```
Business Calculator is a clean, large-key calculator built for shops, offices and anyone who adds up figures all day. No account, no sign-in, nothing to set up. Open it and calculate.

SEE EVERY FIGURE
• The whole calculation stays on screen as you type, for example 2 + 2 + 2 + 2 + 2 + 2 − 6 × 4
• The total updates live at the bottom in large, easy-to-read figures
• Earlier results scroll above like a paper tape, so you can check your work at a glance
• Standard maths rules: × and ÷ before + and −

BUSINESS KEYS
• M+, M−, MR and MC memory keys
• GT (Grand Total) adds up every result — tap to use it, long-press to clear
• TAX+ adds tax and TAX− takes it out of a tax-inclusive price, at the rate you choose (e.g. 18% GST)
• Business-style percent: 500 + 10% = 550, 500 − 10% = 450, 250 × 8% = 20
• 00 key, +/−, backspace

SAVED TAPE
• Every finished calculation is saved with the time
• Tap any result to reuse it
• Copy or share the whole tape as text (to chats, email or notes)
• Swipe to delete one entry, or clear the tape

MADE FOR DAYLIGHT
• High-contrast light theme that stays readable in sunlight
• Large keys that are easy to hit
• Exact decimal maths: 0.1 + 0.2 is exactly 0.3, no rounding surprises
• Choose decimal places (Auto, 0, 2, 3 or 4) and thousands separators

SMALL AND PRIVATE
• No login and no account
• Works fully offline
• Needs no permissions
• Your calculations stay on your phone
```
**[ADS]** Add a line such as "Business Calculator is free and supported by ads." when ads ship.

## Graphics (in `store-assets/`)
| Asset | File | Spec |
|---|---|---|
| App icon | `icon-512.png` | 512×512 PNG |
| Feature graphic | `feature-graphic-1024x500.png` | 1024×500 PNG |
| Phone screenshots | `screenshots/01-expression.png` … `05-settings.png` | 1080×1920 (9:16), 5 images |

Regenerate: `flutter test tool/store_screens_test.dart && flutter test tool/make_graphics_test.dart`.

## Store settings answers
- **Ads**: *Does your app contain ads?* → **No** for v1.0.0. **[ADS]** switch to **Yes** in the release that adds the SDK.
- **App access**: All functionality is available without special access.
- **Content rating** (IARC): category *Utility, Productivity, Communication, or Other*. Answer **No** to everything. Expected: Everyone / PEGI 3.
- **Target audience**: 18+ (and optionally 16–17). Not under-13s (keeps the app out of the Families policy, which restricts ad networks later).
- **News app**: No. **Government app**: No. **Financial features**: *My app doesn't provide any financial features* (it is a calculator; it handles no money, accounts or loans). **Health**: none.
- **Data safety** (v1.0.0): *Does your app collect or share any of the required user data types?* → **No**. (Sharing the tape is user-initiated through the Android share sheet, which Play does not count as collection.)
  **[ADS]** With AdMob: Device or other IDs, App interactions, Diagnostics — collected and shared for Advertising, Analytics, Fraud prevention; plus the `AD_ID` declaration.

## Release
- Upload `releases/v1.0.0-1/businesscalc-1.0.0-1.aab` (gitignored; also in the local and Drive backups).
- Play App Signing: accept Google-managed signing. Upload key: `.secrets/businesscalc-upload.keystore` (password in `.secrets/README.txt`; never in Git).
  Upload key SHA-256: `0F:4E:C4:00:AF:B0:6D:B7:03:D8:B2:F0:FB:67:18:5D:95:52:0B:76:F9:AB:9C:DD:2C:3C:6F:4F:96:03:00:A9`
- Release name: `1.0.0 (1)`. Release notes:
```
First release: large-key business calculator with on-screen tape, M+ M− MR MC, Grand Total, TAX+ / TAX− and a saved, shareable tape.
```
