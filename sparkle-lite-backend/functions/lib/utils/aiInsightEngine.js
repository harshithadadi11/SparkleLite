"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.aiInsightEngine = aiInsightEngine;
const admin = __importStar(require("firebase-admin"));
const REQUIRED_DISCLAIMER = 'This is not a medical diagnosis. This app cannot diagnose conditions or replace professional medical advice. Please consult a qualified healthcare provider about any health concerns.';
// CRITICAL: These phrases must NEVER appear in any output string
const FORBIDDEN_PHRASES = [
    'you have pcos', 'you have endometriosis', 'you are pregnant',
    'you have cancer', 'you do not need a doctor', 'definitely normal',
    'definitely abnormal', 'you have diabetes', 'you have thyroid',
    'confirmed diagnosis', 'you are diagnosed',
];
function assertNoForbiddenPhrases(text) {
    const lower = text.toLowerCase();
    for (const phrase of FORBIDDEN_PHRASES) {
        if (lower.includes(phrase)) {
            throw new Error(`Insight contains forbidden diagnostic phrase: "${phrase}"`);
        }
    }
}
function aiInsightEngine(logs, userId) {
    const now30DaysAgo = new Date();
    now30DaysAgo.setDate(now30DaysAgo.getDate() - 30);
    const recentLogs = logs.filter(log => {
        var _a;
        const logDate = ((_a = log.date) === null || _a === void 0 ? void 0 : _a.toDate) ? log.date.toDate() : new Date(log.date);
        return logDate >= now30DaysAgo;
    });
    const highPainLogs = logs.filter(log => log.painLevel >= 8);
    const heavyFlowLogs = logs.filter(log => log.flowLevel === 'heavy');
    const irregularBleeding = logs.some(log => Array.isArray(log.symptoms) && log.symptoms.includes('irregularBleeding'));
    const hasDizzinessNote = logs.some(log => typeof log.notes === 'string' &&
        (log.notes.toLowerCase().includes('dizzy') || log.notes.toLowerCase().includes('dizziness')));
    const hasNoSymptoms = logs.every(log => (!log.symptoms || log.symptoms.length === 0) && log.painLevel <= 2);
    const manyRecentLogs = recentLogs.length >= 3;
    let summary = '';
    let possiblePattern = '';
    let careGuidance = '';
    const doctorQuestions = [];
    // Rule 1: High pain
    if (highPainLogs.length > 0) {
        summary = `Your recent logs show pain levels of 8 or above on ${highPainLogs.length} occasion(s). This level of pain may be worth discussing with a healthcare provider.`;
        possiblePattern = 'Recurring high-intensity pain has been logged. Patterns like this can have various causes that a doctor can help evaluate.';
        careGuidance = 'Consider speaking with a gynaecologist or general practitioner about recurring severe pain. Keeping a record of when it occurs, how long it lasts, and any associated symptoms can be helpful for your consultation.';
        doctorQuestions.push('What might be causing recurring pain at this level?', 'Should I track any additional details about my pain?', 'Are there any tests you would recommend?', 'When should I seek emergency care for pain?');
    }
    // Rule 2: Heavy flow with dizziness note
    if (heavyFlowLogs.length > 0 && hasDizzinessNote) {
        summary = `Your logs show heavy flow alongside notes mentioning dizziness. These two together may be worth discussing with a doctor sooner rather than later.`;
        possiblePattern = 'Heavy flow and dizziness appearing together in your logs may indicate something your healthcare provider should evaluate.';
        careGuidance = 'If you are experiencing dizziness alongside heavy bleeding, please consider contacting a healthcare provider promptly. In case of severe dizziness or very heavy bleeding, seek medical attention.';
        doctorQuestions.push('Could heavy flow be affecting my iron levels or causing dizziness?', 'What level of flow is considered medically heavy?', 'Should I have a blood count test?');
    }
    // Rule 3: Irregular bleeding
    if (irregularBleeding) {
        if (!summary) {
            summary = `Your logs include entries noting irregular bleeding. Tracking the dates and frequency of these occurrences can be useful information for a healthcare consultation.`;
        }
        possiblePattern = 'Irregular bleeding patterns have been noted in your logs. There are many possible reasons for this, and a healthcare provider is best placed to evaluate them.';
        careGuidance = 'Irregular bleeding can have many different causes, ranging from hormonal changes to other conditions. It is generally a good idea to discuss this with a gynaecologist, especially if it is new, frequent, or accompanied by other symptoms.';
        doctorQuestions.push('What could be causing irregular bleeding in my cycle?', 'Is the timing or frequency of irregular bleeding significant?', 'Are there any lifestyle factors that might be contributing?', 'What tests might help identify the cause?');
    }
    // Rule 4: Pattern from multiple recent logs
    if (manyRecentLogs && !summary) {
        const moodCounts = {};
        logs.forEach(log => {
            if (log.mood)
                moodCounts[log.mood] = (moodCounts[log.mood] || 0) + 1;
        });
        const topMood = Object.entries(moodCounts).sort((a, b) => b[1] - a[1])[0];
        summary = `Your logs over the past 30 days show ${recentLogs.length} entries. ${topMood ? `The most frequently logged mood was "${topMood[0]}".` : ''} Consistent tracking like this can be very helpful when preparing for a doctor visit.`;
        possiblePattern = 'You have been logging consistently. Over time, patterns in your data may become more visible and useful for healthcare conversations.';
        careGuidance = 'Continue tracking. Bringing your logged history to your next appointment can give your doctor helpful context.';
        doctorQuestions.push('Does my logged history show any patterns I should be aware of?', 'Are my symptoms within a typical range?', 'How often should I be having routine check-ups?');
    }
    // Rule 5: No symptoms / wellness
    if (hasNoSymptoms || !summary) {
        summary = 'Your recent logs do not show significant symptoms. Continuing to track your health regularly is a positive habit.';
        possiblePattern = 'No concerning patterns are visible in your current logs.';
        careGuidance = 'Keep logging regularly. Even when you feel well, consistent records help establish your personal baseline and can be useful context for future healthcare consultations.';
        doctorQuestions.push('Are there any routine screenings I should schedule?', 'What symptoms should I watch for and log?', 'Is my current cycle pattern typical?');
    }
    // Deduplicate questions
    const uniqueQuestions = [...new Set(doctorQuestions)].slice(0, 5);
    // Safety assertion — fail hard if any forbidden phrase slips through
    assertNoForbiddenPhrases(summary);
    assertNoForbiddenPhrases(possiblePattern);
    assertNoForbiddenPhrases(careGuidance);
    return {
        userId,
        summary,
        possiblePattern,
        careGuidance,
        doctorQuestions: uniqueQuestions,
        disclaimer: REQUIRED_DISCLAIMER,
        sourceLogIds: logs.map(l => l.id),
        createdAt: admin.firestore.Timestamp.now(),
    };
}
//# sourceMappingURL=aiInsightEngine.js.map