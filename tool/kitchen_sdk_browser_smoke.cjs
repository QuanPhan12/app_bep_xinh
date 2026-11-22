const {spawn}=require('node:child_process');const path=require('node:path');const fs=require('node:fs');const assert=require('node:assert/strict');
const {encode}=require('./firebase_cli_client.cjs');const delay=ms=>new Promise(resolve=>setTimeout(resolve,ms));
assert.equal(process.env.FIRESTORE_EMULATOR_HOST,'127.0.0.1:8180');assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST,'127.0.0.1:9199');
const prefix='projects/demo-bepxinh/databases/(default)/documents';
const write=(p,data)=>({update:{name:`${prefix}/${p}`,fields:encode(data).mapValue.fields}});
async function seed(command){
  const [action,uid]=command.split(':');assert.match(uid,/^[A-Za-z0-9]+$/);const writes=[];
  if(action==='KITCHEN_SEED'){
    const content=JSON.parse(fs.readFileSync('assets/mock/recipe_details.json','utf8')).recipes[0];
    for(let i=0;i<11;i++){const id=`kitchen_author_${String(i).padStart(2,'0')}`;writes.push(write(`users/${id}`,{id,name:`Author ${i}`,status:'active'}));}
    for(let i=0;i<25;i++){
      const id=`r_kitchen_${String(i).padStart(2,'0')}`,authorId=`kitchen_author_${String(i%11).padStart(2,'0')}`;
      const w=write(`recipes/${id}`,{id,authorId,status:'approved',author:{id:authorId,name:'Author',handle:'author'},content});
      w.update.fields.submittedAt={timestampValue:'2026-11-16T00:00:00.123456Z'};writes.push(w);
    }
  }else{
    assert.equal(action,'KITCHEN_APPROVE');
    const review=await (await fetch(`http://127.0.0.1:8180/v1/${prefix}/recipes/r_kitchen_00/user_reviews/${uid}`,{headers:{Authorization:'Bearer owner'}})).json();
    const approve={update:{name:review.name,fields:{...review.fields,status:encode('approved')}},updateTransforms:[{fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'}]};writes.push(approve);
    writes.push(write('recipes/r_kitchen_00/ratings/summary',{sum:96,count:24,lastReviewerId:uid}));
    for(let i=0;i<23;i++){const id=`reader_${String(i).padStart(2,'0')}`;const w=write(`recipes/r_kitchen_00/user_reviews/${id}`,{uid:id,name:'Reader',stars:4,body:'Approved fixture',status:'approved'});w.update.fields.updatedAt={timestampValue:`2026-11-15T00:00:00.${String(123000+i).padStart(6,'0')}Z`};writes.push(w);}
  }
  const response=await fetch(`http://127.0.0.1:8180/v1/${prefix}:commit`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer owner'},body:JSON.stringify({writes})});assert.equal(response.status,200,await response.text());
}
(async()=>{
  const server=spawn('python',['-m','http.server','11310','--bind','127.0.0.1','--directory','build/kitchen-smoke-web'],{windowsHide:true,stdio:'ignore'});
  const chrome=spawn(process.env.CHROME_EXECUTABLE||'C:/Program Files/Google/Chrome/Application/chrome.exe',['--headless','--no-sandbox','--no-first-run','--disable-extensions','--remote-debugging-port=11312',`--user-data-dir=${path.resolve('build/kitchen-sdk-browser-'+Date.now())}`,'about:blank'],{windowsHide:true,stdio:'ignore'});let ws;
  try{
    let pages;for(let i=0;i<30;i++){try{pages=await (await fetch('http://127.0.0.1:11312/json/list')).json();break;}catch{await delay(500);}}
    assert.ok(pages,'Chrome failed to start');ws=new WebSocket(pages.find(p=>p.type==='page').webSocketDebuggerUrl);await new Promise(resolve=>ws.addEventListener('open',resolve,{once:true}));
    let id=0;const pending=new Map();ws.addEventListener('message',event=>{const m=JSON.parse(event.data);if(pending.has(m.id)){pending.get(m.id)(m.result);pending.delete(m.id);}});
    const call=(method,params={})=>new Promise(resolve=>{const n=++id;pending.set(n,resolve);ws.send(JSON.stringify({id:n,method,params}));});
    await call('Network.enable');await call('Network.setBlockedURLs',{urls:['https://identitytoolkit.googleapis.com/*','https://securetoken.googleapis.com/*']});
    await call('Page.addScriptToEvaluateOnNewDocument',{source:"sessionStorage.setItem('[DEFAULT]-firebaseEmulatorOrigin','http://127.0.0.1:9199');"});
    await call('Page.navigate',{url:'http://127.0.0.1:11310/'});const seeded=new Set();
    for(let i=0;i<120;i++){
      const status=(await call('Runtime.evaluate',{expression:'globalThis.firebaseSmokeResult',returnByValue:true}))?.result?.value;
      if(typeof status==='string'){
        if(/^KITCHEN_(SEED|APPROVE):/.test(status)&&!seeded.has(status)){await seed(status);seeded.add(status);await call('Runtime.evaluate',{expression:"globalThis.firebaseSmokeResult='KITCHEN_READY'"});}
        if(status.startsWith('PASS:')){console.log(status);return;}if(status.startsWith('FAIL:'))throw Error(status);
      }await delay(500);
    }throw Error('SDK kitchen timeout');
  }finally{if(ws?.readyState===WebSocket.OPEN){ws.send(JSON.stringify({id:9999,method:'Browser.close'}));ws.close();}chrome.kill();server.kill();}
})().catch(error=>{console.error(error.message);process.exitCode=1;});
