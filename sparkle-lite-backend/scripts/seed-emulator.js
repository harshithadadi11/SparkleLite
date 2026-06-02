"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
var admin = require("firebase-admin");
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
process.env.FIREBASE_STORAGE_EMULATOR_HOST = 'localhost:9199';
admin.initializeApp({ projectId: 'sparkle-lite-dev' });
var db = admin.firestore();
var auth = admin.auth();
function seed() {
    return __awaiter(this, void 0, void 0, function () {
        var user, uid, logs, i, date, records, i, recordDate;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    console.log('Seeding emulator...');
                    return [4 /*yield*/, auth.createUser({
                            email: 'test@sparklelite.dev',
                            password: 'Test1234!',
                            displayName: 'Test User',
                        })];
                case 1:
                    user = _a.sent();
                    uid = user.uid;
                    // Profile
                    return [4 /*yield*/, db.collection('profiles').doc(uid).set({
                            userId: uid,
                            nameOrNickname: 'Priya',
                            ageRange: '25-34',
                            lifeStage: 'periodTracking',
                            knownConditions: [],
                            privacyPreference: 'standard',
                            notificationsEnabled: true,
                            useGenericNotifications: true,
                            createdAt: admin.firestore.FieldValue.serverTimestamp(),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                        })];
                case 2:
                    // Profile
                    _a.sent();
                    // Privacy settings
                    return [4 /*yield*/, db.collection('privacySettings').doc(uid).set({
                            userId: uid,
                            hideSensitiveDashboardDetails: false,
                            useGenericNotificationText: true,
                            requireConfirmationBeforeSharing: true,
                            familyProfileAccessEnabled: false,
                            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                        })];
                case 3:
                    // Privacy settings
                    _a.sent();
                    logs = [
                        { periodStatus: 'ongoing', flowLevel: 'medium', painLevel: 6, mood: 'tired', symptoms: ['cramps', 'bloating'], notes: 'Pain in the evening.' },
                        { periodStatus: 'ongoing', flowLevel: 'heavy', painLevel: 8, mood: 'anxious', symptoms: ['cramps', 'fatigue', 'nausea'], notes: 'dizzy in the morning' },
                        { periodStatus: 'ended', flowLevel: 'none', painLevel: 2, mood: 'calm', symptoms: [], notes: '' },
                        { periodStatus: 'noPeriod', flowLevel: 'none', painLevel: 0, mood: 'happy', symptoms: [], notes: '' },
                        { periodStatus: 'noPeriod', flowLevel: 'none', painLevel: 1, mood: 'calm', symptoms: ['headache'], notes: '' },
                    ];
                    i = 0;
                    _a.label = 4;
                case 4:
                    if (!(i < logs.length)) return [3 /*break*/, 7];
                    date = new Date();
                    date.setDate(date.getDate() - i * 5);
                    return [4 /*yield*/, db.collection('symptomLogs').doc(uid).collection('logs').add(__assign(__assign({ userId: uid, date: admin.firestore.Timestamp.fromDate(date) }, logs[i]), { createdAt: admin.firestore.FieldValue.serverTimestamp(), updatedAt: admin.firestore.FieldValue.serverTimestamp() }))];
                case 5:
                    _a.sent();
                    _a.label = 6;
                case 6:
                    i++;
                    return [3 /*break*/, 4];
                case 7:
                    records = [
                        { title: 'Blood Test Report', recordType: 'labReport', doctorName: 'Dr. Rao' },
                        { title: 'Ultrasound Scan', recordType: 'scanReport', doctorName: 'Dr. Sharma' },
                    ];
                    i = 0;
                    _a.label = 8;
                case 8:
                    if (!(i < records.length)) return [3 /*break*/, 11];
                    recordDate = new Date();
                    recordDate.setDate(recordDate.getDate() - i * 10);
                    return [4 /*yield*/, db.collection('healthRecords').doc(uid).collection('records').add(__assign(__assign({ userId: uid, recordDate: admin.firestore.Timestamp.fromDate(recordDate), fileUrl: null, notes: 'Uploaded before appointment.' }, records[i]), { createdAt: admin.firestore.FieldValue.serverTimestamp() }))];
                case 9:
                    _a.sent();
                    _a.label = 10;
                case 10:
                    i++;
                    return [3 /*break*/, 8];
                case 11: 
                // Family member
                return [4 /*yield*/, db.collection('familyMembers').doc(uid).collection('members').add({
                        userId: uid,
                        nameOrNickname: 'Amma',
                        relationship: 'parent',
                        ageRange: '55-64',
                        notes: 'Has diabetes.',
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    })];
                case 12:
                    // Family member
                    _a.sent();
                    console.log("Seeded user: ".concat(uid, " (test@sparklelite.dev / Test1234!)"));
                    return [2 /*return*/];
            }
        });
    });
}
seed().catch(console.error);
