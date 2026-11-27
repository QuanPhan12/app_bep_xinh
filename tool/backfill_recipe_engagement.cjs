const {firebaseClient,encode,decode}=require('./firebase_cli_client.cjs');
const PROJECT='bepxinh-b0be7',root=`projects/${PROJECT}/databases/(default)/documents`;
const base=`/v1/${root}`,quiet={skipLog:{body:true,resBody:true}};
(async()=>{
  const args=process.argv.slice(2);
  if(args.length>1||args.some(arg=>!['--apply','--verify'].includes(arg)))throw Error('Use --apply, --verify or no arguments');
  const apply=args.includes('--apply'),verify=args.includes('--verify'),{api}=await firebaseClient(PROJECT);
  const unpack=doc=>decode({mapValue:{fields:doc.fields||{}}});
  async function query(collectionId,{allDescendants=false,transaction,parent=base}={}) {
    const documents=[];let after;
    for(;;){
      const response=await api.post(`${parent}:runQuery`,{structuredQuery:{
        from:[{collectionId,allDescendants}],orderBy:[{field:{fieldPath:'__name__'},direction:'ASCENDING'}],limit:200,
        ...(after?{startAt:{values:[{referenceValue:after}],before:false}}:{}),
      },...(transaction?{transaction}:{})},quiet);
      const page=response.body.filter(row=>row.document).map(row=>row.document);
      documents.push(...page);if(page.length<200)return documents;after=page.at(-1).name;
    }
  }
  if(verify){
    const transaction=(await api.post(`${base}:beginTransaction`,{options:{readOnly:{}}},quiet)).body.transaction;
    try{
      const recipes=await query('recipes',{transaction});
      const favorites=await query('favorites',{allDescendants:true,transaction});
      for(const post of recipes){
        const id=post.name.split('/').at(-1),data=unpack(post);
        const likes=favorites.filter(doc=>{
          const parts=doc.name.slice(root.length+1).split('/');
          return parts.length===4&&parts[0]==='users'&&parts[2]==='favorites'
            &&parts[3]===id&&unpack(doc).recipeId===id;
        }).length;
        const receipts=await query('shares',{transaction,parent:`/v1/${post.name}`});
        const shares=receipts.filter(doc=>unpack(doc).uid===doc.name.split('/').at(-1)).length;
        if(data.engagement?.likeCount!==likes||data.engagement?.shareCount!==shares)throw Error('Engagement does not match its sources');
      }
      console.log(JSON.stringify({verified:true,recipes:recipes.length}));return;
    }finally{await api.post(`${base}:rollback`,{transaction},quiet).catch(()=>{});}
  }
  const recipes=await query('recipes');
  const favorites=await query('favorites',{allDescendants:true});
  console.log(JSON.stringify({project:PROJECT,recipes:recipes.length,favorites:favorites.length,apply}));
  if(!apply)return;
  let updated=0;
  for(const listed of recipes){
    for(let attempt=0;attempt<5;attempt++){
      const transaction=(await api.post(`${base}:beginTransaction`,{},quiet)).body.transaction;
      let committed=false;
      try{
        const response=await api.post(`${base}:batchGet`,{documents:[listed.name],transaction},quiet);
        const post=response.body.find(row=>row.found)?.found;
        if(!post)break;
        const id=post.name.split('/').at(-1),data=unpack(post);
        // Nguồn và parent cùng transaction; write mới cập nhật parent sẽ buộc retry.
        const saved=await query('favorites',{allDescendants:true,transaction});
        const shares=await query('shares',{transaction,parent:`/v1/${post.name}`});
        const likeCount=saved.filter(doc=>{
          const parts=doc.name.slice(root.length+1).split('/');
          return parts.length===4&&parts[0]==='users'&&parts[2]==='favorites'
            &&parts[3]===id&&unpack(doc).recipeId===id;
        }).length;
        const shareCount=shares.filter(doc=>unpack(doc).uid===doc.name.split('/').at(-1)).length;
        const engagement={likeCount,shareCount};
        if(data.engagement?.likeCount===likeCount && data.engagement?.shareCount===shareCount
          && Object.keys(data.engagement).length===2)break;
        await api.post(`${base}:commit`,{transaction,writes:[{
          update:{name:post.name,fields:encode({engagement}).mapValue.fields},
          updateMask:{fieldPaths:['engagement']},
        }]},quiet);
        committed=true;updated++;break;
      }catch(error){
        if(attempt===4||(error.status!==409&&!String(error.message).includes('ABORTED')))throw error;
      }finally{
        if(!committed)await api.post(`${base}:rollback`,{transaction},quiet).catch(()=>{});
      }
    }
  }
  console.log(JSON.stringify({completed:true,recipesUpdated:updated}));
})().catch(error=>{console.error(error.message);process.exitCode=1;});
