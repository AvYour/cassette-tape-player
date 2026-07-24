import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/models/playlist.dart';
import 'package:cassette_tape_player/screens/home_screen.dart';
import 'package:cassette_tape_player/services/spotify_service.dart';

void main() {
  Widget host(SpotifyService svc) =>
      MaterialApp(home: HomeScreen(spotifyService: svc, autoConnect: false));

  testWidgets('lists every playlist with its owner', (tester) async {
    final svc = SpotifyService();
    addTearDown(svc.dispose);
    await tester.pumpWidget(host(svc));
    await tester.pump();

    // Falls back to the starter mixtape until Spotify hands us real playlists.
    expect(find.text('Starter Mixtape'), findsOneWidget);
    expect(find.text('Cassette'), findsOneWidget);
  });

  testWidgets('only the focused row offers Play', (tester) async {
    final svc = SpotifyService();
    addTearDown(svc.dispose);
    await tester.pumpWidget(host(svc));
    await tester.pump();

    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('the drawer metaphor is gone from the home screen',
      (tester) async {
    final svc = SpotifyService();
    addTearDown(svc.dispose);
    await tester.pumpWidget(host(svc));
    await tester.pump();

    expect(find.text('THE DEN'), findsNothing);
    expect(find.textContaining('shelf'), findsNothing);
  });

  test('the demo playlist survives having no Spotify cover art', () {
    expect(Playlist.demo().imageUrl, isNull);
  });
}
