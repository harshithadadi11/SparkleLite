import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/health_profile.dart';
import '../../../data/repositories/mock_backend.dart';

class ProfileSetupState {
  final String nameOrNickname;
  final int age;
  final LifeStage? lifeStage;
  final String? menstrualCycleStatus;
  final List<String> knownConditions;
  final String? medications;
  final PrivacyLevel privacyPreference;
  final bool notificationsEnabled;
  final bool isLoading;
  final String? error;

  ProfileSetupState({
    this.nameOrNickname = '',
    this.age = 0,
    this.lifeStage,
    this.menstrualCycleStatus,
    this.knownConditions = const [],
    this.medications,
    this.privacyPreference = PrivacyLevel.standard,
    this.notificationsEnabled = true,
    this.isLoading = false,
    this.error,
  });

  ProfileSetupState copyWith({
    String? nameOrNickname,
    int? age,
    LifeStage? lifeStage,
    String? menstrualCycleStatus,
    List<String>? knownConditions,
    String? medications,
    PrivacyLevel? privacyPreference,
    bool? notificationsEnabled,
    bool? isLoading,
    String? error,
  }) {
    return ProfileSetupState(
      nameOrNickname: nameOrNickname ?? this.nameOrNickname,
      age: age ?? this.age,
      lifeStage: lifeStage ?? this.lifeStage,
      menstrualCycleStatus: menstrualCycleStatus ?? this.menstrualCycleStatus,
      knownConditions: knownConditions ?? this.knownConditions,
      medications: medications ?? this.medications,
      privacyPreference: privacyPreference ?? this.privacyPreference,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProfileSetupNotifier extends StateNotifier<ProfileSetupState> {
  final Ref ref;

  ProfileSetupNotifier(this.ref) : super(ProfileSetupState());

  void updateName(String name) => state = state.copyWith(nameOrNickname: name);
  void updateAge(int age) => state = state.copyWith(age: age);
  void updateLifeStage(LifeStage stage) => state = state.copyWith(lifeStage: stage);
  void updateCycleStatus(String status) => state = state.copyWith(menstrualCycleStatus: status);
  void updateConditions(List<String> conditions) => state = state.copyWith(knownConditions: conditions);
  void updateMedications(String meds) => state = state.copyWith(medications: meds);
  void updatePrivacy(PrivacyLevel privacy) => state = state.copyWith(privacyPreference: privacy);
  void updateNotifications(bool enabled) => state = state.copyWith(notificationsEnabled: enabled);

  String _calculateAgeRange(int age) {
    if (age < 18) return 'Under 18';
    if (age <= 24) return '18-24';
    if (age <= 34) return '25-34';
    if (age <= 44) return '35-44';
    if (age <= 54) return '45-54';
    return '55+';
  }

  Future<void> saveProfile() async {
    if (state.nameOrNickname.isEmpty || state.age == 0 || state.lifeStage == null) {
      state = state.copyWith(error: 'Required fields missing');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = HealthProfile(
        userId: ref.read(authRepoProvider).currentUser?.uid ?? 'mock-user-123',
        nameOrNickname: state.nameOrNickname,
        age: state.age,
        ageRange: _calculateAgeRange(state.age),
        lifeStage: state.lifeStage!,
        menstrualCycleStatus: state.menstrualCycleStatus,
        knownConditions: state.knownConditions,
        medications: state.medications,
        privacyPreference: state.privacyPreference,
        notificationsEnabled: state.notificationsEnabled,
        useGenericNotifications: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(profileRepoProvider).saveProfile(profile);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final profileSetupNotifierProvider = StateNotifierProvider<ProfileSetupNotifier, ProfileSetupState>((ref) {
  return ProfileSetupNotifier(ref);
});
