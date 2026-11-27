const assert=require('node:assert/strict');
const {encode}=require('./firebase_cli_client.cjs');
assert.equal(process.env.FIRESTORE_EMULATOR_HOST,'127.0.0.1:8080');
const root='projects/demo-bepxinh/databases/(default)/documents';
const base=`http://127.0.0.1:8080/v1/${root}`;let checks=0;
async function request(url,token,body,status=200,method='POST'){
  const response=await fetch(url,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},
    ...(body===undefined?{}:{body:JSON.stringify(body)})});
  const result=await response.json();assert.equal(response.status,status,`${method} ${new URL(url).pathname}: ${JSON.stringify(result.error??{})}`);checks++;return result;
}
const write=(name,data)=>({update:{name,fields:encode(data).mapValue.fields},updateTransforms:[{fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'}]});
const commit=(token,writes,status=200)=>request(`${base}:commit`,token,{writes},status);
(async()=>{
  const users=[];
  for(const label of ['alice','bob']){
    const user=await request('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo',null,
      {email:`meal-${label}-${Date.now()}@example.test`,password:'Emulator-only-123!',returnSecureToken:true});
    await commit('owner',[write(`${root}/users/${user.localId}`,{id:user.localId,status:'active',role:'user'})]);users.push(user);
  }
  const [alice,bob]=users,account=`${root}/users/${alice.localId}`,planPath=`${account}/meal_plans/meal`,sessionPath=`${account}/meal_sessions/meal`;
  const ref=id=>({id,title:`Món ${id}`,authorId:''});
  const plan={schemaVersion:2,name:'Bữa tối',day:'2026-11-27',slot:'dinner',servings:4,
    dishes:[{recipe:ref('a'),role:'main'},{recipe:ref('b'),role:'soup'}],preparedKeys:[]};
  await commit(alice.idToken,[write(`${account}/meal_plans/legacy`,{schemaVersion:1,day:plan.day,slot:'lunch',servings:2,recipe:ref('old')})]);
  await commit(null,[write(planPath,plan)],403);
  await commit(bob.idToken,[write(planPath,plan)],403);
  await commit(alice.idToken,[write(planPath,{...plan,dishes:[]})],403);
  await commit(alice.idToken,[write(planPath,{...plan,dishes:[...plan.dishes,plan.dishes[0]]})],403);
  await commit(alice.idToken,[write(planPath,{...plan,servings:0})],403);
  await commit(alice.idToken,[write(planPath,{...plan,dishes:[{...plan.dishes[0],role:'invalid'}]})],403);
  await commit(alice.idToken,[write(planPath,plan)]);
  const session={schemaVersion:1,plan,selectedRecipeId:'a',steps:{a:0,b:0},done:[],completed:false,pantryConsumed:false};
  await commit(alice.idToken,[write(sessionPath,{...session,plan:{...plan,servings:9}})],403);
  await commit(alice.idToken,[write(sessionPath,session)]);
  await commit(alice.idToken,[write(planPath,{...plan,servings:5})],403);
  await commit(alice.idToken,[{delete:planPath}],403);
  await commit(alice.idToken,[write(planPath,{...plan,preparedKeys:['checked']})]);
  await commit(alice.idToken,[write(sessionPath,{...session,selectedRecipeId:'x'})],403);
  await commit(alice.idToken,[write(sessionPath,{...session,steps:{a:20,b:0}})],403);
  await commit(alice.idToken,[write(sessionPath,{...session,done:['a'],completed:true})],403);
  const completed={...session,steps:{a:2,b:1},done:['a','b'],completed:true};
  await commit(alice.idToken,[write(sessionPath,completed)]);
  await commit(alice.idToken,[write(sessionPath,session)],403);
  await commit(alice.idToken,[write(sessionPath,{...completed,pantryConsumed:true})]);
  await commit(alice.idToken,[write(sessionPath,completed)],403);
  await request(`http://127.0.0.1:8080/v1/${sessionPath}`,bob.idToken,undefined,403,'GET');
  const shopping=`${account}/shopping_batches/meal`,cart={schemaVersion:1,title:'Bữa tối',linesJson:'[]'};
  await commit(alice.idToken,[write(shopping,cart)]);
  await commit(bob.idToken,[write(shopping,cart)],403);
  await commit(alice.idToken,[write(shopping,{...cart,linesJson:'x'.repeat(100001)})],403);
  await request(`http://127.0.0.1:8080/v1/${shopping}`,bob.idToken,undefined,403,'GET');
  // Phiên dùng dữ liệu cũ vẫn được nâng preparedKeys mà không đổi món/khẩu phần.
  const old={schemaVersion:1,day:plan.day,slot:'lunch',servings:2,recipe:ref('old')};
  await commit(alice.idToken,[write(`${account}/meal_sessions/legacy`,{...session,plan:old,selectedRecipeId:'old',steps:{old:0}})]);
  await commit(alice.idToken,[write(`${account}/meal_plans/legacy`,{schemaVersion:2,name:'',day:old.day,slot:old.slot,servings:old.servings,dishes:[{recipe:old.recipe,role:'other'}],preparedKeys:['yes']})]);
  console.log(`PASS: ${checks} meal schema, legacy, privacy and lifecycle checks`);
})().catch(error=>{console.error(error.message);process.exitCode=1;});
