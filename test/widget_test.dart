// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:tool_node/main.dart';

void main() {
  testWidgets('Machinery App launch smoke test', (WidgetTester tester) async {
    // 🚀 Build our app and trigger a frame.
    // This uses ShacaApp which points to RootScreen (the machinery list).
    await tester.pumpWidget(const ShacaApp());

    // ✅ Verify that the app title 'Shaca' is present in the AppBar.
    expect(find.text('Shaca'), findsOneWidget);

    // ✅ Verify that the Bottom Navigation Bar items are present.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // ✅ Verify that it does NOT show the old counter '0'.
    expect(find.text('0'), findsNothing);
  });
}