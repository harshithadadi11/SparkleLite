import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { resolve } from 'path';

const rules = readFileSync(resolve(__dirname, '../../../firestore.rules'), 'utf8');

describe('Health Records security rules', () => {
  let testEnv: any;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'sparkle-lite-records-test',
      firestore: { rules, host: 'localhost', port: 8080 },
    });
  });

  afterAll(() => testEnv.cleanup());

  test('authenticated user can write to their own records with valid data', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertSucceeds(
      db.collection('healthRecords').doc('user1').collection('records').add({
        userId: 'user1',
        title: 'Blood test',
        recordType: 'labReport',
        recordDate: new Date(),
        createdAt: new Date()
      })
    );
  });

  test('user cannot write to records without required title', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    await assertFails(
      db.collection('healthRecords').doc('user1').collection('records').add({
        userId: 'user1',
        recordType: 'labReport',
        recordDate: new Date(),
        createdAt: new Date()
        // missing title
      })
    );
  });

  test('user cannot read other users records', async () => {
    const db = testEnv.authenticatedContext('user2').firestore();
    await assertFails(
      db.collection('healthRecords').doc('user1').collection('records').get()
    );
  });
});
