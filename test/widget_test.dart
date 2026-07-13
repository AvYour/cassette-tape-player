import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/main.dart';

void main() {
  testWidgets('App boots to the 1985 room', (WidgetTester tester) async {
    await tester.pumpWidget(const CassettePlayerApp());
    await tester.pump();
    expect(find.text('THE DEN'), findsOneWidget);
    // The starter mixtape shelf is on the wall before Spotify connects.
    expect(find.textContaining('STARTER MIXTAPE'), findsOneWidget);
  });
}
