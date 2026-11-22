// Chỉ dùng tài khoản giả và database demo để kiểm chứng quyền quản trị.
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const { encode } = require('./firebase_cli_client.cjs');
const { loadCatalog } = require('./ingredient_catalog_data.cjs');
assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8080');
assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST, '127.0.0.1:9099');
const root = 'projects/demo-bepxinh/databases/(default)/documents';
const base = `http://127.0.0.1:8080/v1/${root}`;
let checks = 0;
async function request(url, method, body, token, expected = 200) {
  const r = await fetch(url, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, ...(body ? { body: JSON.stringify(body) } : {}) });
  const data = await r.json();
  assert.equal(r.status, expected, `${method} ${new URL(url).pathname}: ${JSON.stringify(data.error || {})}`); checks++;
  return data;
}
const write = (path, data, mask, stamps = []) => ({ update: { name: `${root}/${path}`, fields: encode(data).mapValue.fields }, ...(mask ? { updateMask: { fieldPaths: mask } } : {}), ...(stamps.length ? { updateTransforms: stamps.map(fieldPath => ({ fieldPath, setToServerValue: 'REQUEST_TIME' })) } : {}) });
const commit = (token, writes, status = 200) => request(`${base}:commit`, 'POST', { writes }, token, status);
const get = (token, path, status = 200) => request(`${base}/${path}`, 'GET', null, token, status);
async function user(role) {
  const u = await request('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo', 'POST', { email: `admin-test-${crypto.randomUUID()}@example.test`, password: 'Emulator-only-123!', returnSecureToken: true });
  await commit('owner', [write(`users/${u.localId}`, { id: u.localId, schemaVersion: 1, name: role, handle: `bep_${u.localId}`, bio: '', showBio: true, cookedCount: 0, role, status: 'active', lockedAt: null, lockReason: null }, null, ['createdAt', 'updatedAt'])]);
  return { id: u.localId, token: u.idToken };
}
(async () => {
  const admin = await user('admin'), moderator = await user('moderator'), cook = await user('user');
  await commit(cook.token, [write(`users/${cook.id}`, { avatarUrl: 'https://res.cloudinary.com/ddqouziau/image/upload/v1/avatar.png' }, ['avatarUrl'], ['updatedAt'])]);
  await commit(cook.token, [write(`users/${cook.id}`, { avatarUrl: 'http://example.test/insecure.png' }, ['avatarUrl'], ['updatedAt'])], 403);
  await commit(moderator.token, [write(`users/${cook.id}`, { avatarUrl: 'https://example.test/other.png' }, ['avatarUrl'], ['updatedAt'])], 403);
  await commit(cook.token, [write(`users/${cook.id}`, { avatarUrl: 'https://example.test/avatar.png', role: 'admin' }, ['avatarUrl', 'role'], ['updatedAt'])], 403);
  const id = `r_admin_${crypto.randomUUID()}`, id2 = `${id}_reject`;
  const image = { id: 'cover', name: 'cover.png', url: 'https://res.cloudinary.com/ddqouziau/image/upload/v1/test.png', publicId: 'test' };
  const content = { title: 'Món thử', description: '', storageNotes: '', cover: image, preparationMinutes: 5, cookingMinutes: 15, servings: 2, difficulty: 'easy', meals: ['dinner'], categories: ['quick'], ingredientGroups: [{ id: 'main', name: 'Chính' }], ingredients: [{ id: 'i', ingredientId: null, name: 'Nguyên liệu', amount: null, unitId: null, note: '', toTaste: true, groupId: 'main' }], steps: [{ id: 's', title: '', instruction: 'Nấu chín.', minutes: null, tip: '', photo: null }] };
  const pending = recipeId => ({ schemaVersion: 2, id: recipeId, authorId: cook.id, author: { id: cook.id, name: 'user', handle: `bep_${cook.id}` }, content, contentHash: 'a'.repeat(64), catalogVersion: '2026-11-09.v1', isBanner: false, status: 'pending', reviewedAt: null, reviewedBy: null, reviewReason: null, revisionOf: null });
  await commit(cook.token, [write(`recipes/${id}`, pending(id), null, ['submittedAt'])]);
  await commit(cook.token, [write(`recipes/${id2}`, pending(id2), null, ['submittedAt'])]);
  const review = (actor, recipeId, decision = 'approve', reason = null) => [
    write(`recipes/${recipeId}`, { status: decision === 'approve' ? 'approved' : 'rejected', reviewedBy: actor.id, reviewReason: reason }, ['status', 'reviewedBy', 'reviewReason'], ['reviewedAt']),
    write(`recipe_moderation_events/${recipeId}`, { submissionId: recipeId, authorId: cook.id, decision, reviewer: actor.id, reason }, null, ['createdAt']),
  ];
  await get(null, `recipes/${id}`, 403);
  await get(moderator.token, `recipes/${id}`);
  await get(admin.token, 'users');
  await get(moderator.token, 'users', 403);
  await get(moderator.token, `users/${cook.id}`);
  await get(cook.token, `users/${admin.id}`, 403);
  await get(admin.token, `users/${cook.id}/favorites`, 403);
  await get(admin.token, 'conversations', 403);
  await commit(cook.token, review(cook, id), 403);
  await commit(moderator.token, review(moderator, id).slice(0, 1), 403);
  await commit(moderator.token, review(moderator, id).slice(1), 403);
  const forged = review(moderator, id); forged[1] = write(`recipe_moderation_events/${id}`, { submissionId: id, authorId: cook.id, decision: 'reject', reviewer: moderator.id, reason: null }, null, ['createdAt']);
  await commit(moderator.token, forged, 403);
  const changedContent = review(moderator, id); changedContent[0] = write(`recipes/${id}`, { status: 'approved', reviewedBy: moderator.id, reviewReason: null, content: { ...content, title: 'Đổi nội dung' } }, ['status', 'reviewedBy', 'reviewReason', 'content'], ['reviewedAt']);
  await commit(moderator.token, changedContent, 403);
  await commit(admin.token, [write(`users/${cook.id}`, { status: 'locked', lockedAt: null, lockReason: 'Lý do' }, ['status', 'lockedAt', 'lockReason'], ['updatedAt'])], 403);
  const lock = write(`users/${cook.id}`, { status: 'locked', lockReason: 'Vi phạm' }, ['status', 'lockReason'], ['updatedAt', 'lockedAt']);
  await commit(moderator.token, [lock], 403);
  await commit(admin.token, [lock]);
  await commit(moderator.token, review(moderator, id), 403);
  await commit(admin.token, [write(`users/${cook.id}`, { status: 'active', lockedAt: null, lockReason: null }, ['status', 'lockedAt', 'lockReason'], ['updatedAt'])]);
  await commit(moderator.token, review(moderator, id));
  await get(null, `recipes/${id}`);
  await get(moderator.token, `recipe_moderation_events/${id}`);
  await get(cook.token, `recipe_moderation_events/${id}`, 403);
  await commit(admin.token, review(admin, id), 403);
  await commit(moderator.token, review(moderator, id2, 'reject'), 403);
  await commit(moderator.token, review(moderator, id2, 'reject', '   '), 403);
  await commit(moderator.token, review(moderator, id2, 'reject', 'Cần sửa hướng dẫn.'));
  const banner = value => [write(`recipes/${id}`, { isBanner: value }, ['isBanner'])];
  await commit(cook.token, banner(true), 403);
  await commit(moderator.token, banner(true), 403);
  await commit(admin.token, banner(true));
  await commit(admin.token, [write(`recipes/${id2}`, { isBanner: true }, ['isBanner'])], 403);
  await commit(admin.token, [write(`recipes/${id}`, { isBanner: 'yes' }, ['isBanner'])], 403);
  await commit(admin.token, banner(false));
  await commit(admin.token, [write(`users/${admin.id}`, { role: 'user' }, ['role'], ['updatedAt'])], 403);
  await commit(cook.token, [write(`users/${cook.id}`, { role: 'admin' }, ['role'], ['updatedAt'])], 403);
  await commit(admin.token, [write(`users/${cook.id}`, { role: 'moderator' }, ['role'], ['updatedAt'])]);
  const { data, contentHash } = loadCatalog();
  await commit('owner', [write('catalogs/ingredients', { ...data, contentHash }, null, ['updatedAt'])]);
  const next = { ...data, version: '2026-11-12.v999', contentHash: 'b'.repeat(64) };
  await commit(cook.token, [write('catalogs/ingredients', next, null, ['updatedAt'])], 403);
  await commit(moderator.token, [write('catalogs/ingredients', next, null, ['updatedAt'])], 403);
  await commit(admin.token, [write('catalogs/ingredients', next, null, ['updatedAt'])]);
  await commit(admin.token, [write('catalogs/ingredients', next, null, ['updatedAt'])], 403);
  await get(null, 'catalogs/ingredients');
  await commit('owner', [write(`users/${moderator.id}`, { status: 'locked', lockReason: 'Khóa kiểm thử' }, ['status', 'lockReason'], ['lockedAt'])]);
  await get(moderator.token, `recipes/${id2}`, 403);
  await get(moderator.token, 'recipe_moderation_events', 403);
  await commit(admin.token, [{ delete: `${root}/recipe_moderation_events/${id}` }], 403);
  console.log(`PASS: ${checks} admin portal emulator checks`);
})().catch(e => { console.error(e); process.exitCode = 1; });
