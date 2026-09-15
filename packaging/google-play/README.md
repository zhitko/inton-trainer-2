# Google Play listing assets

Files for the Play Console store listing of **Intonation Trainer 2 (Chinese)**
(`by.intoncore.intontrainer2.zh`). Later language editions are separate Play
apps, for example `by.intoncore.intontrainer2.en` with the listing name
**Intonation Trainer 2 (English)**.

| File | Role |
|---|---|
| `store-listing.md` | All required listing **text** (EN + RU), contact fields, category, What’s new, alt text |
| `icon-512.png` | Shared master Play icon (512×512 RGBA PNG) |
| `icon-512-zh.png` | Chinese listing icon (upload this for `.zh`). Also the source for the Android launcher icons in `android/res/` |
| `feature-graphic-zh.png` | Upload-ready Chinese-edition feature graphic (1024×500, 24-bit sRGB PNG, no alpha) |
| `feature-graphic-zh.svg` | Editable vector source for the feature graphic; do not upload this file |
| `screenshots/phone/` | 6 portrait phone captures (`1080×2400`) used on the Play listing |
| `screenshots/tablet7/` | 6 portrait 7-inch tablet captures (`1200×1920`) used on the Play listing |
| `screenshots/tablet10/` | 6 portrait 10-inch tablet captures (`1600×2560`) used on the Play listing |
| `screenshots/README.md` | Filename-to-screen index for those captures |

Launcher icons for the APK/AAB are generated from `icon-512-zh.png` into `android/res/` (legacy, round, and adaptive foreground).

Later editions copy the master, for example `icon-512-en.png`.

## Paste order

1. Open **Grow users → Store presence → Main store listing**.
2. Copy the English name, short description, and full description from
   `store-listing.md`.
3. Add a **Russian** translation and paste the RU fields.
4. Upload `icon-512-zh.png`.
5. Upload `feature-graphic-zh.png`.
6. Upload the phone, 7-inch, and 10-inch screenshots from `screenshots/`
   (index in `screenshots/README.md`).
7. Open **Store settings** and fill category, tags, email, and website.
8. Paste the privacy-policy URL in **App content** / **Data safety**:
   https://intontrainer.by/intontrainer2policy.html

See `scripts/android_build_guide.md` for the rest of the Play readiness checklist.
