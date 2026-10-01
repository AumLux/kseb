# ADR-0001: Maps with flutter_map + OpenStreetMap tiles

- **Status:** Accepted (2026-10-02)
- **Area:** client (`lib/core/maps/`)

## Context

The app needs maps in several places: setting a section office's location and geofence, choosing a worksite or pole location, showing where a photo was taken, and letting supervisors and managers see where their people checked in and out.

The client runs on ₹0/month infrastructure (see DEEP_DIVE §1.4). Google Maps needs a billing account and an API key, and its usage is metered. The product owner asked for a free, open-source option.

## Decision

- Use **`flutter_map`** (BSD-3, pure Flutter, works on Android and web) with **`latlong2`**.
- The default tiles are **OpenStreetMap's standard raster tiles** (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`). No key is required.
- Comply with the OSM [tile usage policy](https://operations.osmfoundation.org/policies/tiles/):
  - **Attribution:** "© OpenStreetMap contributors" is always visible on every map (`SimpleAttributionWidget`, linking to the copyright page).
  - **Identification:** a real User-Agent, `flutter_map (com.aumlux.app)`, via `userAgentPackageName`.
  - **Caching:** flutter_map's built-in tile cache is on (the default on mobile).
  - **No bulk downloads or offline prefetch.**
- **Providers are swappable without code changes:** `--dart-define=MAP_TILE_URL=…` and `MAP_ATTRIBUTION=…` (`MapConfig` in `lib/core/maps/app_map.dart`).
- There is **no geocoding or search** (Nominatim has its own strict usage policy). People place pins by dragging the map, or by taking a GPS fix.

All map UI goes through one module: `AppMap`, `MapPin`, `LocationPreview`, `MapViewPage`, `LocationPickerPage` (`pickLocation`) and `LocationField`. Previews are non-interactive, and a tap opens the full map.

## Consequences

- ₹0, no keys, no billing alerts.
- OSM tiles are community-funded. If usage grows (hundreds of active users panning daily), the policy expects us to move to a commercial or self-hosted provider. Options: MapTiler or Stadia (free tiers with a key), Carto basemaps, or self-hosted tiles. That's a one-line `MAP_TILE_URL` change.
- Without geocoding, there's no address search. The drag-to-place picker covers the real need (field locations rarely have usable addresses).
- The "Directions" button opens the phone's own maps app (`openInMaps`), so turn-by-turn navigation costs nothing either.

## Alternatives considered

| Option | Why not |
|---|---|
| Google Maps (`google_maps_flutter`) | Billing account and API key; metered; key in a public repo needs restrictions; web needs the separate JS SDK. |
| Mapbox | Free tier needs a key and a token in the app; the licence restricts some uses. |
| OpenFreeMap / vector tiles | No key and no limits, but vector rendering in Flutter needs extra packages and is heavier on low-end phones. Revisit if raster tiles become a problem. |
