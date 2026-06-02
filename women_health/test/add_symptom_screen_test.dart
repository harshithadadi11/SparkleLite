import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:women_health/features/symptom_tracker/add_symptom_screen.dart';

void main() {
  testWidgets('AddSymptomScreen renders and allows interaction', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AddSymptomScreen(),
        ),
      ),
    );

    expect(find.text('Add Symptom Log'), findsOneWidget);
    
    // Check for chips
    expect(find.text('Cramps'), findsOneWidget);
    expect(find.text('Fatigue'), findsOneWidget);
    
    // Tap a chip
    await tester.tap(find.text('Cramps'), warnIfMissed: false);
    await tester.pump();
    
    // Test notes field
    await tester.enterText(find.byType(TextFormField).last, 'Feeling a bit tired today.');
    expect(find.text('Feeling a bit tired today.'), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
