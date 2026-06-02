import * as admin from 'firebase-admin';
import { db } from '../config/firebase';

const GENERIC_NOTIFICATION_TITLE = 'Health reminder';
const GENERIC_NOTIFICATION_BODY = 'You have a health reminder. Open the app for details.';

interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export async function sendNotificationToUser(
  userId: string,
  specificPayload: NotificationPayload,
  data?: Record<string, string>
): Promise<void> {
  // Fetch privacy settings
  const privacySnap = await db.collection('privacySettings').doc(userId).get();
  const privacy = privacySnap.data();

  // Fetch FCM token
  const userSnap = await db.collection('users').doc(userId).get();
  const fcmToken = userSnap.data()?.fcmToken;

  if (!fcmToken) return;

  // Enforce generic notification text if privacy setting is on (default: on)
  const useGeneric = !privacy || privacy.useGenericNotificationText !== false;

  const payload = useGeneric
    ? { title: GENERIC_NOTIFICATION_TITLE, body: GENERIC_NOTIFICATION_BODY }
    : specificPayload;

  await admin.messaging().send({
    token: fcmToken,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: data || {},
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  });
}
