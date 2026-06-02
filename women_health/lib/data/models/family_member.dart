import 'package:freezed_annotation/freezed_annotation.dart';

part 'family_member.freezed.dart';
part 'family_member.g.dart';

enum Relationship {
  spouse,
  child,
  parent,
  sibling,
  other
}

@freezed
class FamilyMember with _$FamilyMember {
  const factory FamilyMember({
    required String id,
    required String userId,
    required String nameOrNickname,
    required Relationship relationship,
    required String ageRange,
    String? notes,
    required DateTime createdAt,
  }) = _FamilyMember;

  factory FamilyMember.fromJson(Map<String, dynamic> json) => _$FamilyMemberFromJson(json);
}
