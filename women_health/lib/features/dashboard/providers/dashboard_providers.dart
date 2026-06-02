import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../symptom_tracker/symptom_controller.dart';
import '../../health_records/health_record_controller.dart';
import '../../../data/models/symptom_log.dart';
import '../../../data/models/health_record.dart';

final recentSymptomLogProvider = Provider<AsyncValue<SymptomLog?>>((ref) {
  final logsAsync = ref.watch(symptomControllerProvider);
  return logsAsync.whenData((logs) => logs.isNotEmpty ? logs.first : null);
});

final recentHealthRecordProvider = Provider<AsyncValue<HealthRecord?>>((ref) {
  final recordsAsync = ref.watch(healthRecordControllerProvider);
  return recordsAsync.whenData((records) => records.isNotEmpty ? records.first : null);
});
