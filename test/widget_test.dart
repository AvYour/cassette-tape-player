import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/main.dart';

void main() {
  testWidgets('App boots to library screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CassettePlayerApp());
    await tester.pump();
    expect(find.text('MY TAPES'), findsOneWidget);
  });
}
