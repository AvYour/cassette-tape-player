import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/models/cassette_tape.dart';
import 'package:cassette_tape_player/utils/track_query.dart';

CassetteTape _tape(String name, String artist, {int ms = 200000}) =>
    CassetteTape(
      id: name.toLowerCase(),
      trackName: name,
      artistName: artist,
      year: '2020',
      spotifyUri: 'spotify:track:${name.toLowerCase()}',
      bodyColor: const Color(0xFF000000),
      labelColor: const Color(0xFF000000),
      stripeColor: const Color(0xFF000000),
      durationMs: ms,
      lyrics: const [],
    );

void main() {
  final tapes = [
    _tape('Creep', 'Radiohead', ms: 239000),
    _tape('No Surprises', 'Radiohead', ms: 229000),
    _tape('Photograph', 'Ed Sheeran', ms: 259000),
    _tape('bad', 'wave to earth', ms: 263000),
  ];

  group('TrackQuery.filter', () {
    test('an empty query keeps everything, in order', () {
      expect(TrackQuery.filter(tapes, ''), tapes);
      expect(TrackQuery.filter(tapes, '   '), tapes);
    });

    test('matches on the track name, ignoring case', () {
      expect(
        TrackQuery.filter(tapes, 'creep').map((t) => t.trackName),
        ['Creep'],
      );
      expect(
        TrackQuery.filter(tapes, 'CREEP').map((t) => t.trackName),
        ['Creep'],
      );
    });

    test('matches on the artist too, so typing a band finds their songs', () {
      expect(
        TrackQuery.filter(tapes, 'radiohead').map((t) => t.trackName),
        ['Creep', 'No Surprises'],
      );
    });

    test('matches a fragment anywhere in the words', () {
      expect(
        TrackQuery.filter(tapes, 'surpris').map((t) => t.trackName),
        ['No Surprises'],
      );
    });

    test('a query that matches nothing returns nothing, not everything', () {
      expect(TrackQuery.filter(tapes, 'zzzz'), isEmpty);
    });
  });

  group('TrackQuery.sort', () {
    test('original order hands the list back untouched', () {
      expect(
        TrackQuery.sort(tapes, TrackSort.original).map((t) => t.trackName),
        tapes.map((t) => t.trackName),
      );
    });

    test('by title sorts case-insensitively, so "bad" is not last', () {
      expect(
        TrackQuery.sort(tapes, TrackSort.title).map((t) => t.trackName),
        ['bad', 'Creep', 'No Surprises', 'Photograph'],
      );
    });

    test('by artist groups a band together', () {
      expect(
        TrackQuery.sort(tapes, TrackSort.artist).map((t) => t.artistName),
        ['Ed Sheeran', 'Radiohead', 'Radiohead', 'wave to earth'],
      );
    });

    test('by length runs shortest first', () {
      expect(
        TrackQuery.sort(tapes, TrackSort.length).map((t) => t.durationMs),
        [229000, 239000, 259000, 263000],
      );
    });

    test('never mutates the list it was given', () {
      final original = List<CassetteTape>.from(tapes);
      TrackQuery.sort(tapes, TrackSort.title);
      expect(tapes.map((t) => t.id), original.map((t) => t.id));
    });

    test('an empty list sorts to an empty list', () {
      expect(TrackQuery.sort(const [], TrackSort.title), isEmpty);
    });
  });
}
