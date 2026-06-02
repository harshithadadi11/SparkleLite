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
exports.sendNotificationToUser = sendNotificationToUser;
const admin = __importStar(require("firebase-admin"));
const firebase_1 = require("../config/firebase");
const GENERIC_NOTIFICATION_TITLE = 'Health reminder';
const GENERIC_NOTIFICATION_BODY = 'You have a health reminder. Open the app for details.';
async function sendNotificationToUser(userId, specificPayload, data) {
    var _a;
    // Fetch privacy settings
    const privacySnap = await firebase_1.db.collection('privacySettings').doc(userId).get();
    const privacy = privacySnap.data();
    // Fetch FCM token
    const userSnap = await firebase_1.db.collection('users').doc(userId).get();
    const fcmToken = (_a = userSnap.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
    if (!fcmToken)
        return;
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
//# sourceMappingURL=notificationHelper.js.map