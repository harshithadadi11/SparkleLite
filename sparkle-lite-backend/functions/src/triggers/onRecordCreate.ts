import * as functions from 'firebase-functions';

export const onRecordCreate = functions.firestore
  .document('healthRecords/{userId}/records/{recordId}')
  .onCreate(async (snap, context) => {
    // Post-upload processing hook placeholder
    // Currently no-op.
    return null;
  });
