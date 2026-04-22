// Basic Flutter widget test for ShareCare app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/main.dart';

void main() {
  testWidgets('ShareCare app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ShareCareApp());
    // Avoid settling indefinitely because app bootstrap registers async handlers.
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'ShareCare');
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
