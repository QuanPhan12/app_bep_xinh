// Chỉ kiểm thử emulator demo trên cổng riêng, không cho phép ghi production.
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const {encode} = require('./firebase_cli_client.cjs');
assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8180');
assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST, '127.0.0.1:9199');
const prefix = 'projects/demo-bepxinh/databases/(default)/documents';
const base = `http://127.0.0.1:8180/v1/${prefix}`;
let checks=0;
async function request(url,method,body,token,expected=200) {
  const response=await fetch(url,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},...(body?{body:JSON.stringify(body)}:{})});
  const result=await response.json();
  assert.equal(response.status,expected,`${method} ${new URL(url).pathname}: ${JSON.stringify(result.error||{})}`); checks++;return result;
}
const write=(path,data,stamps=['updatedAt'])=>({update:{name:`${prefix}/${path}`,fields:encode(data).mapValue.fields},updateTransforms:stamps.map(fieldPath=>({fieldPath,setToServerValue:'REQUEST_TIME'}))});
const commit=(token,writes,status=200)=>request(`${base}:commit`,'POST',{writes},token,status);
const get=(token,path,status=200)=>request(`${base}/${path}`,'GET',null,token,status);
async function user(name,role='user') {
  const auth=await request('http://127.0.0.1:9199/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo','POST',
    {email:`${crypto.randomUUID()}@example.test`,password:'EmulatorOnly123!',returnSecureToken:true});
  await commit('owner',[write(`users/${auth.localId}`,{id:auth.localId,name,status:'active',role})]);
  return {id:auth.localId,token:auth.idToken,name};
}
(async()=>{
  const alice=await user('Alice'),bob=await user('Bob'),mod=await user('Moderator','moderator');
  const rid=`r_${crypto.randomUUID()}`,recipe={id:rid,title:'Món thử',authorId:bob.id};
  await commit('owner',[write(`recipes/${rid}`,{id:rid,authorId:bob.id,status:'approved'})]);
  const entries={
    meal_plans:{day:'2026-11-16',slot:'lunch',recipe,servings:2},
    recipe_collections:{name:'Cuối tuần',recipeIds:{[rid]:true}},
    cooking_logs:{recipe,day:'2026-11-16',servings:2,note:'Ghi chú riêng'},
    pantry_lots:{ingredientId:'egg',name:'Trứng',amount:3,unitId:'piece',expiresOn:'2026-11-20'},
    following:{name:'Bob'},
  };
  for(const [kind,data] of Object.entries(entries)) {
    const path=`users/${alice.id}/${kind}/${kind==='following'?bob.id:'entry'}`;
    await commit(alice.token,[write(path,{...data,schemaVersion:1})]);
    await get(alice.token,path);await get(bob.token,path,403);await get(null,path,403);
    await commit(bob.token,[write(path,{...data,schemaVersion:1})],403);
    await commit(alice.token,[write(path,{...data,schemaVersion:1,unexpected:true})],403);
    const query={structuredQuery:{from:[{collectionId:kind}],orderBy:[{field:{fieldPath:'updatedAt'},direction:'DESCENDING'}],limit:500}};
    await request(`${base}/users/${alice.id}:runQuery`,'POST',query,alice.token);
  }
  const pantry=`users/${alice.id}/pantry_lots/entry`;
  await commit(alice.token,[write(pantry,{...entries.pantry_lots,schemaVersion:1,amount:-1})],403);
  await commit(alice.token,[write(pantry,{...entries.pantry_lots,schemaVersion:1,amount:1,unitId:null})],403);
  await commit(alice.token,[write(`users/${alice.id}/following/${alice.id}`,{schemaVersion:1,name:'Alice'})],403);
  await commit(alice.token,[write(`users/${alice.id}/recipe_collections/bad`,{schemaVersion:1,name:'Bad',recipeIds:{x:false}})],403);
  const review=`recipes/${rid}/user_reviews/${alice.id}`,rating=`recipes/${rid}/ratings/summary`;
  const data={uid:alice.id,name:'Alice',stars:4,body:'Rất ngon',status:'pending'};
  const aggregate=(sum,count)=>write(rating,{sum,count,lastReviewerId:alice.id});
  await get(alice.token,review,404);
  await commit(alice.token,[write(review,data)],403);
  await commit(alice.token,[write(review,{...data,status:'approved'}),aggregate(4,1)],403);
  await commit(alice.token,[write(review,data),aggregate(0,0)]);
  await get(alice.token,review);await get(null,review,403);await get(bob.token,review,403);
  await get(null,rating);
  await commit(alice.token,[aggregate(100,20)],403);
  await commit(mod.token,[write(review,{...data,status:'approved'}),aggregate(3,1)],403);
  await commit(mod.token,[write(review,{...data,status:'approved'}),aggregate(4,1)]);
  await get(null,review);
  const approvedQuery={structuredQuery:{from:[{collectionId:'user_reviews'}],where:{fieldFilter:{field:{fieldPath:'status'},op:'EQUAL',value:encode('approved')}},orderBy:[{field:{fieldPath:'updatedAt'},direction:'DESCENDING'},{field:{fieldPath:'__name__'},direction:'DESCENDING'}],limit:20}};
  await request(`${base}/recipes/${rid}:runQuery`,'POST',approvedQuery,null);
  await request(`${base}/recipes/${rid}:runQuery`,'POST',{structuredQuery:{from:[{collectionId:'user_reviews'}]}},null,403);
  const report=`${review}/reports/${bob.id}`;
  await commit(bob.token,[write(report,{reason:'Cần kiểm tra'})]);await get(mod.token,report);await get(alice.token,report,403);
  await commit(alice.token,[write(`${review}/reports/${alice.id}`,{reason:'Tự báo cáo'})],403);
  await commit(alice.token,[write(review,{...data,stars:5}),aggregate(0,0)]);
  await get(null,review,403);
  await commit(mod.token,[write(review,{...data,stars:5,status:'approved'}),aggregate(5,1)]);
  await commit(mod.token,[write(review,{...data,stars:5,status:'hidden'}),aggregate(0,0)]);
  await commit(alice.token,[{delete:`${prefix}/${review}`},aggregate(0,0)]);
  await commit(bob.token,[write(`recipes/${rid}/user_reviews/${bob.id}`,{...data,uid:bob.id,name:'Bob'}),write(rating,{sum:0,count:0,lastReviewerId:bob.id})],403);
  await commit('owner',[write(`users/${alice.id}`,{id:alice.id,name:'Alice',status:'locked'})]);
  await get(alice.token,pantry,403);await commit(alice.token,[{delete:`${prefix}/${pantry}`}],403);
  console.log(`PASS ${checks} kitchen emulator assertions`);
})().catch(error=>{console.error(error);process.exitCode=1;});
