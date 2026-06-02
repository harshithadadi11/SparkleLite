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
exports.generateAIInsight = void 0;
const functions = __importStar(require("firebase-functions"));
const firebase_1 = require("../config/firebase");
const auth_1 = require("../middleware/auth");
const aiInsightEngine_1 = require("../utils/aiInsightEngine");
exports.generateAIInsight = functions.https.onCall(async (data, context) => {
    // 1. Verify auth
    const uid = (0, auth_1.verifyAuth)(context);
    // 2. Validate request
    if (!data.logIds || !Array.isArray(data.logIds) || data.logIds.length === 0) {
        throw new functions.https.HttpsError('invalid-argument', 'logIds must be a non-empty array');
    }
    if (data.logIds.length > 30) {
        throw new functions.https.HttpsError('invalid-argument', 'Maximum 30 logs per insight request');
    }
    // 3. Fetch the requested logs — verify ownership
    const logsRef = firebase_1.db.collection('symptomLogs').doc(uid).collection('logs');
    const logSnapshots = await Promise.all(data.logIds.map(id => logsRef.doc(id).get()));
    const logs = logSnapshots
        .filter(snap => { var _a; return snap.exists && ((_a = snap.data()) === null || _a === void 0 ? void 0 : _a.userId) === uid; })
        .map(snap => (Object.assign({ id: snap.id }, snap.data())));
    if (logs.length === 0) {
        throw new functions.https.HttpsError('not-found', 'No valid logs found for the provided IDs');
    }
    // 4. Generate insight using deterministic engine
    const insight = (0, aiInsightEngine_1.aiInsightEngine)(logs, uid);
    // 5. Save to Firestore
    const insightRef = firebase_1.db
        .collection('aiInsights')
        .doc(uid)
        .collection('insights')
        .doc();
    const insightDoc = Object.assign(Object.assign({}, insight), { id: insightRef.id, createdAt: new Date() });
    await insightRef.set(insightDoc);
    return { insightId: insightRef.id, insight: insightDoc };
});
//# sourceMappingURL=generateAIInsight.js.map