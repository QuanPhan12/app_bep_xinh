const assert=require('node:assert/strict');
const {encode}=require('./firebase_cli_client.cjs');
assert.equal(process.env.FIRESTORE_EMULATOR_HOST,'127.0.0.1:8080');
const root='projects/demo-bepxinh/databases/(default)/documents';
const base=`http://127.0.0.1:8080/v1/${root}`;let checks=0;
async function request(url,token,body,status=200,method='POST'){
  const response=await fetch(url,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},
    ...(body===undefined?{}:{body:JSON.stringify(body)})});
  assert.equal(response.status,status,`${method} ${new URL(url).pathname}`);checks++;return response.json();
}
const write=(name,data,fields)=>({update:{name,fields:encode(data).mapValue.fields},...(fields?{updateMask:{fieldPaths:fields}}:{})});
const stamp=()=>({fieldPath:'createdAt',setToServerValue:'REQUEST_TIME'});
const commit=(token,writes,status=200)=>request(`${base}:commit`,token,{writes},status);
(async()=>{
  const users=[];
  for(const label of ['alice','bob','admin']){
    const user=await request('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo',null,
      {email:`engagement-${label}-${Date.now()}@example.test`,password:'Emulator-only-123!',returnSecureToken:true});
    await commit('owner',[write(`${root}/users/${user.localId}`,{id:user.localId,status:'active',role:label==='admin'?'admin':'user'})]);
    users.push(user);
  }
  const [alice,bob,admin]=users,post=`${root}/recipes/r_engagement_rules`;
  await commit('owner',[write(post,{status:'approved',authorId:bob.localId,engagement:{likeCount:0,shareCount:0}}),
    write(`${root}/recipes/r_sdk_engagement`,{status:'approved',authorId:bob.localId,engagement:{likeCount:0,shareCount:0}})]);
  const aggregate=(likeCount,shareCount)=>write(post,{engagement:{likeCount,shareCount}},['engagement']);
  const share=user=>({...write(`${post}/shares/${user.localId}`,{uid:user.localId,channel:'copy'}),updateTransforms:[stamp()]});
  const favorite=user=>({...write(`${root}/users/${user.localId}/favorites/r_engagement_rules`,{recipeId:'r_engagement_rules'}),updateTransforms:[stamp()]});
  const remove=user=>({delete:`${root}/users/${user.localId}/favorites/r_engagement_rules`});
  await commit(null,[share(alice),aggregate(0,1)],403);
  await commit(bob.idToken,[share(alice),aggregate(0,1)],403);
  await commit(alice.idToken,[share(alice)],403);
  await commit(alice.idToken,[share(alice),aggregate(0,999)],403);
  await commit(alice.idToken,[share(alice),aggregate(0,1)]);
  await commit(alice.idToken,[share(alice),aggregate(0,2)],403);
  await commit(alice.idToken,[favorite(alice)],403);
  await commit(alice.idToken,[favorite(alice),aggregate(1,1)]);
  await commit(alice.idToken,[favorite(alice),aggregate(2,1)],403);
  await commit(bob.idToken,[favorite(bob),aggregate(2,1)]);
  await commit(alice.idToken,[remove(alice),aggregate(1,1)]);
  await commit(alice.idToken,[remove(alice),aggregate(0,1)],403);
  const url=`http://127.0.0.1:8080/v1/${post}/shares/${alice.localId}`;
  await request(url,alice.idToken,undefined,200,'GET');
  await request(url,bob.idToken,undefined,403,'GET');
  await request(url,null,undefined,403,'GET');
  for(const user of [alice,admin])await commit(user.idToken,[aggregate(999,999)],403);
  await commit('owner',[write(post,{status:'hidden'},['status'])]);
  await commit(bob.idToken,[remove(bob),aggregate(0,1)]);
  await commit(bob.idToken,[share(bob),aggregate(0,2)],403);
  const result=await request(`http://127.0.0.1:8080/v1/${post}`,'owner',undefined,200,'GET');
  assert.deepEqual(result.fields.engagement.mapValue.fields,{likeCount:{integerValue:'0'},shareCount:{integerValue:'1'}});
  console.log(`PASS: ${checks} atomic engagement, privacy and duplicate-write checks`);
})().catch(error=>{console.error(error.message);process.exitCode=1;});
