const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {firebaseClient}=require('./firebase_cli_client.cjs');
const PROJECT='bepxinh-b0be7';
const hash=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
(async()=>{
  await firebaseClient(PROJECT);
  const lib=process.env.PATH.split(path.delimiter).map(entry=>path.resolve(entry,'../firebase-tools/lib'))
    .find(candidate=>fs.existsSync(path.join(candidate,'apiv2.js')));
  assert.ok(lib,'Use pinned firebase-tools npm exec');
  const {Client}=require(path.join(lib,'apiv2'));
  const rules=new Client({urlPrefix:'https://firebaserules.googleapis.com',apiVersion:'v1',auth:true});
  const release=(await rules.get(`/projects/${PROJECT}/releases/cloud.firestore`)).body;
  const ruleset=(await rules.get(`/${release.rulesetName}`)).body;
  const remote=ruleset.source.files.find(file=>file.name==='firestore.rules').content.replace(/\r\n/g,'\n');
  const source=fs.readFileSync('firestore.rules','utf8').replace(/\r\n/g,'\n');
  assert.equal(remote,source,'Released rules must exactly match source');
  const hosting=new Client({urlPrefix:'https://firebasehosting.googleapis.com',apiVersion:'v1beta1',auth:true});
  const live=(await hosting.get(`/sites/${PROJECT}/channels/live`)).body;
  const artifacts={};
  const nutrition=process.argv.includes('--nutrition');
  const files=['index.html','main.dart.js','.well-known/assetlinks.json',
    ...(nutrition?['assets/assets/nutrition/usda_sr_legacy.json']:[])];
  for(const file of files) {
    const response=await fetch(`https://${PROJECT}.web.app/${file}?meal_release=${Date.now()}`,{
      redirect:'manual',signal:AbortSignal.timeout(60000)});
    assert.equal(response.status,200,`Public artifact ${file}`);
    const bytes=Buffer.from(await response.arrayBuffer());
    assert.equal(hash(bytes),hash(fs.readFileSync(path.join('build/web',file))),`Public artifact differs: ${file}`);
    if(file.endsWith('assetlinks.json'))assert.match(response.headers.get('content-type'),/application\/json/);
    artifacts[file]=hash(bytes);
  }
  const route=await fetch(`https://${PROJECT}.web.app/kitchen/meal-plan?meal_release=${Date.now()}`,{signal:AbortSignal.timeout(30000)});
  assert.equal(route.status,200);assert.equal(hash(Buffer.from(await route.arrayBuffer())),artifacts['index.html'],'SPA meal route serves app shell');
  const report={checkedAt:new Date().toISOString(),project:PROJECT,
    hostingVersion:live.release.version.name,ruleset:release.rulesetName,rulesUpdatedAt:release.updateTime,
    rulesSha256:hash(source),artifacts,mealRouteShell:true};
  fs.mkdirSync(nutrition?'build/nutrition':'build',{recursive:true});
  fs.writeFileSync(nutrition?'build/nutrition/release.json':'build/meal-release.json',JSON.stringify(report,null,2));
  console.log(JSON.stringify(report,null,2));
  console.log('PASS: live web artifacts, Android association and released Firestore rules match workspace');
})().catch(error=>{console.error(error.message);process.exitCode=1;});
