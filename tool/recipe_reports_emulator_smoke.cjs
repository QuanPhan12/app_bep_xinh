// Tài khoản và dữ liệu giả chỉ dùng trong demo emulator.
const assert=require('node:assert/strict'),crypto=require('node:crypto');
const {encode}=require('./firebase_cli_client.cjs');
assert.equal(process.env.FIRESTORE_EMULATOR_HOST,'127.0.0.1:8080');assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST,'127.0.0.1:9099');
const root='projects/demo-bepxinh/databases/(default)/documents',base=`http://127.0.0.1:8080/v1/${root}`;let checks=0;
async function request(url,method,body,token,expected=200){const r=await fetch(url,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},...(body?{body:JSON.stringify(body)}:{})});const data=await r.json();assert.equal(r.status,expected,JSON.stringify(data.error||{}));checks++;return data;}
const write=(path,data,mask,stamps=[])=>({update:{name:`${root}/${path}`,fields:encode(data).mapValue.fields},...(mask?{updateMask:{fieldPaths:mask}}:{}),updateTransforms:stamps.map(fieldPath=>({fieldPath,setToServerValue:'REQUEST_TIME'}))});
const commit=(writes,token,code=200)=>request(`${base}:commit`,'POST',{writes},token,code);
const get=(path,token,code=200)=>request(`${base}/${path}`,'GET',undefined,token,code);
async function account(role){const result=await request('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo','POST',{email:`report-${crypto.randomUUID()}@example.test`,password:'EmulatorOnly123!',returnSecureToken:true});const a={id:result.localId,token:result.idToken};await commit([write(`users/${a.id}`,{id:a.id,role,status:'active'})],'owner');return a;}
(async()=>{
  const author=await account('user'),reporter=await account('user'),other=await account('user'),admin=await account('admin'),moderator=await account('moderator');
  const id=`r_report_${crypto.randomUUID()}`;
  const seed=status=>write(`recipes/${id}`,{schemaVersion:2,id,authorId:author.id,status,isBanner:true,content:{title:'Report fixture'},reviewedAt:null,reviewedBy:null,reviewReason:null});
  await commit([seed('approved')],'owner');
  const path=`recipe_reports/${reporter.id}:${id}`;
  const report=(overrides={})=>write(path,{recipeId:id,recipeTitle:'Report fixture',reporterId:reporter.id,category:'unsafe',reason:'Hướng dẫn cần xem xét',status:'open',resolution:null,resolutionReason:null,resolvedBy:null,resolvedAt:null,...overrides},null,['createdAt']);
  await get(path,reporter.token,404);
  await commit([report()],null,403);
  await commit([report()],author.token,403);
  await commit([write(`recipe_reports/${author.id}:${id}`,{recipeId:id,recipeTitle:'Report fixture',reporterId:author.id,category:'unsafe',reason:'Self report',status:'open',resolution:null,resolutionReason:null,resolvedBy:null,resolvedAt:null},null,['createdAt'])],author.token,403);
  for(const bad of [{reporterId:other.id},{recipeTitle:'Forged title'},{category:'fake'},{reason:'   '},{reason:'x'.repeat(501)},{status:'resolved'},{resolvedBy:admin.id}]) await commit([report(bad)],reporter.token,403);
  await commit([report()],reporter.token);
  await commit([report()],reporter.token,403);
  await get(path,reporter.token);await get(path,other.token,403);await get(path,author.token,403);
  await get('recipe_reports',reporter.token,403);await get('recipe_reports',moderator.token);await get(path,admin.token);
  await commit([write(path,{reason:'Changed'},['reason'])],reporter.token,403);
  const resolution=(actor,status='resolved',kind='hidden',reason='Vi phạm hướng dẫn')=>write(path,{status,resolution:kind,resolutionReason:reason,resolvedBy:actor.id},['status','resolution','resolutionReason','resolvedBy'],['resolvedAt']);
  await commit([resolution(moderator,'dismissed','dismissed')],moderator.token,403);
  await commit([resolution(reporter,'dismissed','dismissed')],reporter.token,403);
  await commit([resolution(admin)],admin.token,403);
  await commit([resolution(admin,'resolved','unavailable')],admin.token,403);
  await commit([resolution(admin,'dismissed','dismissed','')],admin.token,403);
  const event=crypto.randomUUID();
  const hide=[write(`recipes/${id}`,{status:'hidden',isBanner:false,visibilityEventId:event,visibilityActor:admin.id,visibilityRole:'admin',visibilityReason:'Vi phạm hướng dẫn'},['status','isBanner','visibilityEventId','visibilityActor','visibilityRole','visibilityReason'],['visibilityAt']),write(`recipes/${id}/visibility_events/${event}`,{actor:admin.id,role:'admin',reason:'Vi phạm hướng dẫn',fromStatus:'approved',toStatus:'hidden'},null,['createdAt'])];
  await commit([resolution(admin),...hide],admin.token);
  const result=await get(path,reporter.token);assert.equal(result.fields.status.stringValue,'resolved');checks++;
  const post=await get(`recipes/${id}`,admin.token);assert.equal(post.fields.isBanner.booleanValue,false);checks++;
  await get(`recipes/${id}`,null,403);
  await commit([resolution(admin,'dismissed','dismissed')],admin.token,403);
  await commit([{delete:`${root}/${path}`}],admin.token,403);
  // Một người khác không thể báo cáo bài đã ẩn; staff vẫn xử lý được báo cáo đã gửi trước.
  await commit([write(`recipe_reports/${other.id}:${id}`,{recipeId:id,recipeTitle:'Report fixture',reporterId:other.id,category:'spam',reason:'Spam',status:'open',resolution:null,resolutionReason:null,resolvedBy:null,resolvedAt:null},null,['createdAt'])],other.token,403);
  await commit([report({status:'open'})],'owner');
  await commit([resolution(admin,'resolved','unavailable')],admin.token);
  await commit([seed('approved'),report({status:'open'})],'owner');
  await commit([resolution(admin,'dismissed','dismissed','Không thấy vi phạm')],admin.token);
  assert.equal((await get(`recipes/${id}`,null)).fields.status.stringValue,'approved');checks++;
  await commit([seed('pending')],'owner');
  await commit([report()],other.token,403);
  await commit([seed('approved'),write(`users/${other.id}`,{status:'locked'},['status'])],'owner');
  await commit([write(`recipe_reports/${other.id}:${id}`,{recipeId:id,recipeTitle:'Report fixture',reporterId:other.id,category:'other',reason:'Locked reporter',status:'open',resolution:null,resolutionReason:null,resolvedBy:null,resolvedAt:null},null,['createdAt'])],other.token,403);
  console.log(`PASS: ${checks} recipe report emulator checks`);
})().catch(e=>{console.error(e);process.exitCode=1;});
