// Chỉ dùng emulator demo; không đọc/ghi dữ liệu người dùng production.
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8080');
assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST, '127.0.0.1:9099');
const project = 'demo-bepxinh';
const base = `http://127.0.0.1:8080/v1/projects/${project}/databases/(default)/documents`;
const prefix = `projects/${project}/databases/(default)/documents`;
const {encode} = require('./firebase_cli_client.cjs');
let checks = 0;
async function request(url, method, body, token, expected = 200) {
  const response = await fetch(url, {method,
    headers: {'Content-Type': 'application/json', ...(token ? {Authorization: `Bearer ${token}`} : {})},
    ...(body ? {body: JSON.stringify(body)} : {})});
  const result = await response.json();
  assert.equal(response.status, expected, `${method} ${new URL(url).pathname}: ${JSON.stringify(result.error || {})}`);
  checks++;
  return result;
}
const fields = data => encode(data).mapValue.fields;
// UID ngẫu nhiên có thể bắt đầu bằng số; REST field path phải quote segment đó.
const stamp = fieldPath => ({fieldPath: fieldPath.split('.').map(part => /^[a-zA-Z_][a-zA-Z_0-9]*$/.test(part) ? part : '`' + part + '`').join('.'), setToServerValue:'REQUEST_TIME'});
const write = (path, data, mask, stamps = []) => ({
  update:{name:`${prefix}/${path}`,fields:fields(data)},
  ...(mask ? {updateMask:{fieldPaths:mask}} : {}),
  ...(stamps.length ? {updateTransforms:stamps.map(stamp)} : {}),
});
const commit = (token, writes, expected = 200) => request(`${base}:commit`, 'POST', {writes}, token, expected);
const get = (token, path, expected = 200) => request(`${base}/${path}`, 'GET', null, token, expected);
async function user(label) {
  const result = await request('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo',
    'POST', {email:`${label}-${crypto.randomUUID()}@example.test`,password:'EmulatorOnly123!',returnSecureToken:true});
  await commit('owner', [write(`users/${result.localId}`, {id:result.localId,name:label,status:'active'})]);
  return {id:result.localId,token:result.idToken};
}
(async () => {
  const alice = await user('Alice'), bob = await user('Bob'), outsider = await user('Outsider');
  const recipeId = `chat_recipe_${crypto.randomUUID()}`;
  await commit('owner',[write(`recipes/${recipeId}`, {id:recipeId,authorId:bob.id,status:'approved',
    author:{id:bob.id,name:'Bob'}, content:{title:'Món thử'}, submittedAt:new Date().toISOString()})]);
  const members = [alice.id,bob.id].sort();
  const conversationId = crypto.createHash('sha256').update(JSON.stringify(members)).digest('hex');
  const path = `conversations/${conversationId}`;
  const initial = {memberIds:members, memberNames:{[alice.id]:'Alice',[bob.id]:'Bob'}, recipeId,
    lastMessageId:null,lastMessageText:'',lastSenderId:null,readAt:{}};
  const create = data => write(path,data,null,['createdAt','updatedAt',`readAt.${alice.id}`]);
  await get(alice.token,path,404);
  await commit(alice.token,[create({...initial,memberIds:[alice.id,alice.id]})],403);
  await commit(alice.token,[create({...initial,memberNames:{[alice.id]:'Admin',[bob.id]:'Bob'}})],403);
  await commit(alice.token,[create({...initial,recipeId:'not_published'})],403);
  await commit(alice.token,[create(initial)]);
  await get(bob.token,path);
  await get(outsider.token,path,403);
  await get(null,path,403);
  const sendWrites = (sender, text, id = crypto.randomBytes(16).toString('hex'), image) => ({id,writes:[
    write(`${path}/messages/${id}`,{senderId:sender.id,text,...(image ? {image} : {})},null,['createdAt']),
    write(path,{lastMessageId:id,lastMessageText:text || (image ? '📷 Ảnh' : ''),lastSenderId:sender.id},
      ['lastMessageId','lastMessageText','lastSenderId'],['updatedAt',`readAt.${sender.id}`]),
  ]});
  const first = sendWrites(alice,'Xin chào\nCùng vào bếp nhé!');
  await commit(alice.token,first.writes);
  await get(bob.token,`${path}/messages/${first.id}`);
  await get(outsider.token,`${path}/messages/${first.id}`,403);
  await commit(alice.token,[write(`${path}/messages/${first.id}`,{text:'Sửa lịch sử'},['text'])],403);
  await commit(alice.token,[{delete:`${prefix}/${path}/messages/${first.id}`}],403);
  await commit(alice.token,[write(`${path}/messages/${crypto.randomBytes(16).toString('hex')}`,
    {senderId:alice.id,text:'Thiếu preview'},null,['createdAt'])],403);
  await commit(alice.token,sendWrites(bob,'Giả danh').writes,403);
  await commit(outsider.token,sendWrites(outsider,'Đọc trộm').writes,403);
  await commit(alice.token,sendWrites(alice,'   \n\t ').writes,403);
  await commit(alice.token,sendWrites(alice,'a'.repeat(2001)).writes,403);
  const mismatch = sendWrites(alice,'Nội dung thật');
  mismatch.writes[1].update.fields.lastMessageText = encode('Preview giả');
  await commit(alice.token,mismatch.writes,403);
  const image = {id:'photo',name:'Ảnh trò chuyện',
    url:'https://res.cloudinary.com/ddqouziau/image/upload/v1/chat.png',publicId:'chat'};
  const photo = sendWrites(alice,'',undefined,image);
  await commit(alice.token,photo.writes);
  const receivedPhoto = await get(bob.token,`${path}/messages/${photo.id}`);
  assert.equal(receivedPhoto.fields.image.mapValue.fields.url.stringValue,image.url);
  await commit(alice.token,sendWrites(alice,'Có lời nhắn',undefined,image).writes);
  await commit(alice.token,sendWrites(alice,'').writes,403);
  await commit(alice.token,sendWrites(alice,'',undefined,{...image,url:'http://example.com/photo.png'}).writes,403);
  await commit(alice.token,sendWrites(alice,'',undefined,{...image,url:'https://example.com/photo.png'}).writes,403);
  await commit(alice.token,sendWrites(alice,'',undefined,{...image,bytesBase64:'not allowed'}).writes,403);
  await commit(alice.token,sendWrites(alice,'',undefined,{...image,name:'a'.repeat(121)}).writes,403);
  const badImagePreview = sendWrites(alice,'',undefined,image);
  badImagePreview.writes[1].update.fields.lastMessageText = encode('Preview khác');
  await commit(alice.token,badImagePreview.writes,403);
  await commit(alice.token,[write(path,{memberIds:[alice.id,outsider.id]},['memberIds'])],403);
  await commit(alice.token,[write(path,{},[],[`readAt.${bob.id}`])],403);
  await commit(bob.token,[write(path,{},[],[`readAt.${bob.id}`])]);
  await commit(bob.token,sendWrites(bob,'Mình cũng thích món này!').writes);
  const deletionPath = `users/${alice.id}/chat_deletions/${conversationId}`;
  const through = (await get(alice.token,path)).fields.updatedAt;
  const deletion = (ownerId, cutoff = through) => ({update:{
    name:`${prefix}/users/${ownerId}/chat_deletions/${conversationId}`,fields:{through:cutoff},
  }});
  await commit(alice.token,[deletion(alice.id,{timestampValue:'2099-01-01T00:00:00Z'})],403);
  await commit(outsider.token,[deletion(outsider.id)],403);
  await commit(bob.token,[deletion(alice.id)],403);
  await commit(alice.token,[deletion(alice.id)]);
  await get(alice.token,deletionPath);
  await get(bob.token,deletionPath,403);
  await get(bob.token,`${path}/messages/${first.id}`);
  await commit(bob.token,sendWrites(bob,'Tin nhắn mới sau khi xóa').writes);
  assert.equal((await get(alice.token,deletionPath)).fields.through.timestampValue,through.timestampValue);
  await commit(alice.token,[{delete:`${prefix}/${path}`}],403);
  // Query inbox phải kèm membership; rules không hoạt động như bộ lọc hậu kỳ.
  const query = member => ({structuredQuery:{from:[{collectionId:'conversations'}],
    ...(member ? {where:{fieldFilter:{field:{fieldPath:'memberIds'},op:'ARRAY_CONTAINS',value:encode(member)}}} : {}),
    orderBy:[{field:{fieldPath:'updatedAt'},direction:'DESCENDING'}],limit:50}});
  await request(`${base}:runQuery`,'POST',query(alice.id),alice.token);
  await request(`${base}:runQuery`,'POST',query(null),alice.token,403);
  await request(`${base}:runQuery`,'POST',query(bob.id),outsider.token,403);
  const receipt = `users/${alice.id}/notification_reads/${recipeId}_approved`;
  await commit(alice.token,[write(receipt,{},null,['readAt'])]);
  await get(alice.token,receipt);
  await get(bob.token,receipt,403);
  await commit(bob.token,[write(receipt,{},null,['readAt'])],403);
  await commit(alice.token,[write(receipt,{title:'Tự tạo kết quả duyệt'},null,['readAt'])],403);
  await commit(alice.token,[write(`recipes/${recipeId}`,{status:'approved'},['status'])],403);
  await commit('owner',[write(`users/${alice.id}`,{status:'locked'},['status'])]);
  await get(alice.token,path,403);
  await get(alice.token,deletionPath,403);
  await commit(alice.token,sendWrites(alice,'Đã khóa').writes,403);
  console.log(`Communication rules: ${checks} checks passed (demo emulator only).`);
})().catch(error => {console.error(error.message); process.exitCode=1;});
