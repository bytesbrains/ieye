# iEye icon set

All sizes derived from the approved master `brand/ieye-appicon.png` (the "i = lighthouse" mark). Use the appropriate file per placeholder.

## web/  — site favicon + PWA
| File | Use |
|------|-----|
| `favicon.ico` | classic browser favicon (bundles 16/32/48) |
| `favicon-16x16.png`, `favicon-32x32.png`, `favicon-48x48.png` | modern PNG favicons |
| `apple-touch-icon-180x180.png` | iOS Safari "Add to Home Screen" |
| `icon-192x192.png`, `icon-512x512.png` | PWA / Android web manifest (required) |
| `icon-64/96/128/256/384` | extra fallbacks |

**HTML `<head>` snippet:**
```html
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" type="image/png" sizes="32x32" href="/icons/favicon-32x32.png">
<link rel="icon" type="image/png" sizes="16x16" href="/icons/favicon-16x16.png">
<link rel="apple-touch-icon" sizes="180x180" href="/icons/apple-touch-icon-180x180.png">
<link rel="manifest" href="/icons/site.webmanifest">
```

## ios/  — native app icon (px)
`icon-20/29/40/58/60/76/80/87/120/152/167/180` (iPhone/iPad @1x–@3x) + `icon-1024` (App Store). Drop into the Xcode `AppIcon.appiconset` (or let Flutter/`flutter_launcher_icons` generate from the master).

## android/  — native launcher (mipmap densities)
`mipmap-mdpi 48 · hdpi 72 · xhdpi 96 · xxhdpi 144 · xxxhdpi 192` + `playstore 512`.

---
### Note (honest)
These are **faithful resizes of the approved concept master**, which has generous padding — so at the *tiniest* favicon sizes (16/32) the mark looks small. For production polish, the master should be **vectorized + tightened to fill the icon safe-area** (and the amber lamp's soft glow flattened for a true one-color version). That's a quick follow-up when building the app/site for real; these files are ready to use as placeholders now. See #41.
