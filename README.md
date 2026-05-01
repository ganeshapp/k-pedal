# K-Pedal 🚴

A free, offline-first Flutter app for planning Korea's national bicycle certification routes. Browse the 10 major paths, view route shapes, distances, and elevation profiles, and collect stamps at red certification booths — no account, no GPS tracking, no paid APIs, no backend.

For navigation while riding, open any checkpoint in Kakao Maps or Naver Maps. For ride recording, use Strava, your Garmin watch, or any other cycling app — K-Pedal stays out of the way.

## Screenshots

> Coming soon

## Features

### Digital Passport
- All 10 major Korean cycling paths with 86 certification checkpoints embedded in the app
- One-tap stamp collection on each checkpoint screen
- Digital stamp grid per path, with gold medal awarded on completion
- **Korea Grand Slam** achievement for completing all paths
- Stamps persist locally (no account needed)

### Path Overview
- Each path card shows a route-outline preview with start (green) and end (red) markers
- Path detail screen embeds an OpenStreetMap view with the full route + numbered checkpoint pins
- Total path distance and per-leg distance between consecutive checkpoints
- Pre-computed elevation profile for the whole path (SRTM 30 m DEM, fetched once and bundled offline)

### Checkpoint Details
- Photos of each red booth
- Sticky toggle to choose Kakao Maps or Naver Maps as your default
- One-tap "Open in Maps" using the curated short link or the checkpoint coordinates
- "Find Nearby" — opens your chosen map app with categorical searches (lodging, convenience, toilet, bike repair, bus, train) anchored at the checkpoint

## Cycling Paths

| # | Path | Checkpoints | Distance |
|---|------|-------------|----------|
| 1 | Ara / Hangang Bicycle Path | 11 | ~277 km |
| 2 | Saejae Bicycle Path | 4 | ~100 km |
| 3 | Nakdonggang Bicycle Path | 12 | ~382 km |
| 4 | East Coast Bicycle Path | 17 | ~336 km |
| 5 | Ocheon Bicycle Path | 5 | ~102 km |
| 6 | Geumgang Bicycle Path | 6 | ~148 km |
| 7 | Seomjingang Bicycle Path | 8 | ~143 km |
| 8 | Yeongsangang Bicycle Path | 7 | ~137 km |
| 9 | Bukhangang & More Bicycle Paths | 4 | ~73 km |
| 10 | Jeju Fantasy Bicycle Path | 10 | ~234 km |

## Install

### Android
Download the APK for your device from the [Releases](https://github.com/ganeshapp/k-pedal/releases) page:

| File | Device |
|------|--------|
| `app-arm64-v8a-release.apk` | Most phones (2016+) |
| `app-armeabi-v7a-release.apk` | Older phones |
| `app-x86_64-release.apk` | Emulators / Intel |

You may need to enable **Install from unknown sources** in Android settings.

### iOS
Build from source with Xcode (requires Apple Developer account for device installation):
```
flutter build ipa
```

## Build from Source

**Requirements:** Flutter 3.29+, Android SDK or Xcode

```bash
git clone https://github.com/ganeshapp/k-pedal.git
cd k-pedal
flutter pub get
flutter run
```

Build release APKs:
```bash
flutter build apk --release --split-per-abi
```

## Tech Stack

| Concern | Solution |
|---------|----------|
| Maps | `flutter_map` + OpenStreetMap (free, no key) |
| Local storage | `hive` |
| Checkpoint data | Embedded JSON (parsed from Google My Maps KML) |
| Elevation data | Pre-computed via Open-Topo-Data SRTM 30 m, bundled into JSON (`scripts/precompute_elevations.py`) |
| State | `provider` |

## Data Sources

Checkpoint locations, route polylines, and transport stops sourced from [koreabybike.com](https://www.koreabybike.com) via Google My Maps export. Elevation samples generated once with [Open-Topo-Data](https://www.opentopodata.org/) (free, public SRTM 30 m endpoint) and shipped inside `assets/data/paths.json`.

## License

MIT
