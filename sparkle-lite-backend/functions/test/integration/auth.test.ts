import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { resolve } from 'path';

const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

describe('Firestore security rules', () => {
  let testEnv: any;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'sparkle-lite-test',
      firestore: { rules },
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  it('allows user to read their own profile', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(alice.firestore().collection('profiles').doc('alice').get());
  });
});
