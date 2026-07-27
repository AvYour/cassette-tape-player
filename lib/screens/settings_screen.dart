import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/spotify_service.dart';
import '../utils/explore_theme.dart';
import '../widgets/glass.dart';

/// Settings: the Spotify connection, and the few preferences the app actually
/// keeps. Reached from the "…" menu on Explore.
class SettingsScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  const SettingsScreen({super.key, required this.spotifyService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SpotifyService get svc => widget.spotifyService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Explore.bgTop,
      body: GlassBackdrop(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: svc,
            builder: (context, _) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 24, 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Explore.ink),
                        tooltip: 'Back',
                      ),
                      Text('Settings',
                          style: Explore.screenTitle.copyWith(fontSize: 24)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      _label('Account'),
                      _accountCard(),
                      _label('Your Top Songs'),
                      _rangeCard(),
                      _label('Search'),
                      _card(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title:
                              Text('Clear recent searches', style: Explore.chip),
                          subtitle: Text(
                            svc.recentSearches.isEmpty
                                ? 'Nothing saved'
                                : '${svc.recentSearches.length} saved',
                            style: Explore.caption,
                          ),
                          trailing: const Icon(Icons.delete_outline_rounded,
                              color: Explore.muted),
                          onTap: svc.recentSearches.isEmpty
                              ? null
                              : () {
                                  svc.clearRecentSearches();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Recent searches cleared')),
                                  );
                                },
                        ),
                      ),
                      _label('About'),
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Playback runs through the Spotify app on '
                                'this device; playlists, search and your '
                                'library come from the Spotify Web API.',
                                style: Explore.caption.copyWith(height: 1.5)),
                            const SizedBox(height: 8),
                            Text('Artist biographies come from Wikipedia.',
                                style: Explore.caption.copyWith(height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 16, 0, 8),
        child: Text(text.toUpperCase(),
            style: Explore.caption.copyWith(letterSpacing: 1.5)),
      );

  Widget _card({required Widget child}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: GlassPanel(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child,
        ),
      );

  Widget _accountCard() {
    final connected = svc.isConnected;
    return _card(
      child: Row(
        children: [
          Icon(
            connected ? Icons.check_circle_rounded : Icons.link_rounded,
            color: connected ? const Color(0xFF1DB954) : Explore.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(connected ? 'Spotify connected' : 'Not connected',
                    style: Explore.chip),
                const SizedBox(height: 2),
                Text(
                  svc.isLoading
                      ? 'Connecting…'
                      : connected
                          ? (svc.hasWebApi
                              ? 'Playback and library'
                              : 'Playback only — no Web API token')
                          : 'Connect to load your playlists',
                  style: Explore.caption,
                ),
              ],
            ),
          ),
          if (!connected)
            TextButton(
              onPressed: svc.isLoading ? null : svc.connectToSpotify,
              child: Text('Connect',
                  style: Explore.chip.copyWith(color: const Color(0xFF1DB954))),
            ),
        ],
      ),
    );
  }

  Widget _rangeCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Which window Explore shows by default', style: Explore.caption),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final r in TopRange.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => svc.topRange = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: svc.topRange == r
                            ? Explore.ink
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: svc.topRange == r
                              ? Colors.transparent
                              : Explore.hairline,
                        ),
                      ),
                      child: Text(
                        r.label,
                        style: Explore.caption.copyWith(
                          fontSize: 11.5,
                          fontWeight: svc.topRange == r
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: svc.topRange == r
                              ? Colors.white
                              : Explore.muted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
