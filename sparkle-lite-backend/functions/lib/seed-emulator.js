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
const admin = __importStar(require("firebase-admin"));
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
process.env.FIREBASE_STORAGE_EMULATOR_HOST = 'localhost:9199';
admin.initializeApp({ projectId: 'sparkle-lite-dev' });
const db = admin.firestore();
const auth = admin.auth();
async function seed() {
    console.log('Seeding emulator...');
    // Create test user
    const user = await auth.createUser({
        email: 'test@sparklelite.dev',
        password: 'Test1234!',
        displayName: 'Test User',
    });
    const uid = user.uid;
    // Profile
    await db.collection('profiles').doc(uid).set({
        userId: uid,
        nameOrNickname: 'Priya',
        ageRange: '25-34',
        lifeStage: 'periodTracking',
        knownConditions: [],
        privacyPreference: 'standard',
        notificationsEnabled: true,
        useGenericNotifications: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Privacy settings
    await db.collection('privacySettings').doc(uid).set({
        userId: uid,
        hideSensitiveDashboardDetails: false,
        useGenericNotificationText: true,
        requireConfirmationBeforeSharing: true,
        familyProfileAccessEnabled: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Symptom logs
    const logs = [
        { periodStatus: 'ongoing', flowLevel: 'medium', painLevel: 6, mood: 'tired', symptoms: ['cramps', 'bloating'], notes: 'Pain in the evening.' },
        { periodStatus: 'ongoing', flowLevel: 'heavy', painLevel: 8, mood: 'anxious', symptoms: ['cramps', 'fatigue', 'nausea'], notes: 'dizzy in the morning' },
        { periodStatus: 'ended', flowLevel: 'none', painLevel: 2, mood: 'calm', symptoms: [], notes: '' },
        { periodStatus: 'noPeriod', flowLevel: 'none', painLevel: 0, mood: 'happy', symptoms: [], notes: '' },
        { periodStatus: 'noPeriod', flowLevel: 'none', painLevel: 1, mood: 'calm', symptoms: ['headache'], notes: '' },
    ];
    for (let i = 0; i < logs.length; i++) {
        const date = new Date();
        date.setDate(date.getDate() - i * 5);
        await db.collection('symptomLogs').doc(uid).collection('logs').add(Object.assign(Object.assign({ userId: uid, date: admin.firestore.Timestamp.fromDate(date) }, logs[i]), { createdAt: admin.firestore.FieldValue.serverTimestamp(), updatedAt: admin.firestore.FieldValue.serverTimestamp() }));
    }
    // Health records
    const records = [
        { title: 'Blood Test Report', recordType: 'labReport', doctorName: 'Dr. Rao' },
        { title: 'Ultrasound Scan', recordType: 'scanReport', doctorName: 'Dr. Sharma' },
    ];
    for (let i = 0; i < records.length; i++) {
        const recordDate = new Date();
        recordDate.setDate(recordDate.getDate() - i * 10);
        await db.collection('healthRecords').doc(uid).collection('records').add(Object.assign(Object.assign({ userId: uid, recordDate: admin.firestore.Timestamp.fromDate(recordDate), fileUrl: null, notes: 'Uploaded before appointment.' }, records[i]), { createdAt: admin.firestore.FieldValue.serverTimestamp() }));
    }
    // Family member
    await db.collection('familyMembers').doc(uid).collection('members').add({
        userId: uid,
        nameOrNickname: 'Amma',
        relationship: 'parent',
        ageRange: '55-64',
        notes: 'Has diabetes.',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Seeded user: ${uid} (test@sparklelite.dev / Test1234!)`);
}
seed().catch(console.error);
//# sourceMappingURL=seed-emulator.js.map