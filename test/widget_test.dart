import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/main.dart';

void main() {
  testWidgets('App boots into Explore', (WidgetTester tester) async {
    await tester.pumpWidget(const CassettePlayerApp());
    await tester.pump();
    expect(find.text('Explore'), findsOneWidget);
    // The starter mixtape is in the list before Spotify connects, so the
    // home screen is never an empty page.
    expect(find.text('Starter Mixtape'), findsOneWidget);
  });
}
