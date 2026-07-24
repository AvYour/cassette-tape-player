# Cassette Tape Player

A Spotify-connected music player with two moods: a clean, glassy **daylight**
side for browsing, and a skeuomorphic **cassette deck** for playing — a
hand-drawn tape whose reels wind with the song, seven frosted transport keys,
VU needles, and lyrics that scroll past like a mixtape.

## Features

**Explore (home)**
- Your playlists on a slow vertical wheel; the row under the reading line rises
  onto a frosted-glass lozenge and is the only one that offers **Play**.
- Three shelves every account has, each with its own glyph: **Liked Songs** (♥),
  **Your Top Songs** (with a 4-week / 6-month / all-time window), and
  **Recently Played** (⏱).
- Pick a playlist, then a song — a plain track list, no drawers.

**Search**
- Across **songs, artists and albums** in one query.
- Before you type: your **recent searches** and your **top artists** as a
  jumping-off point. (Spotify retired its recommendation endpoints, so these
  stand in for "recommended".)
- Tap an album for its tracks, or an artist for their albums.

**The player**
- Hand-drawn cassette — the album art becomes the shell — with reels that wind
  as the track plays; **scrub by dragging the tape** across.
- Seven glass transport keys with spring-press physics and haptics, a glass
  volume tuner, and stereo **VU meters** that ride the music.
- A **♥ Like** toggle that saves the current track to your library.
- **Synced lyrics** from [lrclib](https://lrclib.net) when available.
- A **liner-notes sheet** with the track's full Spotify details — album, year,
  length, popularity, genres, follower count.

**Throughout**
- Glassmorphism: frosted panels that blur soft colour blooms over a lavender
  daylight gradient; the player's blooms lean toward the current song's colour.
- Real cassette sound effects (insert / eject / close) and button clicks.

## Spotify integration

- **Playback** runs through the **App Remote SDK** (`spotify_sdk`) so it drives
  the installed Spotify app directly.
- **Data** comes from the **Web API** (`http`): `/me`, `/me/playlists`,
  `/playlists/{id}/items`, `/me/tracks` (+ `/contains`, save/remove),
  `/me/top/{tracks,artists}`, `/me/player/recently-played`, `/search`,
  `/albums/{id}`, `/artists/{id}/albums`, `/tracks/{id}`, `/artists/{id}`,
  `/me/player/volume`.
- **Auth** is the SDK's implicit-grant `getAccessToken`. The token is cached
  with the scope set it was granted, and re-authorizes automatically when the
  app asks for more scopes rather than silently running on the old grant.
- **Scopes:** playback read/modify, currently-playing, playlist read
  (private + collaborative), library read + modify, top-read, recently-played.

## Tech stack

- **Flutter** (Android target)
- [`spotify_sdk`](https://pub.dev/packages/spotify_sdk) `3.0.0` — remote
  playback (vendored; see `dependency_overrides`)
- `http` — Spotify Web API · `flutter_secure_storage` — token storage ·
  `flutter_dotenv` — credentials · `palette_generator` — album-art colours ·
  `audioplayers` — sound effects · `google_fonts` — Plus Jakarta Sans for the
  daylight UI, plus mono/serif faces for the deck's instrument text and lyrics
- State: `ChangeNotifier` + `ValueNotifier` (no state-management library)
- Pure logic (wheel geometry, playback maths, tape winding, paging) lives in
  `utils/` and is covered by unit tests.

## Project structure

```
lib/
├── main.dart              # entry, dotenv, HomeScreen (Explore) as home
├── models/                # cassette_tape, playlist, browse (album/artist/search), track_info
├── services/              # spotify_auth, spotify_service, lyrics_service (lrclib),
│                          #   palette_service, sound_service
├── painters/              # cassette_tape_painter (+ legacy room painters)
├── widgets/               # glass, track_row, cassette_tape_view, skeuo_button,
│                          #   eject_button, title_header, lyrics_view, volume_tuner,
│                          #   vu_meter, liner_notes_sheet, ...
├── screens/               # home (Explore), playlist, album, artist, search, player
└── utils/                 # explore_theme, colors, carousel_math, playback_math,
                           #   tape_wind, ... (pure, unit-tested)
```

## Getting started

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure Spotify credentials**

   Create an app at the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard),
   add `cassetteplayer://callback` as a Redirect URI, then copy `.env.example`
   to `.env` and fill in your Client ID:
   ```
   SPOTIFY_CLIENT_ID=your_client_id_here
   SPOTIFY_REDIRECT_URI=cassetteplayer://callback
   ```

3. **Run**
   ```bash
   flutter run
   ```

   Requires the Spotify app installed on the device, and the account added to
   your app's allowlist while it is in Development Mode.

## Notes

- Android `minSdkVersion` is 21 (required by `spotify_sdk`).
- **Web API, current state (2026):** `/playlists/{id}/tracks` was renamed to
  `/items`; a playlist's tracks are only returned for playlists you **own or
  collaborate on**, so other people's playlists are hidden. `search` and
  `/artists/{id}/albums` cap `limit` at 10. Recommendation, audio-features,
  related-artists and featured/new-release endpoints are deprecated.
- **Premium:** the `/me/player/*` endpoints (e.g. volume) require Spotify
  Premium; free accounts may also be limited to shuffle rather than on-demand
  track playback on mobile.
- The earlier "1985 room" home (a cabinet of drawers) still exists in the tree
  but is no longer reachable — Explore replaced it.
