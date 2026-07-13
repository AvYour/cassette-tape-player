# Cassette Tape Player — Handoff / Status

Skeuomorphic cassette-tape music player in **Flutter (Android)** connected to **Spotify**.
Repo: https://github.com/AvYour/cassette-tape-player

---

## How to build & run

- Flutter SDK lives at `C:\src\flutter` (not on PATH). Use the full path:
  - `& "C:\src\flutter\bin\flutter.bat" run` (or `analyze`, `build apk`).
- **App won't launch from PATH** — always use the full `flutter.bat` path.
- Emulator used in dev: `emulator-5554` (has Spotify installed + Premium account).
- After adding/removing a **native plugin**, do a **full rebuild** (`flutter run` again), not hot reload.

### Spotify Developer Dashboard (developer.spotify.com/dashboard)
App is in **Development Mode**, so it needs:
- **Redirect URIs** (Settings → Redirect URIs): only **`cassetteplayer://callback`** is needed now.
  - (Earlier experiments added `cassettepkce://callback`, `cassetteplayer://auth`, `http://127.0.0.1:8888/callback` — these are NO LONGER used and can be removed.)
- **Android package**: `com.example.cassette_tape_player`
- **SHA1 fingerprint** (debug keystore): `02:EE:D9:1A:18:4E:25:B1:39:7B:6B:40:F1:AF:46:D8:1E:34:CD:B1`
- **User Management**: the Spotify account logged into the emulator must be added here (dev mode).

### `.env` (project root, gitignored)
```
SPOTIFY_CLIENT_ID=56b4168a47a34f4597766b2c16a24e4c
SPOTIFY_REDIRECT_URI=cassetteplayer://callback
```

---

## ⚠️ Git rule
**Do NOT `git push` until the user explicitly says "push".** Commit locally as work progresses; hold pushes.

### Unpushed local commits (as of handoff)
`origin/master` is at `7199a0e`. Local `master` is ahead by these (newest first):
```
d499f29 Fix next/previous by driving playback from our own queue
84f597d Renew the Spotify token automatically
6432fd1 Revert to the Spotify SDK implicit-grant token
5510bbb Switch PKCE to a loopback redirect (reverted later)
514446d Connect playback before Web API auth so songs always play
e7ff905 Use Authorization Code + PKCE (reverted later)
c351131 Use a real button-press sound for the transport controls
90c3747 Use real cassette sound effects
02cc17e Add mechanical cassette start/stop sound effects
2f0db2a Hand the queue to Spotify and follow its track changes
```
When the user says push: `gh auth switch --user AvYour`, push with an inline credential
helper (see "Git push" below), then `gh auth switch --user relkeretaa`.

### Git push (two accounts on this machine)
`relkeretaa` is the default active `gh` account; `AvYour` owns the repo. To push:
```
gh auth switch --user AvYour
$token = (gh auth token).Trim()
git -c credential.helper= -c credential.helper="!f() { echo username=AvYour; echo password=$token; }; f" push origin master
gh auth switch --user relkeretaa
```
All commits must be authored as **AvYour**, with **no Claude co-author trailer or mention**.

---

## Architecture

Home is **`screens/cabinet_screen.dart`** — a filing cabinet of drawers (each drawer = a
Spotify playlist). Auto-connects to Spotify on open.

