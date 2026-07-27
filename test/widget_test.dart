import 'package:flutter_test/flutter_test.dart';
import 'package:cassette_tape_player/main.dart';
import 'package:cassette_tape_player/widgets/skeleton.dart';

void main() {
  testWidgets('App boots into Explore', (WidgetTester tester) async {
    await tester.pumpWidget(const CassettePlayerApp());
    await tester.pump();
    expect(find.text('Explore'), findsOneWidget);
  });

  testWidgets('the wheel shows skeletons while the connect is in flight, not '
      'the starter mixtape', (WidgetTester tester) async {
    await tester.pumpWidget(const CassettePlayerApp());
    await tester.pump(); // lets the post-frame connect kick off

    // The demo is the offline fallback for when there is genuinely nothing —
    // showing it mid-connect would be dummy data standing in for real rows
    // that are on their way.
    expect(find.byType(SkeletonWheel), findsOneWidget);
    expect(find.text('Starter Mixtape'), findsNothing);

    // Let the shimmer settle so the test doesn't end mid-animation.
    await tester.pump(const Duration(milliseconds: 100));
  });
}
