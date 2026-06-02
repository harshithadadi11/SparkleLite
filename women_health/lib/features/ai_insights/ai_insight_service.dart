import 'package:uuid/uuid.dart';
import '../../data/models/ai_insight.dart';
import '../../data/models/symptom_log.dart';

class AIInsightService {
  AIInsight generateInsight(List<SymptomLog> logs, String userId) {
    String summary = "";
    String possiblePattern = "No clear pattern identified yet. Continue logging to help find trends.";
    String careGuidance = "Keep logging regularly. Even when you feel well, consistent records help establish your personal baseline.";
    List<String> doctorQuestions = [];

    int pain8plusCount = logs.where((l) => l.painLevel >= 8).length;
    bool hasHeavyAndDizzy = logs.any((l) =>
        l.flowLevel == FlowLevel.heavy &&
        (l.notes?.toLowerCase().contains('dizzy') == true ||
            l.notes?.toLowerCase().contains('dizziness') == true));
    bool hasIrregularBleeding = logs.any((l) => l.symptoms.contains(Symptom.irregularBleeding));

    final now = DateTime.now();
    final logsLast30Days = logs.where((l) => l.date.isAfter(now.subtract(const Duration(days: 30)))).toList();

    bool ruleFired = false;

    if (pain8plusCount > 0) {
      summary = "Your recent logs show pain levels of 8 or above on $pain8plusCount occasion(s). Pain at this level may be worth discussing with a healthcare provider.";
      careGuidance = "Consider speaking with a gynaecologist or general practitioner about recurring severe pain. Keeping a record of when it occurs and how long it lasts can be helpful.";
      doctorQuestions = [
        "What might be causing this level of pain?",
        "Should I track any additional details about my pain?",
        "When should I seek emergency care?"
      ];
      ruleFired = true;
    } else if (hasHeavyAndDizzy) {
      summary = "Your logs show heavy flow alongside notes mentioning dizziness. These together may be worth discussing with a doctor sooner rather than later.";
      careGuidance = "If you experience dizziness alongside heavy bleeding, consider contacting a healthcare provider promptly.";
      ruleFired = true;
    } else if (hasIrregularBleeding) {
      summary = "Your logs include entries noting irregular bleeding. Tracking the dates and frequency can be useful for a healthcare consultation.";
      careGuidance = "Irregular bleeding can have many causes. It is generally worth discussing with a gynaecologist, especially if it is new or frequent.";
      doctorQuestions = [
        "What could be causing irregular bleeding in my cycle?",
        "Are there tests that might help identify the cause?"
      ];
      ruleFired = true;
    } else if (logsLast30Days.length >= 3) {
      // Find most frequent mood
      Map<Mood, int> moodCounts = {};
      for (var l in logsLast30Days) {
        moodCounts[l.mood] = (moodCounts[l.mood] ?? 0) + 1;
      }
      var mostFrequentMood = moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      summary = "Your logs over the past 30 days show ${logsLast30Days.length} entries. The most frequently logged mood was ${mostFrequentMood.name}. Consistent tracking like this can be very helpful when preparing for a doctor visit.";
      possiblePattern = "You have been logging consistently. Patterns in your data may become more visible over time.";
      ruleFired = true;
    } else {
      // RULE 5
      summary = "Your recent logs do not show significant symptoms. Continuing to track regularly is a positive habit.";
    }

    final forbiddenPhrases = [
      "you have pcos",
      "you are pregnant",
      "you have cancer",
      "you do not need a doctor",
      "this is definitely normal",
      "this is definitely abnormal",
      "confirmed diagnosis",
      "you have endometriosis",
      "you have thyroid",
      "you have diabetes"
    ];

    void checkForbidden(String text) {
      final lowerText = text.toLowerCase();
      for (var phrase in forbiddenPhrases) {
        if (lowerText.contains(phrase)) {
          throw Exception("Forbidden phrase generated: $phrase");
        }
      }
    }

    checkForbidden(summary);
    checkForbidden(possiblePattern);
    checkForbidden(careGuidance);
    for (var q in doctorQuestions) {
      checkForbidden(q);
    }

    return AIInsight(
      id: const Uuid().v4(),
      userId: userId,
      summary: summary,
      possiblePattern: possiblePattern,
      careGuidance: careGuidance,
      doctorQuestions: doctorQuestions,
      disclaimer: AIInsight.DISCLAIMER,
      sourceLogIds: logs.map((e) => e.id).toList(),
      createdAt: DateTime.now(),
    );
  }
}
