import * as functions from 'firebase-functions';
import { db, storage } from '../config/firebase';

// Triggered when Firebase Auth user is deleted (e.g. from Firebase console)
export const onUserDelete = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;

  const subcollections = [
    { parent: 'symptomLogs', sub: 'logs' },
    { parent: 'healthRecords', sub: 'records' },
    { parent: 'aiInsights', sub: 'insights' },
    { parent: 'doctorSummaries', sub: 'summaries' },
    { parent: 'familyMembers', sub: 'members' },
  ];

  const batch = db.batch();

  for (const { parent, sub } of subcollections) {
    const snap = await db.collection(parent).doc(uid).collection(sub).get();
    snap.docs.forEach(doc => batch.delete(doc.ref));
    batch.delete(db.collection(parent).doc(uid));
  }

  batch.delete(db.collection('profiles').doc(uid));
  batch.delete(db.collection('privacySettings').doc(uid));
  batch.delete(db.collection('users').doc(uid));

  await batch.commit();

  try {
    await storage.bucket().deleteFiles({ prefix: `users/${uid}/` });
  } catch (err) {
    console.error(`onUserDelete storage cleanup failed for ${uid}:`, err);
  }

  console.log(`All data deleted for user: ${uid}`);
});