```
lib/
├── main.dart                      # entry, dotenv, CabinetScreen as home
├── models/
│   ├── cassette_tape.dart         # CassetteTape (body/label/stripe colors, lyrics, uri, durationMs), TapeState
│   └── playlist.dart              # Playlist (id, name, ownerId, accent, lazy tapes)
├── services/
│   ├── spotify_auth.dart          # getAccessToken (implicit grant) + connectToSpotifyRemote; token cached in secure storage
│   ├── spotify_service.dart       # ChangeNotifier: connect, playlists, search, playback, now-playing, demo sim
│   ├── lyrics_service.dart        # lrclib.net lyrics (synced LRC / plain)
│   ├── palette_service.dart       # album-art → colors + swatches (palette_generator)
│   └── sound_service.dart         # cassette SFX + button click (audioplayers)
├── painters/
│   └── cassette_tape_painter.dart # CassetteBasePainter / CassetteHubsPainter / CassetteFrontPainter (1:1 from reference)
├── utils/
│   ├── playback_math.dart         # pure position/lyric maths (poll gating, end detect) — unit-tested
│   ├── lru_cache.dart             # bounded LRU with negative caching (lyrics)
│   ├── image_pick.dart            # picks right-sized Spotify image (thumb vs full art)
│   ├── playlist_paging.dart       # /items page → tapes, true contextIndex, ghost filtering
│   └── grid_math.dart             # drawer grid rows/cols + row stagger windows
├── widgets/
│   ├── cassette_tape_view.dart    # full cassette (album art AS the body), rotating hero flight, ReelAngles
│   ├── cassette_spine.dart        # thin filed spine (album-art cap + cream label) for drawers
│   ├── cabinet_drawer.dart        # drawer FACE ONLY, seated in a dark opening; brass label card; WoodGrainPainter (public)
│   ├── mini_player_bar.dart       # Spotify-style now-playing bar (cabinet/search bottom)
│   ├── dynamic_background.dart    # animated album-color glow, transitions with lyric progress
│   ├── lyrics_view.dart           # center-focused scrolling lyric reel
│   ├── title_header.dart          # J-card marquee header
│   ├── skeuo_button.dart          # piano-key transport buttons (haptic + click sound)
│   ├── eject_button.dart, volume_tuner.dart, tape_color_builder.dart, vintage_background.dart
└── screens/
    ├── cabinet_screen.dart        # home = "THE DEN", a 1985 room at dusk (wallpaper_painter):
    │                              #   poster on the wall = now-playing art; pinned paper note = status;
    │                              #   tape_shelf.dart = playlists (stylized spines, brass plaques);
    │                              #   desk_deck.dart = living mini-player (reels spin; tap → player)
    │                              #   + bakelite radio (tap → search). Starter-mixtape shelf offline.
    │                              #   Shelf tap = POV route (rotateX w/ easeOutBack settle) into:
    ├── drawer_screen.dart         # top-down INTO the box: wood rim + painted felt, tapes in recessed
    │                              #   slots (5/row, GridMath), staggered settle-in, press-lift, red
    │                              #   now-playing LED, pull-down-to-shuffle (ShufflePull)
    ├── search_screen.dart         # live Spotify search (rows w/ art) + mini-bar
    └── player_screen.dart         # the player (reels, lyrics, panel, dynamic bg, queue playback)
```
Note: `widgets/cabinet_drawer.dart` (drawer-face design) is no longer used by the home
screen but is kept with its widget tests in case the cabinet concept returns.

`third_party/spotify_sdk/` — **vendored** copy of spotify_sdk 3.0.0 with the dead Flutter v1
embedding (`PluginRegistry.Registrar`) stripped so it compiles; wired via `dependency_overrides`
in `pubspec.yaml`. Do not delete.

---

## Key behaviors & gotchas

