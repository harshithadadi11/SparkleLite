import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:women_health/core/routing/app_router.dart';
import 'package:women_health/features/dashboard/dashboard_screen.dart';
import 'package:women_health/features/symptom_tracker/symptom_history_screen.dart';
import 'package:women_health/features/timeline/timeline_screen.dart';
import 'package:women_health/features/settings/settings_screen.dart';

void main() {
  testWidgets('DashboardScreen renders tabs and switches correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'is_logged_in': true});
    final prefs = await SharedPreferences.getInstance();

    // Set screen size to mobile to trigger mobileBody
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Symptoms tab
    await tester.tap(find.text('Symptoms').last);
    await tester.pumpAndSettle();
    expect(find.byType(SymptomHistoryScreen), findsOneWidget);

    // Tap Timeline tab
    await tester.tap(find.text('Timeline').last);
    await tester.pumpAndSettle();
    expect(find.byType(TimelineScreen), findsOneWidget);

    // Tap Settings tab
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
