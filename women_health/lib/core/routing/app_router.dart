import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/ai_insights/insight_input_screen.dart';
import '../../features/ai_insights/insight_result_screen.dart';
import '../../data/models/ai_insight.dart';
import '../../features/doctor_summary/doctor_summary_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/health_records/health_records_screen.dart';
import '../../features/health_records/upload_record_screen.dart';
import '../../features/profile/profile_setup_screen.dart';
import '../../features/symptom_tracker/add_symptom_screen.dart';
import '../../features/symptom_tracker/symptom_history_screen.dart';
import '../../data/models/symptom_log.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/privacy_screen.dart';
import '../../features/settings/family_profile_screen.dart';
import '../../features/settings/notification_settings_screen.dart';
import '../../features/settings/add_family_member_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/timeline/timeline_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/mock_backend.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_router.g.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final localAuthSuccessProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return prefs.getBool('is_logged_in') ?? false;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepoProvider).authStateChanges;
});

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authNotifier = ValueNotifier<bool>(ref.read(localAuthSuccessProvider));
  
  ref.listen<bool>(localAuthSuccessProvider, (_, next) {
    authNotifier.value = next;
  });

  ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
    if (next is AsyncData<User?>) {
      final isLoggedIn = next.value != null;
      ref.read(localAuthSuccessProvider.notifier).state = isLoggedIn;
      ref.read(sharedPrefsProvider).setBool('is_logged_in', isLoggedIn);
    }
  });

  return GoRouter(
    initialLocation: '/auth/signup',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = authNotifier.value;
      final isAuthRoute = state.uri.path.startsWith('/auth');
      
      if (!isAuthenticated && !isAuthRoute) return '/auth/signup';
      if (isAuthenticated && isAuthRoute) return '/dashboard';
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => SignupScreen(),
      ),
      GoRoute(
        path: '/profile/setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'reminders',
            builder: (context, state) => const RemindersScreen(),
          ),
          GoRoute(
            path: 'symptoms/history',
            builder: (context, state) => const SymptomHistoryScreen(),
          ),
          GoRoute(
            path: 'symptoms/add',
            builder: (context, state) => const AddSymptomScreen(),
          ),
          GoRoute(
            path: 'records',
            builder: (context, state) => const HealthRecordsScreen(),
            routes: [
              GoRoute(
                path: 'upload',
                builder: (context, state) => const UploadRecordScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => const HealthRecordsScreen(), // Placeholder for detail screen
              ),
            ],
          ),
          GoRoute(
            path: 'doctor-summary',
            builder: (context, state) => const DoctorSummaryScreen(),
          ),
          GoRoute(
            path: 'timeline',
            builder: (context, state) => const TimelineScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'privacy',
                builder: (context, state) => const PrivacyScreen(),
              ),
              GoRoute(
                path: 'notifications',
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
              GoRoute(
                path: 'family',
                builder: (context, state) => const FamilyProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddFamilyMemberScreen(),
                  ),
                  GoRoute(
                    path: 'add/:id',
                    builder: (context, state) => const AddFamilyMemberScreen(), // Edit mode
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/symptoms/add',
        builder: (context, state) => const AddSymptomScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final log = state.extra as SymptomLog?;
              return AddSymptomScreen(existingLog: log);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/records',
        builder: (context, state) => const HealthRecordsScreen(),
      ),
      GoRoute(
        path: '/upload-record',
        builder: (context, state) => const UploadRecordScreen(),
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) => const AiInsightsScreen(),
      ),
      GoRoute(
        path: '/insight-result',
        builder: (context, state) {
          final insight = state.extra as AIInsight;
          return InsightResultScreen(insight: insight);
        },
      ),
      GoRoute(
        path: '/visit-prep',
        builder: (context, state) => const DoctorSummaryScreen(),
      ),
    ],
  );
}
