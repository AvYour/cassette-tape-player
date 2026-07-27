import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/services/wiki_service.dart';

void main() {
  group('WikiService.bioFrom', () {
    test('takes the opening paragraph of a normal article', () {
      final bio = WikiService.bioFrom({
        'type': 'standard',
        'title': 'Radiohead',
        'extract': 'Radiohead are an English rock band formed in Abingdon.',
      });
      expect(bio, 'Radiohead are an English rock band formed in Abingdon.');
    });

    test('refuses a disambiguation page', () {
      // "XG may refer to..." is a list of options, not a biography.
      final bio = WikiService.bioFrom({
        'type': 'disambiguation',
        'title': 'XG',
        'extract': 'XG may refer to: XG (band), XG (motorcycle)…',
      });
      expect(bio, isNull);
    });

    test('a payload with no extract yields nothing', () {
      expect(WikiService.bioFrom({'type': 'standard'}), isNull);
      expect(WikiService.bioFrom({'type': 'standard', 'extract': ''}), isNull);
      expect(
          WikiService.bioFrom({'type': 'standard', 'extract': '   '}), isNull);
    });

    test('a non-string extract does not crash the parse', () {
      expect(WikiService.bioFrom({'extract': 42}), isNull);
      expect(WikiService.bioFrom(const {}), isNull);
    });

    test('trims surrounding whitespace', () {
      expect(
        WikiService.bioFrom({'extract': '  A band from Oxford.\n'}),
        'A band from Oxford.',
      );
    });
  });

  group('WikiService.cleanTrackTitle', () {
    test('drops a remaster or version suffix after a dash', () {
      expect(WikiService.cleanTrackTitle('Let Down - Remastered'), 'Let Down');
      expect(WikiService.cleanTrackTitle('Creep - 2011 Remaster'), 'Creep');
    });

    test('drops a featured-artist parenthetical', () {
      expect(WikiService.cleanTrackTitle('Praise The Lord (feat. Skepta)'),
          'Praise The Lord');
      expect(WikiService.cleanTrackTitle('Gabriela (with Young Miko)'),
          'Gabriela');
    });

    test('keeps a parenthetical that is part of the title', () {
      expect(
        WikiService.cleanTrackTitle('Exit Music (For A Film)'),
        'Exit Music (For A Film)',
      );
    });

    test('leaves a plain title alone', () {
      expect(WikiService.cleanTrackTitle('No Surprises'), 'No Surprises');
    });
  });

  group('WikiService.songTitleCandidates', () {
    test('asks for the artist-qualified article first', () {
      final candidates = WikiService.songTitleCandidates('Creep', 'Radiohead');
      expect(candidates.first, 'Creep (Radiohead song)');
      expect(candidates, contains('Creep (song)'));
    });

    test('cleans the track name before building candidates', () {
      final candidates =
          WikiService.songTitleCandidates('Let Down - Remastered', 'Radiohead');
      expect(candidates.first, 'Let Down (Radiohead song)');
    });

    test('falls back to the bare title last, where famous songs often sit', () {
      // "Take Me Home, Country Roads" needs no disambiguation on Wikipedia.
      final candidates = WikiService.songTitleCandidates(
          'Take Me Home, Country Roads', 'John Denver');
      expect(candidates.last, 'Take Me Home, Country Roads');
      // But it is the last resort, behind both qualified forms — and songBio
      // only accepts it when the text names the artist, so "Photograph" the
      // article about photographs is rejected.
      expect(candidates.length, 3);
      expect(candidates.indexOf('Take Me Home, Country Roads'), 2);
    });

    test('a blank track or artist has nothing to ask for', () {
      expect(WikiService.songTitleCandidates('', 'X'), isEmpty);
      expect(WikiService.songTitleCandidates('Y', ''), isEmpty);
    });
  });

  group('WikiService.mentionsArtist', () {
    // The unqualified "(song)" article could be a different artist's song, so
    // it is only trusted when the text names the artist we asked about.
    test('accepts an extract that names the artist', () {
      expect(
        WikiService.mentionsArtist(
            '"Creep" is a song by the English rock band Radiohead.',
            'Radiohead'),
        isTrue,
      );
    });

    test('is case-insensitive', () {
      expect(WikiService.mentionsArtist('a song by radiohead', 'Radiohead'),
          isTrue);
    });

    test('rejects an extract about somebody else', () {
      expect(
        WikiService.mentionsArtist('"Creep" is a song by Stone Temple Pilots.',
            'Radiohead'),
        isFalse,
      );
    });

    test('a blank artist matches nothing rather than everything', () {
      expect(WikiService.mentionsArtist('any text at all', '   '), isFalse);
    });
  });

  group('WikiService.titleFor', () {
    test('percent-encodes a name for the summary path', () {
      expect(WikiService.titleFor('Radiohead'), 'Radiohead');
      expect(WikiService.titleFor('A\$AP Rocky'), contains('%24'));
    });

    test('spaces become underscores, the way Wikipedia titles read', () {
      expect(WikiService.titleFor('Fleetwood Mac'), 'Fleetwood_Mac');
    });

    test('an empty or blank name has no title to ask for', () {
      expect(WikiService.titleFor('   '), isEmpty);
    });
  });
}
