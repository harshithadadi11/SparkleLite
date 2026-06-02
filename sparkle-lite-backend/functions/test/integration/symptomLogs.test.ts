import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { resolve } from 'path';

const rules = readFileSync(resolve(__dirname, '../../../firestore.rules'), 'utf8');

describe('Symptom Logs security rules', () => {
  let testEnv: any;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'sparkle-lite-symptom-test',
      firestore: { rules, host: 'localhost', port: 8080 },
    });
  });

  afterAll(() => testEnv.cleanup());

  test('authenticated user can write to their own logs with valid data', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertSucceeds(
      db.collection('symptomLogs').doc('user1').collection('logs').add({
        userId: 'user1',
        date: new Date(),
        periodStatus: 'started',
        painLevel: 5,
        mood: 'happy',
        createdAt: new Date()
      })
    );
  });

  test('user cannot write to logs without required fields', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(
      db.collection('symptomLogs').doc('user1').collection('logs').add({
        userId: 'user1',
        // missing date, periodStatus, etc.
      })
    );
  });

  test('user cannot write painLevel out of bounds', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(
      db.collection('symptomLogs').doc('user1').collection('logs').add({
        userId: 'user1',
        date: new Date(),
        periodStatus: 'started',
        painLevel: 11, // Invalid
        mood: 'happy',
        createdAt: new Date()
      })
    );
  });
});
