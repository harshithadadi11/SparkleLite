import * as functions from 'firebase-functions';
import { db } from '../config/firebase';
import { verifyAuth } from '../middleware/auth';
import { aiInsightEngine } from '../utils/aiInsightEngine';
import { GenerateInsightRequest, GenerateInsightResponse } from '../types/requests';

export const generateAIInsight = functions.https.onCall(
  async (data: GenerateInsightRequest, context) => {
    // 1. Verify auth
    const uid = verifyAuth(context);

    // 2. Validate request
    if (!data.logIds || !Array.isArray(data.logIds) || data.logIds.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'logIds must be a non-empty array');
    }
    if (data.logIds.length > 30) {
      throw new functions.https.HttpsError('invalid-argument', 'Maximum 30 logs per insight request');
    }

    // 3. Fetch the requested logs — verify ownership
    const logsRef = db.collection('symptomLogs').doc(uid).collection('logs');
    const logSnapshots = await Promise.all(
      data.logIds.map(id => logsRef.doc(id).get())
    );

    const logs = logSnapshots
      .filter(snap => snap.exists && snap.data()?.userId === uid)
      .map(snap => ({ id: snap.id, ...snap.data() }));

    if (logs.length === 0) {
      throw new functions.https.HttpsError('not-found', 'No valid logs found for the provided IDs');
    }

    // 4. Generate insight using deterministic engine
    const insight = aiInsightEngine(logs, uid);

    // 5. Save to Firestore
    const insightRef = db
      .collection('aiInsights')
      .doc(uid)
      .collection('insights')
      .doc();

    const insightDoc = {
      ...insight,
      id: insightRef.id,
      createdAt: new Date(),
    };

    await insightRef.set(insightDoc);

    return { insightId: insightRef.id, insight: insightDoc } as GenerateInsightResponse;
  }
);
