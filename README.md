# K-Pedal 🚴

A free, offline-first Flutter app for cycling Korea's national bicycle certification routes. Collect stamps at red certification booths, navigate on OpenStreetMap, and record your rides — no account, no paid APIs, no backend.

## Screenshots

> Coming soon

## Features

### Digital Passport
- All 10 major Korean cycling paths with 86 certification checkpoints embedded in the app
- GPS proximity detection — automatically prompts stamp collection when you reach a red booth
- Digital stamp grid per path, with gold medal awarded on completion
- **Korea Grand Slam** achievement for completing all paths
- Stamps persist locally (no account needed)

### Navigation
- Free OpenStreetMap tiles — no API key, no cost
- Full route polylines for every path loaded from embedded GPX data
- Live location with heading and "follow me" mode
- Tap any checkpoint to set it as your target — dotted line guides you there
- One-tap deep links to Kakao Maps or Naver Maps for each checkpoint

### Checkpoint Details
- Photo of each red booth
- Kakao Maps / Naver Maps links
- Nearest public transport stops

### Ride Recording (optional)
- Tap to start — zero battery drain until you choose to record
- Live stats in the top bar: elapsed time · distance · current elevation
- Elevation profile chart below the map, drawn in real time
- Pause / resume / stop
- Export as a standard `.gpx` file — share to Strava, Komoot, Garmin Connect, or any cycling app

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
| GPS | `geolocator` |
| Local storage | `hive` |
| Checkpoint data | Embedded JSON (parsed from Google My Maps KML) |
| GPX export | Custom builder, share via `share_plus` |
| State | `provider` |

## Data Sources

Checkpoint locations, route polylines, and transport stops sourced from [koreabybike.com](https://www.koreabybike.com) via Google My Maps export.

## License

MIT
