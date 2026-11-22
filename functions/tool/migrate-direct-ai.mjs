import { readFileSync } from 'node:fs';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, Timestamp, FieldValue } from 'firebase-admin/firestore';
import { decryptKey } from '../src/domain.mjs';

if (process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST || !process.argv.includes('--apply')) throw Error('Explicit --apply required; this migration only targets bepxinh-b0be7.');
initializeApp({ projectId: 'bepxinh-b0be7', credential: applicationDefault() });
const db = getFirestore();
try {
  const target = db.doc('ai_settings/runtime');
  if (!(await target.get()).exists) {
    const old = (await db.doc('_ai_private/config').get()).data();
    if (old?.keyCipher) {
      const secret = readFileSync(new URL('../.secret.local', import.meta.url), 'utf8').split(/\r?\n/).find(line => line.startsWith('AI_CONFIG_ENCRYPTION_KEY='));
      const key = decryptKey(old.keyCipher, secret.slice(secret.indexOf('=') + 1));
      await target.create({ provider: old.provider, endpoint: old.endpoint, model: old.model, enabled: old.enabled, dailyLimit: old.dailyLimit, version: old.version, apiKey: key, updatedBy: old.updatedBy, updatedAt: FieldValue.serverTimestamp() });
      console.log('Existing AI configuration copied to direct mode; key was not printed.');
    }
  } else console.log('Direct configuration already exists; left unchanged.');
  let messages = 0, events = 0;
  for (const thread of await db.collection('_ai_threads').listDocuments()) {
    for (const source of (await thread.collection('messages').get()).docs) {
      const ref = db.doc(`ai_chat_threads/${thread.id}/messages/${source.id}`);
      if ((await ref.get()).exists) continue;
      const value = source.data();
      await ref.create({role:value.role,text:value.text,recipes:value.recipes ?? [],createdAtMillis:value.createdAtMillis}); messages++;
    }
  }
  for (const source of (await db.collection('_ai_requests').select('uid','status','leaseUntil','expiresAt','attemptedAtMillis').get()).docs) {
    const ref = db.doc(`ai_chat_events/${source.id}`);
    if ((await ref.get()).exists) continue;
    const value = source.data(), time = value.attemptedAtMillis ?? value.leaseUntil - 60000;
    if (!Number.isFinite(time)) continue;
    // Lượt thử cũ đã nằm trong _ai_limits/project_*, không cộng lần hai vào events.
    await ref.create({uid:value.uid,status:value.status,attemptedAtMillis:time,leaseUntil:value.leaseUntil,attempts:0,expiresAt:value.expiresAt ?? Timestamp.fromMillis(time+7*86400000)}); events++;
  }
  console.log('Migration complete:', { messagesCopied: messages, eventMetadataCopied: events });
} finally { await db.terminate(); }
