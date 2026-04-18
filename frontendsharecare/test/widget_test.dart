// Basic Flutter widget test for ShareCare app.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/main.dart';

void main() {
  testWidgets('ShareCare app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ShareCareApp());
    await tester.pumpAndSettle();

    // Verify app title (AppBar) is present
    expect(find.text('ShareCare'), findsOneWidget);
  });
}
