import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/main.dart';

void main() {
  testWidgets('Music App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MusicApp());

    // Verify the app starts without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
