import '../../../data/models/health_profile.dart';
import '../../../data/models/symptom_log.dart';
import '../../../data/models/health_record.dart';
import 'package:intl/intl.dart';

class SummaryBuilderService {
  String buildSummaryText({
    required HealthProfile? profile,
    required List<SymptomLog> recentLogs,
    required List<HealthRecord> recentRecords,
    required List<String> questionsToAsk,
    String? userNotes,
    String? medications,
  }) {
    final dateStr = DateFormat('MMM dd, yyyy').format(DateTime.now());
    
    final buffer = StringBuffer();
    buffer.writeln('DOCTOR VISIT PREPARATION SUMMARY');
    buffer.writeln('Generated: $dateStr');
    buffer.writeln('─────────────────────────────────\n');
    
    buffer.writeln('PATIENT INFORMATION');
    buffer.writeln('Name: ${profile?.nameOrNickname ?? "Unknown"}');
    buffer.writeln('Age range: ${profile?.ageRange ?? "Unknown"}');
    buffer.writeln('Life stage: ${profile?.lifeStage.name ?? "Unknown"}');
    buffer.writeln('Current medications: ${medications != null && medications.isNotEmpty ? medications : "None noted"}\n');
    
    buffer.writeln('RECENT SYMPTOM LOG SUMMARY (${recentLogs.length} entries)');
    for (var log in recentLogs) {
      final logDate = DateFormat('MMM dd, yyyy').format(log.date);
      final symptomsList = log.symptoms.map((s) => s.name).join(', ');
      buffer.writeln('  $logDate — Period: ${log.periodStatus.name}, Pain: ${log.painLevel}/10, Mood: ${log.mood.name}, Symptoms: $symptomsList');
      if (log.notes != null && log.notes!.isNotEmpty) {
        buffer.writeln('  Notes: ${log.notes}');
      }
    }
    buffer.writeln();
    
    buffer.writeln('HEALTH RECORDS (last 30 days)');
    for (var record in recentRecords) {
      if (record.isPrivate) continue; // Should be filtered already, but double check
      final recDate = DateFormat('MMM dd, yyyy').format(record.recordDate);
      buffer.writeln('  - ${record.title} (${record.recordType.name}) — $recDate');
      if (record.doctorName != null && record.doctorName!.isNotEmpty) {
        buffer.writeln('    Doctor/Clinic: ${record.doctorName}');
      }
    }
    buffer.writeln('  Note: Private records are excluded from this export.\n');
    
    buffer.writeln('QUESTIONS FOR YOUR DOCTOR');
    for (int i = 0; i < questionsToAsk.length; i++) {
      buffer.writeln('${i + 1}. ${questionsToAsk[i]}');
    }
    buffer.writeln();
    
    if (userNotes != null && userNotes.isNotEmpty) {
      buffer.writeln('PERSONAL NOTES');
      buffer.writeln('$userNotes\n');
    }
    
    buffer.writeln('─────────────────────────────────');
    buffer.writeln('IMPORTANT: This summary was prepared by the user as a conversation aid. It does not constitute medical advice or a diagnosis.');
    
    return buffer.toString();
  }
}
