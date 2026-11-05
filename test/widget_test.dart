// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:puli_meka_game_flutter/main.dart';

void main() {
  testWidgets('Home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PuliMekaApp());

    expect(find.text('Puli Meka'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Career'), findsOneWidget);
  });
}
