// Firestore security-rules tests (run against the Firebase emulator).
//
// Local run (requires JDK 21+):
//   firebase emulators:exec --only firestore --project demo-energy-tracker \
//     "npm --prefix rules-test test"
//
// CI runs this automatically (.github/workflows/firebase-rules.yml).

import { before, after, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
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
} from 'firebase/firestore';

const here = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(here, '../firestore.rules'), 'utf8');

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-energy-tracker',
    firestore: { rules, host: '127.0.0.1', port: 8080 },
  });
});

after(async () => {
  await env?.cleanup();
});

const db = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

const validUser = (uid, overrides = {}) => ({
  uid,
  fullName: 'Alice',
  email: 'alice@example.com',
  tnbAccountNo: '123456789012',
  tariffType: 'domestic',
  monthlyBudget: 150,
  onboardingCompleted: false,
  ...overrides,
});

test('owner can read their own user doc', async () => {
  await assertSucceeds(getDoc(doc(db('alice'), 'users/alice')));
});

test('a user cannot read another user doc', async () => {
  await assertFails(getDoc(doc(db('bob'), 'users/alice')));
});

test('unauthenticated read is denied', async () => {
  await assertFails(getDoc(doc(anon(), 'users/alice')));
});

test('owner can create a valid user doc', async () => {
  await assertSucceeds(
    setDoc(doc(db('alice'), 'users/alice'), validUser('alice')),
  );
});

test('create with invalid tariffType is denied', async () => {
  await assertFails(
    setDoc(
      doc(db('carol'), 'users/carol'),
      validUser('carol', { tariffType: 'evil' }),
    ),
  );
});

test('create with a mismatched uid is denied', async () => {
  await assertFails(
    setDoc(doc(db('alice'), 'users/alice'), validUser('someone-else')),
  );
});

test('owner can write a valid reading; another user cannot', async () => {
  const payload = {
    reading: 100,
    kwh: 5,
    date: new Date(),
    tariffType: 'domestic',
  };
  await assertSucceeds(
    setDoc(doc(db('alice'), 'users/alice/readings/r1'), payload),
  );
  await assertFails(
    setDoc(doc(db('bob'), 'users/alice/readings/r2'), payload),
  );
});

test('bill create without alertTierSent is allowed', async () => {
  await assertSucceeds(
    setDoc(doc(db('alice'), 'users/alice/bills/2026-07'), {
      kwh: 100,
      amount: 30,
      tariffType: 'domestic',
    }),
  );
});

test('bill create that sets alertTierSent is denied', async () => {
  await assertFails(
    setDoc(doc(db('alice'), 'users/alice/bills/2026-08'), {
      kwh: 100,
      amount: 30,
      tariffType: 'domestic',
      alertTierSent: 80,
    }),
  );
});

test('client cannot mutate alertTierSent on an existing bill', async () => {
  await setDoc(doc(db('alice'), 'users/alice/bills/2026-09'), {
    kwh: 100,
    amount: 30,
    tariffType: 'domestic',
  });
  await assertFails(
    updateDoc(doc(db('alice'), 'users/alice/bills/2026-09'), {
      alertTierSent: 100,
    }),
  );
});

test('appliance with dailyHours > 24 is denied', async () => {
  await assertFails(
    setDoc(doc(db('alice'), 'users/alice/appliances/a1'), {
      name: 'AC',
      category: 'Cooling',
      wattage: 1200,
      dailyHours: 25,
    }),
  );
});

test('gamification is readable by owner but not writable', async () => {
  await assertSucceeds(
    getDoc(doc(db('alice'), 'users/alice/gamification/state')),
  );
  await assertFails(
    setDoc(doc(db('alice'), 'users/alice/gamification/state'), { xp: 999 }),
  );
});

test('unknown collections are denied', async () => {
  await assertFails(setDoc(doc(db('alice'), 'secrets/x'), { a: 1 }));
});
