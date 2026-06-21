// iEye Firestore security-rules unit tests (#43).
//
// Runs against the Firestore emulator only — NO real Firebase project, NO
// network, NO secrets. Launched via `npm test` (firebase emulators:exec).
//
// These tests are the proof that the rules protect data even if the frontend
// is fully compromised: every assertion models a hostile client trying to do
// something it must not be able to do.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { beforeAll, afterAll, beforeEach, describe, test } from 'vitest';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
} from 'firebase/firestore';

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

// ---- auth context helpers --------------------------------------------------

const alice = () => testEnv.authenticatedContext('alice').firestore();
const bob = () => testEnv.authenticatedContext('bob').firestore();
const anon = () => testEnv.unauthenticatedContext().firestore();
// Admin is a CUSTOM CLAIM, minted only by the Admin SDK in production. Here we
// mock the claim — proving rules trust the claim, not any Firestore field.
const admin = () =>
  testEnv.authenticatedContext('rootadmin', { admin: true }).firestore();

// Seed data through a rules-bypassing context (simulates trusted backend).
async function seed(fn) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

// ===========================================================================
// users
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

  test('owner can create their own profile with opt-in-named flags', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'users/alice'), {
        displayName: 'Alice',
        optInDisplayName: true,
        optInDisplayAmount: false,
        consentVersion: 'v1',
      })
    );
  });

  test('user CANNOT create a profile under another uid', async () => {
    await assertFails(setDoc(doc(alice(), 'users/bob'), { displayName: 'spoof' }));
  });

  test('owner can update their own opt-in-named flag', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users/alice'), { displayName: 'Alice', optInDisplayName: false })
    );
    await assertSucceeds(
      updateDoc(doc(alice(), 'users/alice'), { optInDisplayName: true })
    );
  });

  test('user CANNOT elevate themselves to admin via an `admin` field on create', async () => {
    await assertFails(
      setDoc(doc(alice(), 'users/alice'), { displayName: 'Alice', admin: true })
    );
  });

  test('user CANNOT grant themselves a `role` field', async () => {
    await seed((db) => setDoc(doc(db, 'users/alice'), { displayName: 'Alice' }));
    await assertFails(
      updateDoc(doc(alice(), 'users/alice'), { role: 'admin' })
    );
  });

  test('user CANNOT smuggle in `customClaims`', async () => {
    await seed((db) => setDoc(doc(db, 'users/alice'), { displayName: 'Alice' }));
    await assertFails(
      updateDoc(doc(alice(), 'users/alice'), { customClaims: { admin: true } })
    );
  });

  test('admin can read any profile', async () => {
    await seed((db) => setDoc(doc(db, 'users/alice'), { displayName: 'Alice' }));
    await assertSucceeds(getDoc(doc(admin(), 'users/alice')));
  });

  test('owner can delete their own profile (self-service erasure)', async () => {
    await seed((db) => setDoc(doc(db, 'users/alice'), { displayName: 'Alice' }));
    await assertSucceeds(deleteDoc(doc(alice(), 'users/alice')));
  });
});

