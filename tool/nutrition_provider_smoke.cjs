const fs=require('node:fs');
const assert=require('node:assert/strict');
const {firebaseClient,decode}=require('./firebase_cli_client.cjs');
(async()=>{
  assert.deepEqual(process.argv.slice(2),['--live'],'Explicit --live required for one provider request');
  const {api}=await firebaseClient('bepxinh-b0be7');
  const response=await api.get('/v1/projects/bepxinh-b0be7/databases/(default)/documents/ai_settings/runtime',{skipLog:{resBody:true}});
  const config=decode({mapValue:{fields:response.body.fields}});
  assert.equal(config.enabled,true,'Shared AI is disabled');assert.ok(config.apiKey);
  assert.match(config.model,/^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$/);
  const endpoint=new URL(config.endpoint);assert.equal(endpoint.protocol,'https:');
  assert.equal(endpoint.username,'');assert.equal(endpoint.password,'');assert.equal(endpoint.search,'');assert.equal(endpoint.hash,'');
  const catalog=JSON.parse(fs.readFileSync('assets/nutrition/usda_sr_legacy.json','utf8'));
  const refs=catalog.foods.filter(food=>food.ingredientId).map(({id,name,description})=>({id,name,description}));
  const image=fs.readFileSync('assets/images/salad_uc_ga.jpg').toString('base64');
  const guide='Nhận diện tối đa 3 thành phần trong ảnh món ăn mẫu công khai. Chỉ trả JSON {"items":[{"name":"tên tiếng Việt","foodId":"ID trong REFERENCES hoặc null","grams":số gram ước tính}]}. Không trả calo. REFERENCES: '+JSON.stringify(refs);
  const gemini=config.provider==='gemini';
  if(gemini)assert.equal(endpoint.hostname,'generativelanguage.googleapis.com');
  const url=gemini?`https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent`:
    `${config.endpoint.replace(/\/+$/,'')}/chat/completions`;
  const body=gemini?{systemInstruction:{parts:[{text:guide}]},contents:[{role:'user',parts:[{text:'Nhận diện món trong ảnh.'},
    {inline_data:{mime_type:'image/jpeg',data:image}}]}],generationConfig:{maxOutputTokens:2048,responseMimeType:'application/json'}}:
    {model:config.model,messages:[{role:'system',content:guide},{role:'user',content:[{type:'text',text:'Nhận diện món trong ảnh.'},
      {type:'image_url',image_url:{url:`data:image/jpeg;base64,${image}`}}]}],
      [endpoint.hostname==='api.openai.com'?'max_completion_tokens':'max_tokens']:2048,response_format:{type:'json_object'}};
  const result=await fetch(url,{method:'POST',signal:AbortSignal.timeout(45000),headers:{'Content-Type':'application/json',
    ...(gemini?{'x-goog-api-key':config.apiKey}:{Authorization:`Bearer ${config.apiKey}`})},body:JSON.stringify(body)});
  assert.equal(result.status,200,`Shared provider returned HTTP ${result.status}`);
  const data=await result.json();
  const raw=gemini?data.candidates?.[0]?.content?.parts?.filter(p=>!p.thought).map(p=>p.text??'').join(''):data.choices?.[0]?.message?.content;
  assert.equal(typeof raw,'string');assert.ok(!raw.includes(config.apiKey),'Invalid provider output');
  const answer=JSON.parse(raw.trim().replace(/^```(?:json)?\s*/i,'').replace(/\s*```$/,''));
  assert.ok(Array.isArray(answer.items)&&answer.items.length>0&&answer.items.length<=3,'Invalid recognition response');
  const report={checkedAt:new Date().toISOString(),provider:config.provider,model:config.model,
    image:'public bundled salad_uc_ga.jpg',imageRecognized:true,items:answer.items.length,sharedConfig:true};
  fs.mkdirSync('build/nutrition',{recursive:true});fs.writeFileSync('build/nutrition/provider-smoke.json',JSON.stringify(report,null,2));
  console.log(JSON.stringify(report));
  console.log('PASS: configured Chat AI model recognized a public meal photo; no user data written');
})().catch(()=>{console.error('FAIL: shared provider recognition did not pass; credentials and raw provider output withheld.');process.exitCode=1;});
