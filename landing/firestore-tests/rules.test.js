// iEye Firestore security-rules unit tests (#43).
//
// Runs against the Firestore emulator only — NO real Firebase project, NO
// network, NO secrets. Launched via `npm test` (firebase emulators:exec).
//
// The payments + contribution subsystem was removed (iEye takes no donations),
// so these tests now cover only the surviving surface: the per-user profile /
// waitlist doc, and default-deny for everything else. Every assertion models a
// hostile client trying to do something it must not be able to do.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { beforeAll, afterAll, beforeEach, describe, test } from 'vitest';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ID = 'ieye-rules-test';

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

afterAll(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

const alice = () => testEnv.authenticatedContext('alice').firestore();
const bob = () => testEnv.authenticatedContext('bob').firestore();
const anon = () => testEnv.unauthenticatedContext().firestore();

// Seed data through a rules-bypassing context (simulates the trusted backend).
async function seed(fn) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

// ===========================================================================
// users — the only client-writable collection (profile + waitlist)
// ===========================================================================
describe('users', () => {
  test('owner can read their own profile', async () => {
    await seed((db) => setDoc(doc(db, 'users/alice'), { displayName: 'Alice' }));
    await assertSucceeds(getDoc(doc(alice(), 'users/alice')));
  });

  test('a user CANNOT read another user\'s profile', async () => {
    await seed((db) => setDoc(doc(db, 'users/alice'), { displayName: 'Alice' }));
    await assertFails(getDoc(doc(bob(), 'users/alice')));
  });

  test('anonymous CANNOT read any profile', async () => {
    await seed((db) => setDoc(doc(db, 'users/alice'), { displayName: 'Alice' }));
    await assertFails(getDoc(doc(anon(), 'users/alice')));
  });

  test('owner can create their own profile (name/email/consent)', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'users/alice'), {
        displayName: 'Alice',
        email: 'alice@example.com',
        consentVersion: 'v1',
      })
    );
  });

  test('user CANNOT create a profile under another uid', async () => {
    await assertFails(setDoc(doc(alice(), 'users/bob'), { displayName: 'spoof' }));
  });

  test('owner can update their own profile', async () => {
    await seed((db) => setDoc(doc(db, 'users/alice'), { displayName: 'Alice' }));
    await assertSucceeds(updateDoc(doc(alice(), 'users/alice'), { displayName: 'Alice N.' }));
  });

  test('a user CANNOT update another user\'s profile', async () => {
    await seed((db) => setDoc(doc(db, 'users/alice'), { displayName: 'Alice' }));
    await assertFails(updateDoc(doc(bob(), 'users/alice'), { displayName: 'hijacked' }));
  });

  test('owner can delete their own profile (self-service erasure)', async () => {
    await seed((db) => setDoc(doc(db, 'users/alice'), { displayName: 'Alice' }));
    await assertSucceeds(deleteDoc(doc(alice(), 'users/alice')));
  });
});

// ===========================================================================
// default deny — every other collection is closed to all clients
// ===========================================================================
describe('default deny', () => {
  for (const path of ['secrets/x', 'contributions/c1', 'publicSupporters/s1', 'mail/m1']) {
    test(`clients cannot read or write ${path}`, async () => {
      await seed((db) => setDoc(doc(db, path), { seeded: true }));
      await assertFails(getDoc(doc(alice(), path)));
      await assertFails(setDoc(doc(alice(), path), { x: 1 }));
      await assertFails(setDoc(doc(anon(), path), { x: 1 }));
    });
  }
});
