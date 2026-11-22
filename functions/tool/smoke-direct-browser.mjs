import { spawn } from 'node:child_process';
import { mkdirSync } from 'node:fs';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
if (process.env.FIRESTORE_EMULATOR_HOST || !process.argv.includes('--live')) throw Error('Use --live for one direct provider request with saved trial configuration.');
initializeApp({projectId:'bepxinh-b0be7',credential:applicationDefault()});
const db=getFirestore(); let chrome, socket;
try {
  const config=(await db.doc('ai_settings/runtime').get()).data();
  if(!config?.enabled || config.provider!=='gemini' || !config.apiKey) throw Error('Enabled direct Gemini configuration required.');
  const profile=new URL(`../../build/report_temp/ai-direct-chrome-${Date.now()}/`,import.meta.url);mkdirSync(profile,{recursive:true});
  chrome=spawn('C:/Program Files/Google/Chrome/Application/chrome.exe',['--headless','--no-first-run','--disable-extensions','--remote-debugging-port=17502','--user-data-dir='+profile.pathname.replace(/^\/(\w:)/,'$1'),'https://bepxinh-admin.web.app/?view=settings'],{windowsHide:true,stdio:'ignore'});
  let page;
  for(let i=0;i<50;i++){try{page=(await(await fetch('http://127.0.0.1:17502/json/list')).json()).find(p=>p.type==='page');if(page)break;}catch{}await delay(200);}
  if(!page)throw Error('Chrome did not start.');
  socket=new WebSocket(page.webSocketDebuggerUrl);await new Promise((resolve,reject)=>{socket.addEventListener('open',resolve,{once:true});socket.addEventListener('error',reject,{once:true});});
  let serial=0;const pending=new Map();socket.addEventListener('message',event=>{const value=JSON.parse(event.data);if(value.id&&pending.has(value.id)){pending.get(value.id)(value);pending.delete(value.id);}});
  const call=(method,params={})=>new Promise(resolve=>{const id=++serial;pending.set(id,resolve);socket.send(JSON.stringify({id,method,params}));});
  await call('Runtime.enable');await delay(1500);
  // Key chỉ đi vào bộ nhớ trình duyệt thử nghiệm và header Gemini; không in ra stdout.
  const expression=`(async()=>{if(location.origin!=='https://bepxinh-admin.web.app')return {originOK:false};const key=${JSON.stringify(config.apiKey)};const r=await fetch('https://generativelanguage.googleapis.com/v1beta/models/'+encodeURIComponent(${JSON.stringify(config.model)})+':generateContent',{method:'POST',headers:{'Content-Type':'application/json','x-goog-api-key':key},body:JSON.stringify({contents:[{role:'user',parts:[{text:'Trả JSON duy nhất: {"reply":"Chào bạn","recipeIds":[]}.'}]}],generationConfig:{maxOutputTokens:2048,responseMimeType:'application/json'}}),signal:AbortSignal.timeout(40000)});if(!r.ok)return {originOK:true,http:r.status,validReply:false};const data=await r.json();const raw=(data.candidates?.[0]?.content?.parts??[]).filter(p=>!p.thought).map(p=>p.text??'').join('');if(raw.includes(key))return {originOK:true,http:r.status,validReply:false};try{const a=JSON.parse(raw);return {originOK:true,http:r.status,validReply:typeof a.reply==='string'&&Array.isArray(a.recipeIds)}}catch{return {originOK:true,http:r.status,validReply:false}}})()`;
  const result=await call('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true});
  const value=result.result?.result?.value;
  if(result.result?.exceptionDetails||!value?.validReply){console.log('Direct browser check:',value?{originOK:value.originOK,http:value.http,validReply:false}:{validReply:false});process.exitCode=1;}else console.log('PASS: direct Gemini call from live admin origin; HTTP 200, valid JSON reply.');
} finally {socket?.close();chrome?.kill();await db.terminate();}
