import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/models/cassette_tape.dart';

void main() {
  const tape = CassetteTape(
    id: 't1',
    trackName: 'Creep',
    artistName: 'Radiohead',
    albumName: 'Pablo Honey',
    year: '1992',
    albumArtUrl: 'https://i.scdn.co/big',
    albumThumbUrl: 'https://i.scdn.co/small',
    spotifyUri: 'spotify:track:t1',
    bodyColor: Color(0xFF112233),
    labelColor: Color(0xFF445566),
    stripeColor: Color(0xFF778899),
    durationMs: 239000,
    lyrics: ['a', 'b'],
    contextIndex: 4,
  );

  group('CassetteTape round-trips through JSON', () {
    test('everything the mini-player and player need survives', () {
      final back = CassetteTape.fromStoredJson(tape.toStoredJson());
      expect(back.id, 't1');
      expect(back.trackName, 'Creep');
      expect(back.artistName, 'Radiohead');
      expect(back.albumName, 'Pablo Honey');
      expect(back.year, '1992');
      expect(back.spotifyUri, 'spotify:track:t1');
      expect(back.durationMs, 239000);
      expect(back.contextIndex, 4);
      expect(back.thumbUrl, 'https://i.scdn.co/small');
    });

    test('the painted colours come back exactly, so the tape looks the same',
        () {
      final back = CassetteTape.fromStoredJson(tape.toStoredJson());
      expect(back.bodyColor, const Color(0xFF112233));
      expect(back.labelColor, const Color(0xFF445566));
      expect(back.stripeColor, const Color(0xFF778899));
    });

    test('a tape with no art or context index still restores', () {
      const bare = CassetteTape(
        id: 'x',
        trackName: 'X',
        artistName: 'Y',
        year: '',
        spotifyUri: '',
        bodyColor: Color(0xFF000000),
        labelColor: Color(0xFF000000),
        stripeColor: Color(0xFF000000),
        lyrics: [],
      );
      final back = CassetteTape.fromStoredJson(bare.toStoredJson());
      expect(back.albumArtUrl, isNull);
      expect(back.contextIndex, isNull);
      expect(back.thumbUrl, isNull);
    });

    test('a malformed record does not crash the restore', () {
      final back = CassetteTape.fromStoredJson(const {});
      expect(back.id, isEmpty);
      expect(back.durationMs, greaterThan(0));
    });

    test('lyrics are not stored — they are refetched, not remembered', () {
      expect(tape.toStoredJson().containsKey('lyrics'), isFalse);
    });
  });
}
