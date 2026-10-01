# ADR-0004: Stop Android recreating the app; restore it if it is killed

- **Status:** Accepted (2026-10-02)
- **Area:** Android manifest, router, media

## Context

Field reports:

1. "The app refreshes and reloads when the screen turns off and on."
2. "After uploading a photo on a worksheet, the app restarts."

The Dart side doesn't reload: no provider the session or router depends on changes on resume. Both symptoms match the **activity being recreated** (Flutter then starts again from the splash).
- Samsung devices change the display's **colour mode** on screen off/on and when the camera app takes over. `colorMode` was not in the activity's handled `configChanges`, so Android destroyed and rebuilt the activity.
- Separately, Android may **kill the process** while the camera is open (memory pressure). `image_picker` documents this, and it's worse when the app holds several full-resolution image decodes (our thumbnails did).

## Decision

1. **Handle the config changes ourselves:** add `colorMode|navigation|touchscreen|mcc|mnc` to `MainActivity`'s `android:configChanges` (Flutter re-lays-out on its own).
2. **State restoration:** `MaterialApp.router(restorationScopeId: 'app')`, `GoRouter(restorationScopeId: 'router')`, plus the shell and every branch. If Android kills the app, it comes back on the same screen.
3. **Remember the destination through the splash:** the redirect sends a cold start to `/splash?from=<where you were going>`, and after the session loads, back there (also through `/login`). This also fixes notification taps on a cold start landing on Home. Only in-app, non-public paths are honoured (no open redirect); see `test/core/router/redirect_test.dart`.
4. **Recover the photo:** before launching the picker, the target record is saved (`aumlux.pendingPhotoPick`). On return after a kill, `ImagePicker.retrieveLostData()` re-attaches the photo and the user sees "Recovered the photo you took…".
5. **Memory:** thumbnails decode at tile size (`cacheWidth`), not 1600px.

## Consequences

- Screen off/on and camera round-trips no longer rebuild the app on affected devices.
- When the OS does kill the app, the user returns to the same place and the photo isn't lost.
- To confirm on a specific phone: `adb logcat -b events | grep com.aumlux.app` should no longer show `am_create_activity` on screen on/off. (USB debugging authorisation is needed.)

## Alternatives considered

| Option | Why not |
|---|---|
| Cache the Flutter engine (`FlutterEngineCache`) | Doesn't help with process death, and adds lifecycle complexity. |
| In-app camera (`camera` package) | Avoids the external activity, but it's a large dependency and UX surface; the system camera is better on low-end phones. |
