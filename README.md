# Cassette Tape Player

A skeuomorphic cassette tape music player for Android, built with Flutter and connected to the Spotify SDK for full track playback. Holding-a-real-vintage-deck vibes — spinning reels, a rotary volume knob, a mechanical tape counter, and tactile transport buttons with haptics.

## Features

- **Hand-drawn cassette UI** — every element (shell, paper label, wound spools, hubs, capstan holes, screws) rendered with `CustomPainter`, no image assets
- **Live reel animation** — a frame-loop drives both hubs with eased speed ramps, a supply/take-up speed ratio, and subtle motor wobble; 6x wind for FF/REW
- **Spotify playback** — play, pause, and resume real tracks via the Spotify app through `spotify_sdk`
- **Recently played → tapes** — your Spotify history maps to a swipeable carousel of upright cassettes
- **J-card marquee header** — scrolling now-playing spine with side-A badge
- **Scrolling lyric reel** — center-focused lines that wind and rewind with the tape
- **Component panel** — slide volume tuner plus five piano-key transport buttons with spring press physics and haptics
- **Rotating hero transition** — tapes swing from their upright library pose into the player

## Tech Stack

- Flutter (Android target)
- [`spotify_sdk`](https://pub.dev/packages/spotify_sdk) — remote playback control
- `http` — Spotify Web API (recently played, album art)
- `flutter_secure_storage` — OAuth token storage
- `flutter_dotenv` — credential management
- `google_fonts` — vintage typography (VT323, Courier Prime, Special Elite)
- State: `ChangeNotifier` + `ValueNotifier` (no state-management library)

## Project Structure

```
lib/
├── main.dart              # entry, dotenv init, theme
├── models/                # CassetteTape model, TapeState enum
├── services/              # Spotify auth + Web API / SDK wrapper
├── painters/              # cassette body, reels, tape strip, VU meter
├── widgets/               # cassette card, transport, volume knob, counter, lyrics
├── screens/               # library carousel + player
└── utils/                 # color palette
```

## Getting Started

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure Spotify credentials**

   Create an app at the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard), add `cassetteplayer://callback` as a Redirect URI, then copy `.env.example` to `.env` and fill in your Client ID:
   ```
   SPOTIFY_CLIENT_ID=your_client_id_here
   SPOTIFY_REDIRECT_URI=cassetteplayer://callback
   ```

3. **Run**
   ```bash
   flutter run
   ```

   Requires the Spotify app installed on the device and an active Spotify Premium account for playback control.

## Notes

- Android `minSdkVersion` is 21 (required by `spotify_sdk`).
- Volume control has no SDK API in `spotify_sdk` 2.x — the knob is retained as a UI affordance and hook for future support.