// ===========================================================================
// contributions  (clients NEVER write)
// ===========================================================================
describe('contributions', () => {
  test('owner can read their own contribution', async () => {
    await seed((db) =>
      setDoc(doc(db, 'contributions/c1'), { ownerUid: 'alice', amountWei: '1000', isPublic: false })
    );
    await assertSucceeds(getDoc(doc(alice(), 'contributions/c1')));
  });

  test('a user CANNOT read another user\'s (private) contribution', async () => {
    await seed((db) =>
      setDoc(doc(db, 'contributions/c1'), { ownerUid: 'alice', amountWei: '1000', isPublic: false })
    );
    await assertFails(getDoc(doc(bob(), 'contributions/c1')));
  });

  test('a user CANNOT read another user\'s contribution even if marked public', async () => {
    // Public visibility is surfaced via the publicSupporters projection, never
    // by exposing the raw contribution doc.
    await seed((db) =>
      setDoc(doc(db, 'contributions/c1'), { ownerUid: 'alice', amountWei: '1000', isPublic: true })
    );
    await assertFails(getDoc(doc(bob(), 'contributions/c1')));
  });

  test('a client CANNOT create a contribution', async () => {
    await assertFails(
      setDoc(doc(alice(), 'contributions/c1'), { ownerUid: 'alice', amountWei: '999999' })
    );
  });

  test('a client CANNOT create a contribution even for themselves', async () => {
    await assertFails(
      setDoc(doc(alice(), 'contributions/mine'), { ownerUid: 'alice', amountWei: '1' })
    );
  });

  test('a client CANNOT update an existing contribution (e.g. inflate amount)', async () => {
    await seed((db) =>
      setDoc(doc(db, 'contributions/c1'), { ownerUid: 'alice', amountWei: '1000' })
    );
    await assertFails(
      updateDoc(doc(alice(), 'contributions/c1'), { amountWei: '9999999' })
    );
  });

  test('a client CANNOT mark their own contribution public', async () => {
    await seed((db) =>
      setDoc(doc(db, 'contributions/c1'), { ownerUid: 'alice', isPublic: false })
    );
    await assertFails(
      updateDoc(doc(alice(), 'contributions/c1'), { isPublic: true })
    );
  });

  test('even admin (via client SDK) CANNOT write contributions — backend Admin SDK only', async () => {
    // Deliberate: contributions are immutable from any client, including an
    // admin client. Writes happen through the Admin SDK / Functions, which
    // bypass rules. This keeps the ledger backend-authoritative.
    await assertFails(
      setDoc(doc(admin(), 'contributions/c2'), { ownerUid: 'bob', amountWei: '1' })
    );
  });

  test('admin can read any contribution', async () => {
    await seed((db) =>
      setDoc(doc(db, 'contributions/c1'), { ownerUid: 'alice', amountWei: '1000', isPublic: false })
    );
    await assertSucceeds(getDoc(doc(admin(), 'contributions/c1')));
  });
});

// ===========================================================================
// publicSupporters  (world-readable projection; backend/admin writes only)
// ===========================================================================
describe('publicSupporters', () => {
  test('anonymous CAN read the public supporter wall', async () => {
    await seed((db) =>
      setDoc(doc(db, 'publicSupporters/s1'), { displayName: 'Generous Friend' })
    );
    await assertSucceeds(getDoc(doc(anon(), 'publicSupporters/s1')));
  });

  test('a signed-in user CAN read the public supporter wall', async () => {
    await seed((db) =>
      setDoc(doc(db, 'publicSupporters/s1'), { displayName: 'Generous Friend' })
    );
    await assertSucceeds(getDoc(doc(alice(), 'publicSupporters/s1')));
  });

  test('a client CANNOT write themselves onto the supporter wall', async () => {
    await assertFails(
      setDoc(doc(alice(), 'publicSupporters/alice'), { displayName: 'Look At Me' })
    );
  });

  test('an anonymous client CANNOT write the supporter wall', async () => {
    await assertFails(
      setDoc(doc(anon(), 'publicSupporters/x'), { displayName: 'spam' })
    );
  });

  test('admin can write the supporter wall (projection build)', async () => {
    await assertSucceeds(
      setDoc(doc(admin(), 'publicSupporters/s1'), { displayName: 'Consented Name' })
    );
  });
});

