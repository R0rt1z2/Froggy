# Froggy 2.0 — Live Weather Screensaver: Technical Design

## Goal

Turn the existing "swipe through Weather Frog animations" demo into a **real Android
screensaver** (`DreamService`) that automatically displays the Froggy animation +
background matching the **current real weather and time of day** at the user's location.

- Weather source: **Open-Meteo** (no API key).
- Screensaver: native **`DreamService`** hosting the Flutter engine.
- The existing `.webp` backgrounds + `.flr` Flare animations are reused as-is.

---

## 1. Asset model

Assets are named `{scene}_{timeofday}_{condition}_{bg|frog}.{webp|flr}`.

| Axis       | Values                                      |
|------------|---------------------------------------------|
| scene      | `fields`, `hill`, `mushroom`                |
| timeofday  | `morning`, `day`, `sunset`, `night`         |
| condition  | `sunny`, `cloudy`, `hazy`, `rainy`, `snowy` |

Full grid = 3 × 4 × 5 = **60 combos. All 60 frog animations exist.**

**Only 3 backgrounds are missing** (frog exists, bg does not):
`fields_morning_rainy`, `fields_night_cloudy`, `hill_sunset_cloudy`.
(Also note: old code flagged `fields_night_rainy` animation as possibly broken — verify in phase 1.)

### Asset resolution & fallback
Do **not** hardcode the 60-entry list like the old `main.dart`. Instead:
1. At startup, read Flutter's bundled `AssetManifest.json` to know exactly which assets ship.
2. Given a target `(scene, timeofday, condition)`:
   - Frog: always exists → use directly.
   - Background: if `{scene}_{tod}_{cond}_bg.webp` is missing, fall back in order:
     a. same scene + tod, a "neutral" condition (`cloudy` → `hazy` → `sunny`),
     b. same scene, nearest tod (`morning↔day`, `sunset↔night`).
   - This reproduces the old manual patches (e.g. `fields_night_cloudy` → `fields_night_hazy_bg`)
     but data-driven, so it can never reference a non-existent file.
3. `scene` is **cosmetic** — not weather-driven. Rotate it periodically (e.g. change scene
   every N minutes, or pick per weather refresh) for variety.

---

## 2. Weather pipeline

### Location
- `geolocator` package. Request `whileInUse` permission **in the launcher app** (a Service
  cannot prompt). Cache last known lat/lon in `shared_preferences`.
- The screensaver itself only *reads* cached location + does a background fetch; it never prompts.

### Fetch (Open-Meteo)
`GET https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}`
`&current=weather_code,temperature_2m,is_day&daily=sunrise,sunset&timezone=auto`

- `weather_code` = WMO code → map to `condition`.
- `temperature_2m` → overlay.
- `daily.sunrise/sunset` → drives `timeofday` precisely.

### WMO code → condition
| WMO codes                      | condition |
|--------------------------------|-----------|
| 0, 1                           | sunny     |
| 2, 3                           | cloudy    |
| 45, 48                         | hazy      |
| 51–67, 80–82, 95–99            | rainy     |
| 71–77, 85, 86                  | snowy     |

### Local time → timeofday (using sunrise/sunset)
- `morning`: sunrise → sunrise + 2.5h
- `day`:     sunrise + 2.5h → sunset − 1h
- `sunset`:  sunset − 1h → sunset + 0.5h
- `night`:   otherwise
(Tunable constants. Fallback to fixed clock bands if daily data unavailable.)

### Caching & refresh
- Persist last `WeatherData` (+ timestamp) in `shared_preferences`.
- Refresh every ~20 min while active; on launch show cached immediately, then update.
- Fully offline-tolerant: stale data still renders a frog.

---

## 3. Flutter app architecture

### New dependencies (`pubspec.yaml`)
- `http` — Open-Meteo calls
- `geolocator` — location
- `shared_preferences` — cache location + last weather
- `intl` — clock/temperature formatting
- Keep `flare_flutter` **if it still builds** (phase 1 gate). If not → migrate `.flr`→`.riv`
  and switch to the `rive` package, OR pin an older Flutter. Decision deferred to phase 1.

