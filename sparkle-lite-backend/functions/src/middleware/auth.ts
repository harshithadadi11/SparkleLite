import * as functions from 'firebase-functions';

export function verifyAuth(context: functions.https.CallableContext): string {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'This function requires authentication.'
    );
  }
  return context.auth.uid;
}
