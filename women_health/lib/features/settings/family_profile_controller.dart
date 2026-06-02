import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/family_member.dart';
import '../../data/repositories/mock_backend.dart';

part 'family_profile_controller.g.dart';

@riverpod
class FamilyProfileController extends _$FamilyProfileController {
  @override
  FutureOr<List<FamilyMember>> build() async {
    return _fetchMembers();
  }

  Future<List<FamilyMember>> _fetchMembers() async {
    final uid = ref.read(authRepoProvider).currentUser!.uid;
    return await ref.read(familyRepoProvider).getMembers(uid);
  }

  Future<void> addMember(String name, Relationship relationship, String ageRange, String notes) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final member = FamilyMember(
        id: const Uuid().v4(),
        userId: ref.read(authRepoProvider).currentUser!.uid,
        nameOrNickname: name,
        relationship: relationship,
        ageRange: ageRange,
        notes: notes,
        createdAt: DateTime.now(),
      );
      await ref.read(familyRepoProvider).addMember(member);
      return _fetchMembers();
    });
  }
}
