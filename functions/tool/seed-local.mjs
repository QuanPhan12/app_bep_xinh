import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { createRequire } from 'node:module';
if (process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080' || process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099') throw new Error('Chỉ chạy với demo Auth/Firestore emulator tại loopback.');
initializeApp({ projectId: 'demo-bepxinh' });
const db = getFirestore(), auth = getAuth();
const password = 'BepXinhLocal123!';
for (const [email, role, name] of [['local-admin@example.test','admin','Quản trị local'],['local-cook@example.test','user','Đầu bếp local']]) {
  let user;
  try { user = await auth.getUserByEmail(email); } catch (e) { if (e.code !== 'auth/user-not-found') throw e; user = await auth.createUser({ email, password }); }
  const ref = db.doc(`users/${user.uid}`);
  if (!(await ref.get()).exists) await ref.set({ id: user.uid, schemaVersion: 1, name, handle: `bep_${user.uid}`, bio: '', showBio: true, cookedCount: 0, role, status: 'active', lockedAt: null, lockReason: null, createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
}
const require = createRequire(import.meta.url), { loadCatalog } = require('../../tool/ingredient_catalog_data.cjs');
const { data, contentHash } = loadCatalog();
if (!(await db.doc('catalogs/ingredients').get()).exists) await db.doc('catalogs/ingredients').set({ ...data, contentHash, updatedAt: FieldValue.serverTimestamp() });
console.log('DEMO ONLY accounts: local-admin@example.test / local-cook@example.test; password: BepXinhLocal123!');
console.log('Catalog ready. Publish and approve local recipes to use them as real AI recommendation cards.');
