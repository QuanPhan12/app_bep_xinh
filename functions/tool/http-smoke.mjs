import assert from 'node:assert/strict';
if (process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080' || process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099') throw new Error('Demo emulator required');
const base='http://127.0.0.1:5001/demo-bepxinh/asia-southeast1/bepXinhAi';
async function token(email) { const r=await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email,password:'BepXinhLocal123!',returnSecureToken:true})});assert.equal(r.status,200);return (await r.json()).idToken; }
const user=await token('local-cook@example.test'),admin=await token('local-admin@example.test');
const call=(path,t,method='GET',body,origin)=>fetch(base+path,{method,headers:{...(t?{Authorization:`Bearer ${t}`} :{}),'Content-Type':'application/json',...(origin?{Origin:origin}:{})},...(body?{body:JSON.stringify(body)}:{})});
assert.equal((await call('/history')).status,401);
assert.equal((await call('/history','invalid')).status,401);
assert.equal((await call('/admin/config',user)).status,403);
assert.equal((await call('/history',user,'GET',null,'https://untrusted.example')).status,403);
assert.equal((await call('/history',user,'GET',null,'http://127.0.0.1:11500')).status,200);
assert.equal((await call('/admin/config',admin)).status,200);
for (const path of ['_ai_private/config','_ai_threads/any/messages']) {
  const response=await fetch(`http://127.0.0.1:8080/v1/projects/demo-bepxinh/databases/(default)/documents/${path}`,{headers:{Authorization:`Bearer ${admin}`}});
  assert.equal(response.status,403);
}
assert.equal((await call('/admin/config',admin,'PUT',{provider:'wrong'})).status,400);
assert.equal((await call('/chat',user,'POST',{requestId:'../invalid',message:'Hi'})).status,400);
assert.equal((await call('/chat',user,'POST',{requestId:'e'.repeat(32),message:'Gợi ý món'})).status,503);
console.log('PASS: 11 HTTP emulator auth/admin/CORS/private-storage/validation/disabled-AI checks; no provider called.');
