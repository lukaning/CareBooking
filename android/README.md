# EmBeLife — Android

Native Android port of the iOS SwiftUI app in the repository root, built with Kotlin and
Jetpack Compose.

## Status

| Area | State |
| --- | --- |
| Theme, colors, typography, assets | Ported |
| Data models and app state | Ported |
| Auth (sign in/up, code, password reset) | Ported |
| Onboarding (welcome, role, services, location) | Ported |
| Home (provider feed, filters) | Ported |
| Bookings (inbox, cancel, reschedule) | Ported |
| Book provider (multi-step sheet) | Ported |
| Edit booking, add/edit task, sub-tasks | Ported |
| Messages, Notification, Payment, Settings, Profile, Reviews | Not ported |

Unported tabs render a labelled placeholder so navigation stays intact.

## How iOS constructs map

| iOS | Android |
| --- | --- |
| `@Observable AppModel` | `AppViewModel` holding Compose snapshot state |
| `NavigationStack` + `navigationDestination` | `NavHost` + `composable` routes |
| `TabView` with `tabItem` | `Scaffold` + `NavigationBar` |
| `.sheet` | `ModalBottomSheet` |
| `FlowLayout` | `FlowRow` |
| `Font.scaledSystem` (`UIFontMetrics`) | `sp` units, which already scale with system font size |
| Asset catalog imagesets | `res/drawable-nodpi` with snake_case names |
| Asset catalog colorsets | `res/values/colors.xml` and `EmBeColors` |
| `CoreLocation` `LocationManager` | `LocationHelper` over platform `LocationManager` + `Geocoder` |

## Known substitutions

- **Map preview.** The iOS location step shows a non-interactive MapKit snapshot. The
  Android side draws the radius and pin on a `Canvas` so the module stays
  dependency-free. Swapping in a real basemap (Google Maps lite mode or MapLibre) only
  requires replacing `LocationMapPreview` in `LocationStep.kt`.
- **Distance slider.** The iOS slider uses `step: 1` over `1...250`. Compose renders a
  tick per step, and 249 ticks merge into a solid bar, so the Android slider is
  continuous and the value is rounded for display.
- **OTP entry.** iOS uses four focused fields. Android layers one hidden field over four
  drawn boxes, which is the same trick and behaves more reliably with the soft keyboard.
- **SF Symbols.** Mapped to the nearest Material icons; `message` became `Sms` because
  Material's plain `Message` glyph reads differently at tab-bar size.

## Building

The repo does not assume a system Android SDK. `setup-toolchain.sh` installs a
self-contained JDK-compatible SDK plus Gradle under `.toolchain/`, which is gitignored.

```bash
./android/setup-toolchain.sh
. .toolchain/env.sh
cd android
./gradlew assembleDebug
```

The APK lands at `android/app/build/outputs/apk/debug/app-debug.apk`.

## Running an emulator

```bash
. .toolchain/env.sh
sdkmanager "system-images;android-35;google_apis;arm64-v8a"
avdmanager create avd -n EmBeLife_Pixel7 \
  -k "system-images;android-35;google_apis;arm64-v8a" -d pixel_7 --force
emulator -avd EmBeLife_Pixel7
```

Leave that running, then in another shell:

```bash
. .toolchain/env.sh
cd android
./gradlew installDebug
adb shell am start -n com.embelife.app/.MainActivity
```

## Data

Like the iOS app, everything runs on in-memory sample data from `model/Models.kt`. There
is no networking layer yet, so the Supabase schema under `backend/` is unused on both
platforms.
