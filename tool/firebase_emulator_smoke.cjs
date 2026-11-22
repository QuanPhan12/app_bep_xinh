// Chỉ chạy với emulator và project demo; không nhận URL hay project production.
const assert = require('node:assert/strict');
const project = 'demo-bepxinh';
const authUrl = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const db = `projects/${project}/databases/(default)`;
const firestoreUrl = `http://127.0.0.1:8080/v1/${db}/documents`;
let checks = 0;
async function request(url, body, token, expected = 200, method = 'POST') {
  const response = await fetch(url, {
    method,
    headers: {'Content-Type': 'application/json', ...(token ? {Authorization: `Bearer ${token}`} : {})},
    ...(body === undefined ? {} : {body: JSON.stringify(body)}),
  });
  const data = await response.json();
  assert.equal(response.status, expected, `${method} ${new URL(url).pathname}: ${JSON.stringify(data.error || {})}`);
  checks++;
  return data;
}
const string = value => ({stringValue: value});
const boolean = value => ({booleanValue: value});
const integer = value => ({integerValue: String(value)});
const stamp = fieldPath => ({fieldPath, setToServerValue: 'REQUEST_TIME'});
const profilePath = uid => `${db}/documents/users/${uid}`;
async function write(token, path, fields, mask, transforms = ['updatedAt']) {
  return request(`${firestoreUrl}:commit`, {writes: [{
    update: {name: path, fields},
    ...(mask ? {updateMask: {fieldPaths: mask}} : {}),
    updateTransforms: transforms.map(stamp),
  }]}, token);
}
async function deniedWrite(token, path, fields, mask, transforms = ['updatedAt']) {
  return request(`${firestoreUrl}:commit`, {writes: [{
    update: {name: path, fields},
    ...(mask ? {updateMask: {fieldPaths: mask}} : {}),
    updateTransforms: transforms.map(stamp),
  }]}, token, 403);
}
(async () => {
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8080');
  const {loadCatalog,firestoreValue} = require('./ingredient_catalog_data.cjs');
  const {data,contentHash} = loadCatalog();
  const catalogFields = firestoreValue({...data,contentHash}).mapValue.fields;
  const catalogWrite = {writes:[{update:{name:`${db}/documents/catalogs/ingredients`,fields:catalogFields}}]};
  await request(`${firestoreUrl}:commit`, catalogWrite, 'owner');
  const publicCatalog = await request(`${firestoreUrl}/catalogs/ingredients`, undefined, undefined, 200, 'GET');
  assert.equal(publicCatalog.fields.ingredients.arrayValue.values.length,data.ingredients.length);
  await request(`${firestoreUrl}/catalogs`, undefined, undefined, 403, 'GET');
  await request(`${firestoreUrl}:commit`, catalogWrite, undefined, 403);
  const suffix = Date.now();
  const email = `cook-${suffix}@example.test`;
  const password = 'Emulator-only-123!';
  const a = await request(`${authUrl}/accounts:signUp?key=demo`, {email, password, returnSecureToken: true});
  const b = await request(`${authUrl}/accounts:signUp?key=demo`, {email: `other-${suffix}@example.test`, password, returnSecureToken: true});
  await request(`${firestoreUrl}/catalogs/ingredients`, undefined, a.idToken, 200, 'GET');
  await request(`${firestoreUrl}:commit`, catalogWrite, a.idToken, 403);
  const login = await request(`${authUrl}/accounts:signInWithPassword?key=demo`, {email, password, returnSecureToken: true});
  assert.equal(login.localId, a.localId);
  await request(`${authUrl}/accounts:sendOobCode?key=demo`, {email, requestType: 'PASSWORD_RESET'});
  const oob = await request(`http://127.0.0.1:9099/emulator/v1/projects/${project}/oobCodes`, undefined, undefined, 200, 'GET');
  assert.ok(oob.oobCodes.some(code => code.email === email && code.requestType === 'PASSWORD_RESET'));
  await request(`${authUrl}/accounts:signInWithPassword?key=demo`, {email, password: 'incorrect', returnSecureToken: true}, undefined, 400);

  const path = profilePath(a.localId);
  const fields = {schemaVersion: integer(1), role: string('user'), status: string('active'), id: string(a.localId), name: string('Đầu bếp thử nghiệm'), handle: string('bep_test'),
    bio: string(''), showBio: boolean(true), cookedCount: integer(0)};
  await write(a.idToken, path, fields, undefined, ['createdAt', 'updatedAt']);
  const url = `${firestoreUrl}/users/${a.localId}`;
  await request(url, undefined, a.idToken, 200, 'GET');
  await request(url, undefined, b.idToken, 403, 'GET');
  await request(url, undefined, undefined, 403, 'GET');
  await request(`${firestoreUrl}/users`, undefined, a.idToken, 403, 'GET');
  await write(a.idToken, path, {name: string('Tên mới'), bio: string('Gian bếp nhỏ'), showBio: boolean(false)}, ['name', 'bio', 'showBio']);
  const saved = await request(url, undefined, a.idToken, 200, 'GET');
  assert.equal(saved.fields.name.stringValue, 'Tên mới');
  assert.equal(saved.fields.showBio.booleanValue, false);
  await deniedWrite(b.idToken, path, {name: string('Chiếm quyền')}, ['name']);
  await deniedWrite(a.idToken, path, {cookedCount: integer(999)}, ['cookedCount']);
  await deniedWrite(a.idToken, path, {role: string('admin')}, ['role']);
  await deniedWrite(a.idToken, path, {bio: string('x'.repeat(201))}, ['bio']);
  await deniedWrite(a.idToken, path, {id: string(b.localId)}, ['id']);
  await deniedWrite(a.idToken, path, {status: string('locked')}, ['status']);
  await deniedWrite(a.idToken, path, {lastLoginAt: {timestampValue:new Date().toISOString()}}, ['lastLoginAt']);

  const favoritePath = `${path}/favorites/tofu`;
  await write(a.idToken, favoritePath, {recipeId: string('tofu')}, undefined, ['createdAt']);
  await request(`${url}/favorites`, undefined, a.idToken, 200, 'GET');
  await request(`${url}/favorites/tofu`, undefined, b.idToken, 403, 'GET');
  await request(`${firestoreUrl}:commit`, {writes: [{delete: favoritePath}]}, b.idToken, 403);
  await request(`${firestoreUrl}:commit`, {writes: [{delete: favoritePath}]}, a.idToken);
  await request(`${url}/favorites/tofu`, undefined, a.idToken, 404, 'GET');
  const fridgePath = `${path}/fridge/current`;
  const fridgeFields = {schemaVersion:integer(1),ingredientIds:{mapValue:{fields:{egg:boolean(true),tomato:boolean(true)}}}};
  await write(a.idToken, fridgePath, fridgeFields);
  const fridgeSaved = await request(`${url}/fridge/current`, undefined, a.idToken, 200, 'GET');
  assert.equal(fridgeSaved.fields.ingredientIds.mapValue.fields.egg.booleanValue, true);
  await request(`${url}/fridge/current`, undefined, b.idToken, 403, 'GET');
  await request(`${url}/fridge/current`, undefined, undefined, 403, 'GET');
  await deniedWrite(b.idToken, fridgePath, fridgeFields);
  await deniedWrite(a.idToken, fridgePath, {...fridgeFields,ingredientIds:{mapValue:{fields:{egg:boolean(false)}}}});
  await deniedWrite(a.idToken, fridgePath, {...fridgeFields,ingredientIds:{arrayValue:{values:[string('egg')]}}});
  await deniedWrite(a.idToken, fridgePath, {...fridgeFields,ingredientIds:{mapValue:{fields:Object.fromEntries(Array.from({length:501},(_,i)=>['id'+i,boolean(true)]))}}});
  await deniedWrite(a.idToken, `${path}/fridge/other`, fridgeFields);
  await deniedWrite(a.idToken, fridgePath, {...fridgeFields,extra:string('invalid')});
  await write(a.idToken, fridgePath, {schemaVersion:integer(1),ingredientIds:{mapValue:{fields:{}}}});
  const emptyFridge = await request(`${url}/fridge/current`, undefined, a.idToken, 200, 'GET');
  assert.equal(Object.keys(emptyFridge.fields.ingredientIds.mapValue.fields||{}).length, 0);
  // Quyền owner chỉ có trên emulator; mô phỏng metadata do backend quản trị ghi.
  await write('owner', path, {status:string('locked'),lockReason:string('Test lock')}, ['status','lockReason'], ['lockedAt','updatedAt']);
  await request(url, undefined, a.idToken, 200, 'GET');
  await deniedWrite(a.idToken, path, {name:string('Bypass lock')}, ['name']);
  await request(`${url}/favorites`, undefined, a.idToken, 403, 'GET');
  await request(`${url}/fridge/current`, undefined, a.idToken, 403, 'GET');
  await deniedWrite(a.idToken, fridgePath, fridgeFields);
  await request(`${firestoreUrl}:commit`, {writes:[{update:{name:favoritePath,fields:{recipeId:string('tofu')}},updateTransforms:[stamp('createdAt')]}]}, a.idToken, 403);
  await deniedWrite(a.idToken, path, {status:string('active')}, ['status']);
  await write('owner', path, {status:string('active'),lockedAt:{nullValue:null},lockReason:{nullValue:null}}, ['status','lockedAt','lockReason']);
  await write(a.idToken, path, {name:string('After unlock')}, ['name']);
  const legacyPath = profilePath(b.localId);
  const legacyFields = {...fields,id:string(b.localId),name:string('Legacy user')};
  delete legacyFields.schemaVersion;
  delete legacyFields.role;
  delete legacyFields.status;
  const forgedFields = {...legacyFields,schemaVersion:integer(1),role:string('admin'),status:string('active')};
  await request(`${firestoreUrl}:commit`,{writes:[{update:{name:legacyPath,fields:forgedFields},updateTransforms:[stamp('createdAt'),stamp('updatedAt')]}]},b.idToken,403);
  await write('owner',legacyPath,legacyFields,undefined,['createdAt','updatedAt']);
  await write(b.idToken,legacyPath,{name:string('Legacy edit')},['name']);
  console.log(`PASS: ${checks} Auth/Firestore emulator checks; production untouched.`);
})().catch(error => {console.error(error.message); process.exitCode = 1;});
