import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db, storage } from '../config/firebase';
import { verifyAuth } from '../middleware/auth';

export const deleteAccount = functions.https.onCall(async (data, context) => {
  const uid = verifyAuth(context);

  // Delete all Firestore data
  const batch = db.batch();

  const collections = [
    db.collection('profiles').doc(uid),
    db.collection('privacySettings').doc(uid),
    db.collection('users').doc(uid),
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
    const snap = await db.collection(parent).doc(uid).collection(sub).get();
    snap.docs.forEach(doc => batch.delete(doc.ref));
    batch.delete(db.collection(parent).doc(uid));
  }

  await batch.commit();

  // Delete Storage files
  try {
    await storage.bucket().deleteFiles({ prefix: `users/${uid}/` });
  } catch (err) {
    // Log but don't fail — storage cleanup can retry via scheduled function
    console.error(`Storage cleanup failed for user ${uid}:`, err);
  }

  // Delete Firebase Auth user
  await admin.auth().deleteUser(uid);

  return { success: true, message: 'Account and all associated data have been deleted.' };
});
