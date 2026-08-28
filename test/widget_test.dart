// Basic smoke test for the DYD home screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:dyd_app/main.dart';

void main() {
  testWidgets('Home screen shows create/join buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Crear sala'), findsOneWidget);
    expect(find.text('Unirse a sala'), findsOneWidget);
  });
}
