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
exports.cleanupOrphanedFiles = void 0;
const functions = __importStar(require("firebase-functions"));
const firebase_1 = require("../config/firebase");
// Runs daily at 2am UTC
exports.cleanupOrphanedFiles = functions.pubsub
    .schedule('0 2 * * *')
    .timeZone('UTC')
    .onRun(async () => {
    const bucket = firebase_1.storage.bucket();
    const [files] = await bucket.getFiles({ prefix: 'users/' });
    for (const file of files) {
        // Path format: users/{userId}/records/{filename}
        const parts = file.name.split('/');
        if (parts.length < 4)
            continue;
        const userId = parts[1];
        // Check if a Firestore record references this file
        const recordsSnap = await firebase_1.db
            .collection('healthRecords').doc(userId).collection('records')
            .where('storagePath', '==', file.name)
            .limit(1).get();
        if (recordsSnap.empty) {
            console.log(`Deleting orphaned file: ${file.name}`);
            await file.delete();
        }
    }
});
//# sourceMappingURL=cleanupOrphanedFiles.js.map