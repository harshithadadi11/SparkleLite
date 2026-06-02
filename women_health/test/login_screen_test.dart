import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:women_health/features/auth/login_screen.dart';
import 'package:women_health/core/constants/app_strings.dart';

void main() {
  testWidgets('LoginScreen renders correctly and shows validation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Login'), findsOneWidget);

    // Tap login without filling fields
    await tester.tap(find.text('Login'));
    await tester.pump();

    // Expect validation errors
    expect(find.text('Email is required'), findsOneWidget);
  });
}
