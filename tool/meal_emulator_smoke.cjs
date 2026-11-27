const {spawnSync}=require('node:child_process');
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8080')throw new Error('Only demo emulator is allowed');
for(const script of ['firebase_emulator_smoke.cjs','engagement_rules_smoke.cjs','meal_rules_smoke.cjs','firebase_sdk_browser_smoke.cjs']){
  const result=spawnSync(process.execPath,[`tool/${script}`],{stdio:'inherit',windowsHide:true});
  if(result.status!==0)process.exit(result.status??1);
}