### File layout
```
lib/
  main.dart                  # main() launcher entrypoint + dreamMain() entrypoint
  app.dart                   # MaterialApp (launcher: permission + preview + "enable screensaver")
  models/
    weather.dart             # Condition/TimeOfDay enums, WeatherData
  services/
    asset_catalog.dart       # reads AssetManifest, resolves (scene,tod,cond) -> bg+frog with fallback
    location_service.dart    # geolocator wrapper
    weather_service.dart     # Open-Meteo client + WMO/tod mapping
    cache.dart               # shared_preferences read/write
  state/
    weather_controller.dart  # orchestrates: load cache -> fetch -> pick asset -> notify
  ui/
    froggy_view.dart         # Stack(background, FlareActor, overlay) — shared by app & dream
    overlay.dart             # temperature + clock, subtle
```

`froggy_view.dart` is the **shared rendering widget** used both by the launcher app's preview
screen and by the `dreamMain()` entrypoint, so there's one source of truth for visuals.

### Two Dart entrypoints
```dart
void main() => runApp(const FroggyApp());          // launcher (permissions, preview, settings)

@pragma('vm:entry-point')
void dreamMain() => runApp(const FroggyScreensaver()); // bare fullscreen view, no chrome
```

---

## 4. DreamService native integration (the hard part)

Flutter normally runs in a `FlutterActivity`. A screensaver is a `DreamService` (a `Service`
with a window), so we host Flutter manually via `FlutterEngine` + `FlutterView`.

### `FroggyDreamService.kt`
```kotlin
class FroggyDreamService : DreamService() {
  private lateinit var engine: FlutterEngine
  private lateinit var flutterView: FlutterView

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    isFullscreen = true
    isInteractive = false
    isScreenBright = true

    engine = FlutterEngine(this)
    engine.dartExecutor.executeDartEntrypoint(
      DartExecutor.DartEntrypoint(
        FlutterInjector.instance().flutterLoader().findAppBundlePath(),
        "dreamMain"            // <-- the screensaver entrypoint
      )
    )
    flutterView = FlutterView(this)
    flutterView.attachToFlutterEngine(engine)
    setContentView(flutterView)
    engine.lifecycleChannel.appIsResumed()
  }

  override fun onDetachedFromWindow() {
    engine.lifecycleChannel.appIsInactive()
    flutterView.detachFromFlutterEngine()
    engine.destroy()
    super.onDetachedFromWindow()
  }
}
```

### Manifest registration
```xml
<service
    android:name=".FroggyDreamService"
    android:exported="true"
    android:permission="android.permission.BIND_DREAM_SERVICE">
    <intent-filter>
        <action android:name="android.service.dreams.DreamService"/>
        <category android:name="android.intent.category.DEFAULT"/>
    </intent-filter>
    <meta-data android:name="android.service.dream"
               android:resource="@xml/froggy_dream"/>
</service>
```
Plus `res/xml/froggy_dream.xml` (optionally points to a settings activity).

### Key caveats
- **Permissions:** plugins that need an `Activity` (geolocator's permission prompt) can't run
  inside the dream. Mitigation: the **launcher app** obtains location permission and caches
  lat/lon; the dream uses `getLastKnownPosition()` + cached data + a keyless HTTP fetch only.
- **Plugin registration** in a non-Activity engine is limited; keep the dream's plugin surface
  minimal (`http` + `shared_preferences` + `geolocator` last-known are fine; avoid anything
  needing UI/Activity).
- **Battery:** Flare renders on CPU. Screensavers typically run while docked/charging, so this
  is acceptable; still, pause/idle the animation appropriately on `onDreamingStopped`.

---

## 5. Phased delivery

| Phase | Outcome |
|-------|---------|
| **1. Build & modernize** | Toolchain (JDK 17, Flutter, Android SDK); bump Gradle/Kotlin/embedding; confirm `flare_flutter` builds (or migrate). **Old app runs unchanged on device.** |
| **2. Weather core** | Add deps; `asset_catalog`, `weather_service`, `location_service`, `weather_controller`; launcher app auto-selects the right frog from real weather (replaces swipe UI). |
| **3. Screensaver** | `dreamMain()` entrypoint + `FroggyDreamService.kt` + manifest/xml; appears in Settings → Screensaver and runs the live frog. |
| **4. Polish** | Temperature + clock overlay, scene rotation, smooth cross-fades on weather/tod change, settings (units, scene lock), app icon refresh. |

## 6. Open risks
1. `flare_flutter` may not compile on current stable Flutter → may force `.flr`→`.riv` migration
   or a pinned Flutter version. **Resolved/decided in phase 1.**
2. `FlutterView` lifecycle inside `DreamService` is not an officially documented path; may need
   iteration on engine attach/detach + texture rendering. **Phase 3 spike.**
3. Some OEM skins hide/limit the Daydream/Screensaver setting — document how to enable.
</content>
</invoke>
