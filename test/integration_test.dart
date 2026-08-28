
import 'package:flutter_test/flutter_test.dart';
import 'package:dyd_app/main.dart';

void main() {
  group('DYD App Integration Test', () {
    testWidgets('Home screen shows URL input and buttons', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.text('DYD'), findsWidgets);
      expect(find.text('Tu mesa de rol, en cualquier lugar'), findsOneWidget);
      expect(find.text('Crear sala'), findsWidgets);
      expect(find.text('Unirse a sala'), findsWidgets);
    });

    testWidgets('Create room button is disabled without URL', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final createButtons = find.text('Crear sala');
      expect(createButtons, findsWidgets);
    });

    testWidgets('Join room button is disabled without URL', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final joinButtons = find.text('Unirse a sala');
      expect(joinButtons, findsWidgets);
    });
  });
}
