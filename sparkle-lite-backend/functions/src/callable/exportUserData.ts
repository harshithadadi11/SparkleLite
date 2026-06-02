import * as functions from 'firebase-functions';
import { db } from '../config/firebase';
import { verifyAuth } from '../middleware/auth';

export const exportUserData = functions.https.onCall(async (data, context) => {
  const uid = verifyAuth(context);

  const [
    profileSnap,
    privacySnap,
    logsSnap,
    recordsSnap,
    insightsSnap,
    summariesSnap,
    membersSnap,
  ] = await Promise.all([
    db.collection('profiles').doc(uid).get(),
    db.collection('privacySettings').doc(uid).get(),
    db.collection('symptomLogs').doc(uid).collection('logs').get(),
    db.collection('healthRecords').doc(uid).collection('records').get(),
    db.collection('aiInsights').doc(uid).collection('insights').get(),
    db.collection('doctorSummaries').doc(uid).collection('summaries').get(),
    db.collection('familyMembers').doc(uid).collection('members').get(),
  ]);

  return {
    exportedAt: new Date().toISOString(),
    profile: profileSnap.data() || null,
    privacySettings: privacySnap.data() || null,
    symptomLogs: logsSnap.docs.map(d => d.data()),
    healthRecords: recordsSnap.docs.map(d => d.data()),
    aiInsights: insightsSnap.docs.map(d => d.data()),
    doctorSummaries: summariesSnap.docs.map(d => d.data()),
    familyMembers: membersSnap.docs.map(d => d.data()),
  };
});
