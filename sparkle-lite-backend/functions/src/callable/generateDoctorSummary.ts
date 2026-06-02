import * as functions from 'firebase-functions';
import { db } from '../config/firebase';
import { verifyAuth } from '../middleware/auth';
import { summaryBuilder } from '../utils/summaryBuilder';

export const generateDoctorSummary = functions.https.onCall(
  async (data: { questionsToAsk?: string[]; userNotes?: string }, context) => {
    const uid = verifyAuth(context);

    // Fetch profile
    const profileSnap = await db.collection('profiles').doc(uid).get();
    const profile = profileSnap.exists ? profileSnap.data() : null;

    // Fetch last 5 symptom logs
    const logsSnap = await db
      .collection('symptomLogs').doc(uid).collection('logs')
      .orderBy('date', 'desc').limit(5).get();
    const recentLogs = logsSnap.docs.map(d => ({ id: d.id, ...d.data() }));

    // Fetch records from last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const recordsSnap = await db
      .collection('healthRecords').doc(uid).collection('records')
      .where('recordDate', '>=', thirtyDaysAgo)
      .orderBy('recordDate', 'desc').get();
    const recentRecords = recordsSnap.docs.map(d => ({ id: d.id, ...d.data() }));

    // Build the summary
    const summaryText = summaryBuilder({
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
      medications: profile?.medications,
      questionsToAsk: data.questionsToAsk || [],
      userNotes: data.userNotes || '',
      summaryText,
      generatedAt: new Date(),
    };

    const ref = db
      .collection('doctorSummaries').doc(uid).collection('summaries').doc();
    await ref.set({ ...summaryDoc, id: ref.id });

    return { summaryId: ref.id, summary: summaryDoc };
  }
);
