const crypto=require('node:crypto');
const {firebaseClient,decode}=require('./firebase_cli_client.cjs');
const {buildUserReviewWrites}=require('./user_review_moderation_logic.cjs');
const option=name=>{const i=process.argv.indexOf(name);return i<0?undefined:process.argv[i+1];};
(async()=>{
  const project=option('--project'),recipeId=option('--recipe'),reviewerId=option('--reviewer'),decision=option('--decision');
  if(project!=='bepxinh-b0be7'||!/^[A-Za-z0-9_-]{1,128}$/.test(recipeId||''))throw Error('Explicit --project bepxinh-b0be7 --recipe ID required');
  const {api,user}=await firebaseClient(project),base=`/v1/projects/${project}/databases/(default)/documents`;
  const unpack=response=>decode({mapValue:{fields:response.body.fields}});
  if(process.argv.includes('--list')){
    const result=await api.post(`${base}/recipes/${recipeId}:runQuery`,{structuredQuery:{from:[{collectionId:'user_reviews'}],where:{fieldFilter:{field:{fieldPath:'status'},op:'EQUAL',value:{stringValue:'pending'}}},limit:50}});
    // Nội dung chỉ hiển thị trong phiên duyệt chủ động, không ghi file log tự động.
    for(const row of result.body)if(row.document){const d=decode({mapValue:{fields:row.document.fields}});console.log(JSON.stringify({reviewer:d.uid,stars:d.stars,body:d.body}));}return;
  }
  if(!/^[A-Za-z0-9_-]{1,128}$/.test(reviewerId||'')||!['approve','hide'].includes(decision))throw Error('--reviewer UID --decision approve|hide required');
  const principal=user?.user_id||user?.sub||user?.email;if(!principal)throw Error('Cannot identify IAM operator');
  const operator=`iam:${crypto.createHash('sha256').update(principal).digest('hex').slice(0,32)}`;
  for(let attempt=0;attempt<3;attempt++){
    const transaction=(await api.post(`${base}:beginTransaction`,{})).body.transaction;let committed=false;
    try{
      const read=path=>api.get(`${base}/${path}`,{queryParams:{transaction}});
      const recipe=unpack(await read(`recipes/${recipeId}`));if(recipe.status!=='approved'||recipe.authorId===reviewerId)throw Error('Recipe unavailable or self review');
      const response=await read(`recipes/${recipeId}/user_reviews/${reviewerId}`),review=unpack(response);
      let aggregate=null;try{aggregate=unpack(await read(`recipes/${recipeId}/ratings/summary`));}catch(error){if(error.status!==404)throw error;}
      const writes=buildUserReviewWrites({project,recipeId,reviewerId,review,aggregate,decision,updateTime:response.body.updateTime,operator});
      console.log(JSON.stringify({recipeId,reviewerId,decision,dryRun:!process.argv.includes('--apply')}));
      if(!process.argv.includes('--apply'))return;
      await api.post(`${base}:commit`,{transaction,writes});committed=true;return;
    }catch(error){if(attempt===2||(error.status!==409&&!String(error.message).includes('ABORTED')))throw error;}
    finally{if(!committed)await api.post(`${base}:rollback`,{transaction}).catch(()=>{});}
  }
})().catch(error=>{console.error(error.message);process.exitCode=1;});
