import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderRepeat { none, daily, weekly, monthly }
enum ReminderCategory { medication, symptomLog, appointment, hydration, other }

class ReminderModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime scheduledTime;
  final ReminderRepeat repeat;
  final ReminderCategory category;
  final bool isActive;
  final DateTime createdAt;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.scheduledTime,
    required this.repeat,
    required this.category,
    required this.isActive,
    required this.createdAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    DateTime parseTime(dynamic val) {
      if (val is String) return DateTime.parse(val);
      if (val is Timestamp) return val.toDate();
      return DateTime.now();
    }
    return ReminderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledTime: parseTime(json['scheduledTime']),
      repeat: ReminderRepeat.values.firstWhere(
        (e) => e.name == json['repeat'],
        orElse: () => ReminderRepeat.none,
      ),
      category: ReminderCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ReminderCategory.other,
      ),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'repeat': repeat.name,
      'category': category.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime.toIso8601String(),
      'repeat': repeat.name,
      'category': category.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ReminderModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? scheduledTime,
    ReminderRepeat? repeat,
    ReminderCategory? category,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      repeat: repeat ?? this.repeat,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
