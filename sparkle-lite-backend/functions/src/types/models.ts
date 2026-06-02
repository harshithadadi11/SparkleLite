export type PeriodStatus = 'noPeriod' | 'started' | 'ongoing' | 'ended';
export type FlowLevel = 'none' | 'light' | 'medium' | 'heavy';
export type Mood = 'calm' | 'anxious' | 'tired' | 'irritable' | 'happy' | 'sad';
export type Symptom = 'cramps' | 'headache' | 'bloating' | 'fatigue' | 'nausea' | 'spotting' | 'irregularBleeding' | 'other';
export type RecordType = 'labReport' | 'prescription' | 'scanReport' | 'doctorVisitNote' | 'vaccinationRecord' | 'other';
export type LifeStage = 'generalWellness' | 'periodTracking' | 'fertilityPlanning' | 'pregnancy' | 'postpartum' | 'menopause';

export interface SymptomLog {
  id: string;
  userId: string;
  date: any; // FirebaseFirestore.Timestamp;
  periodStatus: PeriodStatus;
  flowLevel: FlowLevel;
  painLevel: number; // 0-10
  mood: Mood;
  symptoms: Symptom[];
  notes?: string;
  createdAt: any; // FirebaseFirestore.Timestamp;
  updatedAt: any; // FirebaseFirestore.Timestamp;
}

export interface HealthRecord {
  id: string;
  userId: string;
  title: string;
  recordType: RecordType;
  recordDate: any; // FirebaseFirestore.Timestamp;
  doctorName?: string;
  fileUrl?: string;
  storagePath?: string;
  notes?: string;
  createdAt: any; // FirebaseFirestore.Timestamp;
}

export interface AIInsight {
  id: string;
  userId: string;
  summary: string;
  possiblePattern: string;
  careGuidance: string;
  doctorQuestions: string[];
  disclaimer: string; // Must always equal REQUIRED_DISCLAIMER constant
  sourceLogIds: string[];
  createdAt: any; // FirebaseFirestore.Timestamp;
}

export interface DoctorSummary {
  id: string;
  userId: string;
  profileSnapshot: Partial<HealthProfile>;
  recentSymptoms: SymptomLog[];
  recentRecords: HealthRecord[];
  recentSymptomCount: number;
  recentRecordCount: number;
  medications?: string;
  questionsToAsk: string[];
  userNotes?: string;
  summaryText: string;
  generatedAt: any; // FirebaseFirestore.Timestamp;
}

export interface HealthProfile {
  userId: string;
  nameOrNickname: string;
  ageRange: string;
  lifeStage: LifeStage;
  menstrualCycleStatus?: string;
  knownConditions: string[];
  medications?: string;
  privacyPreference: 'standard' | 'enhanced';
  notificationsEnabled: boolean;
  useGenericNotifications: boolean;
  createdAt: any; // FirebaseFirestore.Timestamp;
  updatedAt: any; // FirebaseFirestore.Timestamp;
}

export interface FamilyMember {
  id: string;
  userId: string;
  nameOrNickname: string;
  relationship: 'spouse' | 'child' | 'parent' | 'sibling' | 'other';
  ageRange: string;
  notes?: string;
  createdAt: any; // FirebaseFirestore.Timestamp;
}

export interface PrivacySettings {
  userId: string;
  hideSensitiveDashboardDetails: boolean;
  useGenericNotificationText: boolean;
  requireConfirmationBeforeSharing: boolean;
  familyProfileAccessEnabled: boolean;
  updatedAt: any; // FirebaseFirestore.Timestamp;
}

export interface UserRecord {
  uid: string;
  email: string;
  displayName?: string;
  createdAt: any; // FirebaseFirestore.Timestamp;
  lastSignInAt?: any; // FirebaseFirestore.Timestamp;
  fcmToken?: string;
}
