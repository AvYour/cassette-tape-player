import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/models/playlist.dart';
import 'package:cassette_tape_player/widgets/cabinet_drawer.dart';

Playlist _playlist({int trackCount = 72}) => Playlist(
      id: 'pl1',
      name: 'My Favorite One',
      owner: 'Rel Kereta',
      ownerId: 'u1',
      trackCount: trackCount,
      accent: Colors.red,
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('face shows the uppercased playlist name and count subtitle',
      (tester) async {
    await tester.pumpWidget(_wrap(CabinetDrawer(
      playlist: _playlist(),
      isOpen: false,
      onTap: () {},
    )));
    expect(find.text('MY FAVORITE ONE'), findsOneWidget);
    expect(find.textContaining('72 tapes'), findsOneWidget);
    expect(find.textContaining('Rel Kereta'), findsOneWidget);
  });

  testWidgets('loadedCount overrides the playlist metadata count',
      (tester) async {
    await tester.pumpWidget(_wrap(CabinetDrawer(
      playlist: _playlist(trackCount: 99),
      isOpen: false,
      onTap: () {},
      loadedCount: 12,
    )));
    expect(find.textContaining('12 tapes'), findsOneWidget);
    expect(find.textContaining('99 tapes'), findsNothing);
  });

  testWidgets('tapping the face fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(CabinetDrawer(
      playlist: _playlist(),
      isOpen: false,
      onTap: () => taps++,
    )));
    await tester.tap(find.text('MY FAVORITE ONE'));
    expect(taps, 1);
  });

  testWidgets('open drawer takes the pulled pose (scaled up slightly)',
      (tester) async {
    await tester.pumpWidget(_wrap(CabinetDrawer(
      playlist: _playlist(),
      isOpen: true,
      onTap: () {},
    )));
    final scale =
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
    expect(scale, greaterThan(1.0));
  });
}
