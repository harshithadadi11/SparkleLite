import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { resolve } from 'path';

const rules = readFileSync(resolve(__dirname, '../../../firestore.rules'), 'utf8');

describe('Delete Account (Privacy) security rules', () => {
  let testEnv: any;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'sparkle-lite-delete-test',
      firestore: { rules, host: 'localhost', port: 8080 },
    });
  });

  afterAll(() => testEnv.cleanup());

  test('authenticated user can delete their own profile', async () => {
    const db = testEnv.authenticatedContext('user1').firestore();
    // Assuming the document exists or we just try to delete it
    await assertSucceeds(
      db.collection('profiles').doc('user1').delete()
    );
  });

  test('user cannot delete another users profile', async () => {
    const db = testEnv.authenticatedContext('user2').firestore();
    await assertFails(
      db.collection('profiles').doc('user1').delete()
    );
  });
});
