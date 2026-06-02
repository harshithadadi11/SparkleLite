import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "dummy-api-key",
        appId: "1:1234567890:android:dummyapp",
        messagingSenderId: "1234567890",
        projectId: "sparkle-lite-dev",
        storageBucket: "sparkle-lite-dev.appspot.com",
      ),
    );

    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
        webProvider: ReCaptchaV3Provider('dummy-recaptcha-key'),
      );
    } catch (e) {
      debugPrint('Firebase App Check initialization failed: $e');
    }

    if (kDebugMode) {
      try {
        if (kIsWeb) {
          FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
          await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
          FirebaseStorage.instance.useStorageEmulator('127.0.0.1', 9199);
          FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
        } else {
          FirebaseFirestore.instance.useFirestoreEmulator('192.168.29.9', 8080);
          await FirebaseAuth.instance.useAuthEmulator('192.168.29.9', 9099);
          FirebaseStorage.instance.useStorageEmulator('192.168.29.9', 9199);
          FirebaseFunctions.instance.useFunctionsEmulator('192.168.29.9', 5001);
        }
      } catch (e) {
        debugPrint('Failed to initialize emulators: $e');
      }
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const SparkleLiteApp(),
    ),
  );
}

class SparkleLiteApp extends ConsumerWidget {
  const SparkleLiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Sparkle Lite',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}