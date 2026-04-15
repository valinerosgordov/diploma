import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_practice/main.dart';

void main() {
  testWidgets('App renders home page with title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('File Analysis Tool'), findsOneWidget);
    expect(find.byIcon(Icons.folder_open), findsOneWidget);
    expect(find.text('Analyze Directory'), findsOneWidget);
  });

  testWidgets('App shows stats cards', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Total Files'), findsOneWidget);
    expect(find.text('Total Size'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
  });

  testWidgets('App shows empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('No files analyzed yet'), findsOneWidget);
  });
}
