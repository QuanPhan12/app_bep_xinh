// Chỉ kiểm thử trên demo emulator; không xóa hay ẩn dữ liệu production.
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const { encode } = require('./firebase_cli_client.cjs');
assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8080');
assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST, '127.0.0.1:9099');
const root = 'projects/demo-bepxinh/databases/(default)/documents';
const base = `http://127.0.0.1:8080/v1/${root}`;
let checks = 0;
async function request(url, method, body, token, expected = 200) {
  const response = await fetch(url, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, ...(body ? { body: JSON.stringify(body) } : {}) });
  const data = await response.json();
  assert.equal(response.status, expected, `${method} ${new URL(url).pathname}: ${JSON.stringify(data.error || {})}`); checks++;
  return data;
}
const write = (path, data, mask, stamps = []) => ({ update: { name: `${root}/${path}`, fields: encode(data).mapValue.fields }, ...(mask ? { updateMask: { fieldPaths: mask } } : {}), updateTransforms: stamps.map(fieldPath => ({ fieldPath, setToServerValue: 'REQUEST_TIME' })) });
const commit = (writes, token, expected = 200) => request(`${base}:commit`, 'POST', { writes }, token, expected);
const get = (path, token, expected = 200) => request(`${base}/${path}`, 'GET', undefined, token, expected);
async function account(role) {
  const result = await request('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo', 'POST', { email: `visibility-${crypto.randomUUID()}@example.test`, password: 'EmulatorOnly123!', returnSecureToken: true });
  const actor = { id: result.localId, token: result.idToken };
  await commit([write(`users/${actor.id}`, { id: actor.id, role, status: 'active' })], 'owner');
  return actor;
}
(async () => {
  const author = await account('user'), other = await account('user'), admin = await account('admin'), moderator = await account('moderator');
  const id = `r_visibility_${crypto.randomUUID()}`;
  const seed = (recipeId, status) => write(`recipes/${recipeId}`, { schemaVersion: 2, id: recipeId, authorId: author.id, status, isBanner: status === 'approved', content: {}, reviewedAt: null, reviewedBy: null, reviewReason: null }, null, ['submittedAt']);
  await commit([seed(id, 'approved'), seed(`${id}_pending`, 'pending'), seed(`${id}_rejected`, 'rejected'), write(`recipes/${id}/user_reviews/reader`, { uid: 'reader', name: 'Reader', stars: 4, body: 'Public review', status: 'approved' }, null, ['updatedAt']), write(`recipes/${id}/ratings/summary`, { sum: 4, count: 1, lastReviewerId: 'reader' }, null, ['updatedAt'])], 'owner');
  function transition(recipeId, actor, role, fromStatus, toStatus, reason = null) {
    const eventId = crypto.randomUUID();
    return [write(`recipes/${recipeId}`, { status: toStatus, isBanner: false, visibilityEventId: eventId, visibilityActor: actor.id, visibilityRole: role, visibilityReason: reason }, ['status', 'isBanner', 'visibilityEventId', 'visibilityActor', 'visibilityRole', 'visibilityReason'], ['visibilityAt']), write(`recipes/${recipeId}/visibility_events/${eventId}`, { actor: actor.id, role, reason, fromStatus, toStatus }, null, ['createdAt'])];
  }
  await get(`recipes/${id}`, null);
  await get(`recipes/${id}/user_reviews/reader`, null);
  await commit(transition(id, other, 'author', 'approved', 'hidden'), other.token, 403);
  await commit(transition(id, moderator, 'admin', 'approved', 'hidden', 'Moderator cannot hide'), moderator.token, 403);
  await commit(transition(id, author, 'admin', 'approved', 'hidden', 'Forged admin'), author.token, 403);
  const naked = transition(id, author, 'author', 'approved', 'hidden');
  await commit(naked.slice(0, 1), author.token, 403);
  await commit(naked.slice(1), author.token, 403);
  const edited = transition(id, author, 'author', 'approved', 'hidden');
  edited[0].update.fields.content = encode({ title: 'Tampered' }); edited[0].updateMask.fieldPaths.push('content');
  await commit(edited, author.token, 403);
  const ownerHide = transition(id, author, 'author', 'approved', 'hidden');
  await commit(ownerHide, author.token);
  const hidden = await get(`recipes/${id}`, author.token);
  assert.equal(hidden.fields.status.stringValue, 'hidden'); assert.equal(hidden.fields.isBanner.booleanValue, false); checks += 2;
  await get(`recipes/${id}`, null, 403);
  await get(`recipes/${id}/user_reviews/reader`, null, 403);
  await get(`recipes/${id}/ratings/summary`, null, 403);
  const publicRows = await request(`${base}:runQuery`, 'POST', { structuredQuery: { from: [{ collectionId: 'recipes' }], where: { fieldFilter: { field: { fieldPath: 'status' }, op: 'EQUAL', value: encode('approved') } } } }, null);
  assert.ok(!publicRows.some(row => row.document?.name === `${root}/recipes/${id}`)); checks++;
  const ownRows = await request(`${base}:runQuery`, 'POST', { structuredQuery: { from: [{ collectionId: 'recipes' }], where: { compositeFilter: { op: 'AND', filters: [{ fieldFilter: { field: { fieldPath: 'authorId' }, op: 'EQUAL', value: encode(author.id) } }, { fieldFilter: { field: { fieldPath: 'status' }, op: 'IN', value: encode(['pending', 'approved', 'rejected', 'hidden']) } }] } }, orderBy: [{ field: { fieldPath: 'submittedAt' }, direction: 'DESCENDING' }], limit: 50 } }, author.token);
  assert.ok(ownRows.some(row => row.document?.name === `${root}/recipes/${id}`)); checks++;
  await get(`recipes/${id}/visibility_events`, other.token, 403);
  await get(`recipes/${id}/visibility_events`, author.token);
  await commit(transition(id, admin, 'admin', 'hidden', 'approved'), admin.token, 403);
  await commit(transition(id, author, 'author', 'hidden', 'approved'), author.token);
  const restored = await get(`recipes/${id}`, null); assert.equal(restored.fields.isBanner.booleanValue, false); checks++;
  await commit(transition(id, admin, 'admin', 'approved', 'hidden', '   '), admin.token, 403);
  await commit(transition(id, admin, 'admin', 'approved', 'hidden', 'Nội dung cần xem xét'), admin.token);
  await commit(transition(id, author, 'author', 'hidden', 'approved'), author.token, 403);
  await commit(transition(id, author, 'author', 'hidden', 'hidden'), author.token, 403);
  await commit(transition(id, admin, 'admin', 'hidden', 'approved'), admin.token);
  await commit(transition(id, author, 'author', 'approved', 'hidden'), author.token);
  await commit(transition(id, admin, 'admin', 'hidden', 'hidden', 'Admin tiếp nhận xử lý'), admin.token);
  await commit(transition(id, author, 'author', 'hidden', 'approved'), author.token, 403);
  await commit(transition(id, author, 'author', 'hidden', 'deleted'), author.token);
  await get(`recipes/${id}`, null, 403);
  await commit(transition(id, author, 'author', 'deleted', 'approved'), author.token, 403);
  await commit(transition(id, admin, 'admin', 'deleted', 'approved'), admin.token, 403);
  await commit([{ delete: `${root}/recipes/${id}` }], author.token, 403);
  await commit([{ delete: `${root}/recipes/${id}` }], admin.token, 403);
  await commit([{ delete: ownerHide[1].update.name }], author.token, 403);
  await commit([ownerHide[1]], admin.token, 403);
  const aggregate = await get(`recipes/${id}/ratings/summary`, admin.token); assert.equal(aggregate.fields.sum.integerValue, '4'); checks++;
  await commit(transition(`${id}_pending`, author, 'author', 'pending', 'hidden'), author.token, 403);
  await commit(transition(`${id}_pending`, other, 'author', 'pending', 'deleted'), other.token, 403);
  await commit(transition(`${id}_pending`, author, 'author', 'pending', 'deleted'), author.token);
  await commit(transition(`${id}_rejected`, author, 'author', 'rejected', 'deleted'), author.token);
  const lockedId = `${id}_locked`; await commit([seed(lockedId, 'approved'), write(`users/${author.id}`, { status: 'locked' }, ['status'])], 'owner');
  await commit(transition(lockedId, author, 'author', 'approved', 'hidden'), author.token, 403);
  await commit(transition(lockedId, author, 'author', 'approved', 'deleted'), author.token, 403);
  await commit(transition(lockedId, admin, 'admin', 'approved', 'hidden', 'Ẩn khi tác giả bị khóa'), admin.token);
  console.log(`PASS: ${checks} recipe visibility emulator checks`);
})().catch(error => { console.error(error); process.exitCode = 1; });
