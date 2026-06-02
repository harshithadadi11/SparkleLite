"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.summaryBuilder = summaryBuilder;
function summaryBuilder(input) {
    var _a;
    const { profile, recentLogs, recentRecords, questionsToAsk, userNotes } = input;
    const lines = [];
    const now = new Date().toLocaleDateString('en-IN', { year: 'numeric', month: 'long', day: 'numeric' });
    lines.push(`DOCTOR VISIT PREPARATION SUMMARY`);
    lines.push(`Generated: ${now}`);
    lines.push(`---`);
    if (profile) {
        lines.push(`PATIENT INFORMATION`);
        lines.push(`Name: ${profile.nameOrNickname || 'Not provided'}`);
        lines.push(`Age range: ${profile.ageRange || 'Not provided'}`);
        lines.push(`Life stage: ${formatLifeStage(profile.lifeStage)}`);
        if (profile.medications)
            lines.push(`Current medications: ${profile.medications}`);
        if (((_a = profile.knownConditions) === null || _a === void 0 ? void 0 : _a.length) > 0) {
            lines.push(`Noted conditions: ${profile.knownConditions.join(', ')}`);
        }
        lines.push(`---`);
    }
    if (recentLogs.length > 0) {
        lines.push(`RECENT SYMPTOM LOG SUMMARY (last ${recentLogs.length} entries)`);
        recentLogs.forEach((log, i) => {
            var _a, _b;
            const date = ((_a = log.date) === null || _a === void 0 ? void 0 : _a.toDate) ? log.date.toDate().toLocaleDateString() : 'Unknown date';
            lines.push(`Entry ${i + 1}: ${date}`);
            lines.push(`  Period status: ${formatPeriodStatus(log.periodStatus)}`);
            if (log.painLevel !== undefined)
                lines.push(`  Pain level: ${log.painLevel}/10`);
            if (log.mood)
                lines.push(`  Mood: ${log.mood}`);
            if (((_b = log.symptoms) === null || _b === void 0 ? void 0 : _b.length) > 0)
                lines.push(`  Symptoms: ${log.symptoms.join(', ')}`);
            if (log.notes)
                lines.push(`  Notes: ${log.notes}`);
        });
        lines.push(`---`);
    }
    else {
        lines.push(`SYMPTOM LOGS: No recent entries recorded.`);
        lines.push(`---`);
    }
    if (recentRecords.length > 0) {
        lines.push(`HEALTH RECORDS (last 30 days)`);
        recentRecords.forEach(record => {
            var _a;
            const date = ((_a = record.recordDate) === null || _a === void 0 ? void 0 : _a.toDate)
                ? record.recordDate.toDate().toLocaleDateString()
                : 'Unknown date';
            lines.push(`- ${record.title} (${record.recordType}) — ${date}`);
            if (record.doctorName)
                lines.push(`  Doctor/Clinic: ${record.doctorName}`);
        });
        lines.push(`---`);
    }
    if (questionsToAsk.length > 0) {
        lines.push(`QUESTIONS TO ASK YOUR DOCTOR`);
        questionsToAsk.forEach((q, i) => lines.push(`${i + 1}. ${q}`));
        lines.push(`---`);
    }
    if (userNotes) {
        lines.push(`PERSONAL NOTES`);
        lines.push(userNotes);
        lines.push(`---`);
    }
    lines.push(`IMPORTANT: This summary was prepared by the user and is intended as a conversation aid only. It does not constitute medical advice or a diagnosis.`);
    return lines.join('\n');
}
function formatLifeStage(stage) {
    const map = {
        generalWellness: 'General wellness',
        periodTracking: 'Period tracking',
        fertilityPlanning: 'Fertility planning',
        pregnancy: 'Pregnancy',
        postpartum: 'Postpartum',
        menopause: 'Menopause / perimenopause',
    };
    return map[stage] || stage;
}
function formatPeriodStatus(status) {
    const map = {
        noPeriod: 'No period',
        started: 'Period started',
        ongoing: 'Period ongoing',
        ended: 'Period ended',
    };
    return map[status] || status;
}
//# sourceMappingURL=summaryBuilder.js.map