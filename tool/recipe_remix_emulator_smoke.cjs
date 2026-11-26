// Chỉ dùng tài khoản và công thức giả trong Firebase Emulator, không ghi production.
const assert = require('node:assert/strict'), crypto = require('node:crypto');
const { encode } = require('./firebase_cli_client.cjs');
assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8080');
assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST, '127.0.0.1:9099');
const root = 'projects/demo-bepxinh/databases/(default)/documents';
const base = `http://127.0.0.1:8080/v1/${root}`; let checks = 0;
async function request(url, method, body, token, expected = 200) {
  const response = await fetch(url, { method, headers: {'Content-Type':'application/json',
    ...(token ? {Authorization:`Bearer ${token}`} : {})}, ...(body ? {body:JSON.stringify(body)} : {}) });
  const result = await response.json(); assert.equal(response.status, expected, JSON.stringify(result.error || {})); checks++; return result;
}
const write = (path, data, mask, stamps=[]) => ({update:{name:`${root}/${path}`,fields:encode(data).mapValue.fields},
  ...(mask ? {updateMask:{fieldPaths:mask}} : {}), updateTransforms:stamps.map(fieldPath=>({fieldPath,setToServerValue:'REQUEST_TIME'}))});
const commit = (writes, token, code=200) => request(`${base}:commit`,'POST',{writes},token,code);
const get = (path, token, code=200) => request(`${base}/${path}`,'GET',null,token,code);
async function account() {
  const value = await request('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo','POST',
    {email:`remix-${crypto.randomUUID()}@example.test`,password:'EmulatorOnly123!',returnSecureToken:true});
  const a = {id:value.localId,token:value.idToken,name:'Remix fixture',handle:`bep_${value.localId}`};
  await commit([write(`users/${a.id}`,{id:a.id,name:a.name,handle:a.handle,role:'user',status:'active'})],'owner'); return a;
}
(async()=>{
 const original = await account(), author = await account();
 const sourceId = `r_original_${crypto.randomUUID()}`, targetId = `r_remix_${crypto.randomUUID()}`;
 const content = {title:'Original recipe',description:'',cover:{id:'photo',name:'photo.png',publicId:'fixture',
   url:'https://res.cloudinary.com/ddqouziau/image/upload/v1/fixture.png'},preparationMinutes:5,cookingMinutes:10,
   servings:2,difficulty:'easy',meals:[],categories:[],storageNotes:'',ingredientGroups:[{id:'main',name:'Main'}],
   ingredients:[{id:'egg',name:'Egg',ingredientId:'egg',amount:2,unitId:'fruit',toTaste:false,note:'',groupId:'main'}],
   steps:[{id:'step_0',title:'',instruction:'Cook fully',minutes:null,tip:'',photo:null}]};
 content.photos = Array.from({length:9}, (_, i) => ({...content.cover, id:`extra_${i}`}));
 const sourceHash = 'a'.repeat(64);
 await commit([write(`recipes/${sourceId}`,{id:sourceId,schemaVersion:2,authorId:original.id,
   author:{id:original.id,name:original.name,handle:original.handle},status:'approved',content,contentHash:sourceHash,isBanner:false})],'owner');
 const remix = {recipeId:sourceId,title:content.title,authorId:original.id,authorName:original.name,sourceHash,changes:'Use less oil and add mushrooms.'};
 const payload = (id, m=remix) => ({id,schemaVersion:2,authorId:author.id,
   author:{id:author.id,name:author.name,handle:author.handle},isBanner:false,status:'pending',revisionOf:null,
   content:{...content,title:'Less oil recipe',description:'My variation'},contentHash:'b'.repeat(64),catalogVersion:'test',
   reviewedAt:null,reviewedBy:null,reviewReason:null,remix:m});
 const submit = (id,m,token,code=200) => commit([write(`recipes/${id}`,payload(id,m),null,['submittedAt'])],token,code);
 await submit(targetId,remix,null,403);
 await submit(targetId,remix,author.token);
 const saved = await get(`recipes/${targetId}`,author.token);
 assert.equal(saved.fields.authorId.stringValue,author.id); checks++;
 assert.equal(saved.fields.remix.mapValue.fields.authorId.stringValue,original.id); checks++;
 await get(`recipes/${targetId}`,null,403);
 for (const change of [{title:'Fake source'},{authorId:author.id},{authorName:'Fake author'},
   {sourceHash:'c'.repeat(64)},{changes:'short'},{changes:'x'.repeat(501)},{unexpected:true}]) {
   await submit(`r_invalid_${crypto.randomUUID()}`,{...remix,...change},author.token,403);
 }
 for (const status of ['pending','rejected','hidden','deleted']) {
   await commit([write(`recipes/${sourceId}`,{status},['status'])],'owner');
   await submit(`r_unavailable_${crypto.randomUUID()}`,remix,author.token,403);
 }
 await commit([write(`recipes/${sourceId}`,{status:'approved'},['status'])],'owner');
 await commit([write(`recipes/${targetId}`,{status:'approved'},['status'])],author.token,403);
 await commit([write(`recipes/${targetId}`,{remix:{...remix,authorName:'Changed'}},['remix'])],author.token,403);
 await commit([write(`users/${author.id}`,{status:'locked'},['status'])],'owner');
 await submit(`r_locked_${crypto.randomUUID()}`,remix,author.token,403);
 assert.equal((await get(`recipes/${sourceId}`,null)).fields.content.mapValue.fields.title.stringValue,content.title); checks++;
 console.log(`PASS: ${checks} remix emulator checks`);
})().catch(error=>{console.error(error);process.exitCode=1;});