### Playback (Spotify App Remote) — rewritten for reliability
- `spotify_service.playQueue(queue, index)` plays **only the track's exact URI**
  (`SpotifySdk.play(spotifyUri:)`). We do **NOT** inject the queue into Spotify (it polluted the
  user's queue) and we do **NOT** use `skipToIndex` on a playlist context: Spotify's playable
  context order can differ from the Web API item order (unavailable/local "ghost" tracks), so an
  index maps to the WRONG song. Playing the URI is unambiguous.
- **Auto-advance is driven by us**, in demo AND connected mode: the tick detects end-of-track via
  `PlaybackMath.reachedEnd` and calls `_advanceToNext` (a single URI won't auto-advance in Spotify).
- Tapping a cassette **auto-plays** it (no separate PLAY press); `_goToIndex` handles play + state.
- Player **follows Spotify's current track** (`_followSpotify`) only once THIS screen is driving
  playback (`_audioStarted`) and outside a self-change guard window (`_ignoreFollowUntil`, ~2–3s)
  — otherwise a stale/old URI would bounce the display to the wrong tape.
- **Next/Prev** drive our own queue via `_goToIndex`. **Eject** = stop + clear mini-bar.
  **Back** = keep playing + show mini-bar.
- Playlist loading filters out **episodes and `is_playable == false` ghosts** (`market=from_token`
  makes Spotify populate `is_playable`); see `utils/playlist_paging.dart`.

### Position / lyrics sync (important)
- Playback position is **anchored to wall-clock time** (`_anchor`, `_anchorWall`), NOT tick
  accumulation — so it stays correct while the app (ticker) is backgrounded.
- Position is re-synced by **polling `getPlayerState`** — but only when `PlaybackMath.shouldReanchorPoll`
  allows (every ~3s AND past the self-change guard). Polling right after a self-driven track change
  would anchor to the OLD track's stale position and cascade-skip tracks.
- Synced lyrics (lrclib LRC) map `_positionMs` → line by timestamp, nudged by `_lyricLagMs` (~300ms)
  so lines land as they're sung. The per-frame lookup uses `PlaybackMath.lyricLineIndex` with a
  forward-scan hint (cheap). Lyrics are **cached** (`LyricsService` + `utils/lru_cache.dart`, incl.
  negative caching) so reopening a tape is instant.

### Performance notes
- Pure playback/lyric maths live in `utils/playback_math.dart` (unit-tested in `test/`).
- Thumbnails: `CassetteTape.albumThumbUrl` (small Spotify image via `utils/image_pick.dart`) +
  `cacheWidth` on drawer/mini-bar/search images, and palette extraction uses the thumb — so
  scrolling the drawer doesn't decode 640px covers per spine.
- Spotify player-state subscription is single (cancelled before re-subscribe) and only
  `notifyListeners()` when the track/paused state actually changes.

### Auth / token (current = implicit grant)
- Uses `SpotifySdk.getAccessToken` (implicit grant, native SDK flow — custom scheme is fine).
- **No refresh token** (implicit grant limitation). Token cached ~55 min in secure storage.
- **Renewal is automatic**: re-fetched on every connect, and Web API GETs retry once after a
  401 by re-fetching the token (`spotify_service._authedGet`).
- Connect order: **App Remote (playback) FIRST**, then the Web API token — so songs always play
  even if the Web API auth fails.
- ⚠️ We tried **PKCE + refresh token** (commits e7ff905, 5510bbb) but **reverted** it: Spotify
  (April 2025) blocks custom-scheme redirects for browser auth; loopback/HTTPS works but was too
  fiddly. If revisiting refresh tokens, the path is **loopback `http://127.0.0.1:<port>` or
  HTTPS App Links**, not custom schemes.

### Spotify Web API (Feb 2026 changes — live)
- Playlist tracks endpoint: use **`/playlists/{id}/items`** (not `/tracks`); the track is under
  the **`item`** field (`track` is deprecated). Items only returned for playlists the user OWNS.
- **Search limit max is 10** (was 50).
- Only the user's **own** playlists are shown (filtered by owner id via `/me`).

### Cassette visuals
- The **album art image IS the cassette body** (`cassette_tape_view` layers art under the
  base painter which draws a translucent sheen + window/reels/label/screws on top). No per-track
  shell tint anymore.
- **Dynamic color** is used only for the **player background** (`dynamic_background.dart`) — album
  swatches that flow AND shift hue as the lyric progress advances.
- Drawers: the home cabinet is one carcass; **tapping a drawer pushes `DrawerScreen`** with a
  lean-over POV transition (perspective `rotateX` on the route). Inside, spines are filed in a
  **vertical 5-per-row grid** (`DrawerScreen.columns`), rows entering staggered (`GridMath`).
  The old horizontal coverflow carousel was removed (user preference).

### Sound / haptics
- `sound_service.dart` (audioplayers): `tapeStart` (insert.mp3), `tapeStop` (close.mp3),
  `eject` (eject.mp3) on a deck player; `buttonPress` (button_press.mp3) on a separate
  low-latency player. Files in `assets/sounds/` (real recordings, swappable).
- Haptics: transport buttons (`skeuo_button`), carousel scroll detents (`cabinet_drawer`).

---

## Open items / possible next steps
- Verify **next/prev** now works on device (last fix, commit d499f29).
- Confirm the token auto-renewal doesn't flash a login screen too often; if it does, reconsider
  loopback PKCE (with clearer UX).
- Sound files are synthesized-then-replaced with real recordings; user may tweak volumes/mapping.
- User has NOT approved pushing yet — hold all pushes until told.

---

## Auto-memory
Persistent notes live in
`C:\Users\USER\.claude\projects\C--Users-USER-Documents-Darrel-portfolio-cassette-tape-player\memory\`
(`MEMORY.md` is the index). Key memories: project status, "playlists/search must be live Spotify",
"don't push until told".
