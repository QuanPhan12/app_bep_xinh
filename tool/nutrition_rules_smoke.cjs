const assert=require('node:assert/strict');
const {encode}=require('./firebase_cli_client.cjs');
assert.equal(process.env.FIRESTORE_EMULATOR_HOST,'127.0.0.1:8080');
const root='projects/demo-bepxinh/databases/(default)/documents',base=`http://127.0.0.1:8080/v1/${root}`;let checks=0;
async function call(url,token,body,status=200,method='POST'){
  const res=await fetch(url,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},
    ...(body===undefined?{}:{body:JSON.stringify(body)})});const data=await res.json();
  assert.equal(res.status,status,`${method} ${new URL(url).pathname}: ${JSON.stringify(data.error??{})}`);checks++;return data;
}
const write=(name,data)=>({update:{name,fields:encode(data).mapValue.fields}});
const stamp=()=>({fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'});
const commit=(token,writes,status=200)=>call(`${base}:commit`,token,{writes},status);
(async()=>{
  await commit('owner',[write(`${root}/ai_settings/runtime`,{enabled:true,provider:'gemini',model:'emulator-model',
    apiKey:'emulator-only-no-real-key',endpoint:'https://generativelanguage.googleapis.com',dailyLimit:40,version:1})]);
  const users=[];
  for(const label of ['alice','bob']){
    const user=await call('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo',null,
      {email:`nutrition-${label}-${Date.now()}@example.test`,password:'Emulator-only-123!',returnSecureToken:true});
    await commit('owner',[write(`${root}/users/${user.localId}`,{id:user.localId,status:'active',role:'user'})]);users.push(user);
  }
  const [alice,bob]=users,id='1'.repeat(32),journal=`${root}/users/${alice.localId}/nutrition_logs/${id}`;
  const log={schemaVersion:1,title:'Bữa ăn',day:'2026-11-27',slot:'lunch',bodyJson:'{}'};
  const logWrite=data=>({...write(journal,data),updateTransforms:[stamp()]});
  await commit(null,[logWrite(log)],403);await commit(bob.idToken,[logWrite(log)],403);
  await commit(alice.idToken,[logWrite({...log,slot:'invalid'})],403);
  await commit(alice.idToken,[logWrite({...log,bodyJson:'x'.repeat(100001)})],403);
  await commit(alice.idToken,[logWrite(log)]);
  await commit(alice.idToken,[logWrite({...log,title:'Overwrite'})],403);
  await call(`http://127.0.0.1:8080/v1/${journal}`,bob.idToken,undefined,403,'GET');
  const job=`${root}/ai_nutrition_threads/${alice.localId}/requests/${id}`;
  const payload={digest:'a'.repeat(64),status:'processing',lease:1,attempts:1,resultJson:null};
  await commit(bob.idToken,[write(job,payload)],403);
  await commit(alice.idToken,[write(job,{...payload,digest:'invalid'})],403);
  await commit(alice.idToken,[write(job,payload)]);
  await commit(alice.idToken,[write(job,{...payload,digest:'b'.repeat(64)})],403);
  await commit(alice.idToken,[write(job,{...payload,status:'done',resultJson:'{"items":[]}'})]);
  await commit(alice.idToken,[write(job,payload)],403);
  await call(`http://127.0.0.1:8080/v1/${job}`,bob.idToken,undefined,403,'GET');
  const addition=`${root}/catalogs/ingredients/additions/ai_${'b'.repeat(64)}`;
  const ingredient={schemaVersion:1,name:'Nấm thử emulator',nameKey:'nam thu emulator',source:'nutrition_ai',requestId:id};
  const ingredientWrite=data=>({...write(addition,data),updateTransforms:[stamp()]});
  await commit(null,[ingredientWrite(ingredient)],403);
  await commit(bob.idToken,[ingredientWrite(ingredient)],403);
  await commit(alice.idToken,[ingredientWrite({...ingredient,kcal:123})],403);
  await commit(alice.idToken,[ingredientWrite({...ingredient,name:''})],403);
  await commit(alice.idToken,[ingredientWrite({...ingredient,name:'x'.repeat(81)})],403);
  await commit(alice.idToken,[ingredientWrite(ingredient)]);
  await call(`http://127.0.0.1:8080/v1/${addition}`,null,undefined,200,'GET');
  await commit(alice.idToken,[ingredientWrite({...ingredient,name:'Overwrite'})],403);
  await commit(alice.idToken,[{delete:addition}],403);
  await commit('owner',[{delete:addition}]);
  await commit(alice.idToken,[{delete:journal}]);
  await commit('owner',[write(`${root}/users/${alice.localId}`,{id:alice.localId,status:'locked',role:'user'})]);
  await commit(alice.idToken,[logWrite(log)],403);
  await commit(alice.idToken,[ingredientWrite(ingredient)],403);
  console.log(`PASS: ${checks} nutrition privacy, immutability, size and account checks`);
})().catch(error=>{console.error(error.message);process.exitCode=1;});
