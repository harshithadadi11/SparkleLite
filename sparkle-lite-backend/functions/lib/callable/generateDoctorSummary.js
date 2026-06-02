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
exports.generateDoctorSummary = void 0;
const functions = __importStar(require("firebase-functions"));
const firebase_1 = require("../config/firebase");
const auth_1 = require("../middleware/auth");
const summaryBuilder_1 = require("../utils/summaryBuilder");
exports.generateDoctorSummary = functions.https.onCall(async (data, context) => {
    const uid = (0, auth_1.verifyAuth)(context);
    // Fetch profile
    const profileSnap = await firebase_1.db.collection('profiles').doc(uid).get();
    const profile = profileSnap.exists ? profileSnap.data() : null;
    // Fetch last 5 symptom logs
    const logsSnap = await firebase_1.db
        .collection('symptomLogs').doc(uid).collection('logs')
        .orderBy('date', 'desc').limit(5).get();
    const recentLogs = logsSnap.docs.map(d => (Object.assign({ id: d.id }, d.data())));
    // Fetch records from last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const recordsSnap = await firebase_1.db
        .collection('healthRecords').doc(uid).collection('records')
        .where('recordDate', '>=', thirtyDaysAgo)
        .orderBy('recordDate', 'desc').get();
    const recentRecords = recordsSnap.docs.map(d => (Object.assign({ id: d.id }, d.data())));
    // Build the summary
    const summaryText = (0, summaryBuilder_1.summaryBuilder)({
        profile,
        recentLogs,
        recentRecords,
        questionsToAsk: data.questionsToAsk || [],
        userNotes: data.userNotes,
    });
    const summaryDoc = {
        userId: uid,
        profileSnapshot: profile ? {
            nameOrNickname: profile.nameOrNickname,
            ageRange: profile.ageRange,
            lifeStage: profile.lifeStage,
            medications: profile.medications,
        } : {},
        recentSymptoms: recentLogs,
        recentRecords: recentRecords,
        recentSymptomCount: recentLogs.length,
        recentRecordCount: recentRecords.length,
        medications: profile === null || profile === void 0 ? void 0 : profile.medications,
        questionsToAsk: data.questionsToAsk || [],
        userNotes: data.userNotes || '',
        summaryText,
        generatedAt: new Date(),
    };
    const ref = firebase_1.db
        .collection('doctorSummaries').doc(uid).collection('summaries').doc();
    await ref.set(Object.assign(Object.assign({}, summaryDoc), { id: ref.id }));
    return { summaryId: ref.id, summary: summaryDoc };
});
//# sourceMappingURL=generateDoctorSummary.js.map