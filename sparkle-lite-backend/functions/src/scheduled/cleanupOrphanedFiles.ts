import * as functions from 'firebase-functions';
import { db, storage } from '../config/firebase';

// Runs daily at 2am UTC
export const cleanupOrphanedFiles = functions.pubsub
  .schedule('0 2 * * *')
  .timeZone('UTC')
  .onRun(async () => {
    const bucket = storage.bucket();
    const [files] = await bucket.getFiles({ prefix: 'users/' });

    for (const file of files) {
      // Path format: users/{userId}/records/{filename}
      const parts = file.name.split('/');
      if (parts.length < 4) continue;

      const userId = parts[1];

      // Check if a Firestore record references this file
      const recordsSnap = await db
        .collection('healthRecords').doc(userId).collection('records')
        .where('storagePath', '==', file.name)
        .limit(1).get();

      if (recordsSnap.empty) {
        console.log(`Deleting orphaned file: ${file.name}`);
        await file.delete();
      }
    }
  });