// ===========================================================================
// contributorRequests  (owner-scoped; admin advances status)
// ===========================================================================
describe('contributorRequests', () => {
  test('owner can create their own request starting at status "requested"', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'contributorRequests/r1'), {
        ownerUid: 'alice',
        status: 'requested',
        skills: 'rust',
      })
    );
  });

  test('user CANNOT create a request owned by someone else', async () => {
    await assertFails(
      setDoc(doc(alice(), 'contributorRequests/r1'), {
        ownerUid: 'bob',
        status: 'requested',
      })
    );
  });

  test('user CANNOT self-promote by creating a request already "vetted"', async () => {
    await assertFails(
      setDoc(doc(alice(), 'contributorRequests/r1'), {
        ownerUid: 'alice',
        status: 'vetted',
      })
    );
  });

  test('user CANNOT self-promote to "invited"', async () => {
    await assertFails(
      setDoc(doc(alice(), 'contributorRequests/r1'), {
        ownerUid: 'alice',
        status: 'invited',
      })
    );
  });

  test('owner can read their own request', async () => {
    await seed((db) =>
      setDoc(doc(db, 'contributorRequests/r1'), { ownerUid: 'alice', status: 'requested' })
    );
    await assertSucceeds(getDoc(doc(alice(), 'contributorRequests/r1')));
  });

  test('a user CANNOT read another user\'s request', async () => {
    await seed((db) =>
      setDoc(doc(db, 'contributorRequests/r1'), { ownerUid: 'alice', status: 'requested' })
    );
    await assertFails(getDoc(doc(bob(), 'contributorRequests/r1')));
  });

  test('owner CANNOT advance their own request status to "vetted"', async () => {
    await seed((db) =>
      setDoc(doc(db, 'contributorRequests/r1'), { ownerUid: 'alice', status: 'requested' })
    );
    await assertFails(
      updateDoc(doc(alice(), 'contributorRequests/r1'), { status: 'vetted' })
    );
  });

  test('admin can read all requests', async () => {
    await seed((db) =>
      setDoc(doc(db, 'contributorRequests/r1'), { ownerUid: 'alice', status: 'requested' })
    );
    await assertSucceeds(getDoc(doc(admin(), 'contributorRequests/r1')));
  });

  test('admin can advance a request to "vetted"', async () => {
    await seed((db) =>
      setDoc(doc(db, 'contributorRequests/r1'), { ownerUid: 'alice', status: 'requested' })
    );
    await assertSucceeds(
      updateDoc(doc(admin(), 'contributorRequests/r1'), { status: 'vetted' })
    );
  });

  test('admin CANNOT regress a request status (forward-only is structural)', async () => {
    await seed((db) =>
      setDoc(doc(db, 'contributorRequests/r1'), { ownerUid: 'alice', status: 'invited' })
    );
    await assertFails(
      updateDoc(doc(admin(), 'contributorRequests/r1'), { status: 'vetted' })
    );
  });

  test('admin CANNOT reassign a request to another owner', async () => {
    await seed((db) =>
      setDoc(doc(db, 'contributorRequests/r1'), { ownerUid: 'alice', status: 'requested' })
    );
    await assertFails(
      updateDoc(doc(admin(), 'contributorRequests/r1'), { ownerUid: 'bob', status: 'vetted' })
    );
  });
});

// ===========================================================================
// backend-only collections — held shut by default-deny (Admin SDK writes only)
// ===========================================================================
describe('backend-only collections', () => {
  for (const path of ['consentLog/x', 'supporterIndex/alice', 'adminAudit/x', 'mail/x']) {
    test(`clients cannot read or write ${path}`, async () => {
      await seed((db) => setDoc(doc(db, path), { seeded: true }));
      await assertFails(getDoc(doc(admin(), path)));
      await assertFails(setDoc(doc(admin(), path), { x: 1 }));
      await assertFails(setDoc(doc(alice(), path), { x: 1 }));
    });
  }
});

// ===========================================================================
// default deny
// ===========================================================================
describe('default deny', () => {
  test('an unknown collection is denied to clients', async () => {
    await assertFails(getDoc(doc(alice(), 'secrets/whatever')));
  });

  test('an unknown collection cannot be written by clients', async () => {
    await assertFails(setDoc(doc(alice(), 'secrets/whatever'), { x: 1 }));
  });

  test('even admin clients are denied on undefined collections', async () => {
    await assertFails(setDoc(doc(admin(), 'arbitrary/doc'), { x: 1 }));
  });
});
