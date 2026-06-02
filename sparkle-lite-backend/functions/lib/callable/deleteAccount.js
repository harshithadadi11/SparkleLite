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
exports.deleteAccount = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const firebase_1 = require("../config/firebase");
const auth_1 = require("../middleware/auth");
exports.deleteAccount = functions.https.onCall(async (data, context) => {
    const uid = (0, auth_1.verifyAuth)(context);
    // Delete all Firestore data
    const batch = firebase_1.db.batch();
    const collections = [
        firebase_1.db.collection('profiles').doc(uid),
        firebase_1.db.collection('privacySettings').doc(uid),
        firebase_1.db.collection('users').doc(uid),
    ];
    for (const ref of collections) {
        batch.delete(ref);
    }
    // Delete subcollections
    const subcollections = [
        { parent: 'symptomLogs', sub: 'logs' },
        { parent: 'healthRecords', sub: 'records' },
        { parent: 'aiInsights', sub: 'insights' },
        { parent: 'doctorSummaries', sub: 'summaries' },
        { parent: 'familyMembers', sub: 'members' },
    ];
    for (const { parent, sub } of subcollections) {
        const snap = await firebase_1.db.collection(parent).doc(uid).collection(sub).get();
        snap.docs.forEach(doc => batch.delete(doc.ref));
        batch.delete(firebase_1.db.collection(parent).doc(uid));
    }
    await batch.commit();
    // Delete Storage files
    try {
        await firebase_1.storage.bucket().deleteFiles({ prefix: `users/${uid}/` });
    }
    catch (err) {
        // Log but don't fail — storage cleanup can retry via scheduled function
        console.error(`Storage cleanup failed for user ${uid}:`, err);
    }
    // Delete Firebase Auth user
    await admin.auth().deleteUser(uid);
    return { success: true, message: 'Account and all associated data have been deleted.' };
});
//# sourceMappingURL=deleteAccount.js.map