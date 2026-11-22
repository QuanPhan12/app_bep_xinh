const assert=require('node:assert/strict');
const {encode}=require('./firebase_cli_client.cjs');
function reviewDelta(review,aggregate,decision){
  assert.ok(['pending','approved','hidden'].includes(review.status));
  assert.ok(Number.isInteger(review.stars)&&review.stars>=1&&review.stars<=5);
  assert.ok(['approve','hide'].includes(decision));
  const status=decision==='approve'?'approved':'hidden';
  assert.notEqual(status,review.status,'Review already has requested status');
  const old=review.status==='approved'?review.stars:0,next=status==='approved'?review.stars:0;
  const sum=(aggregate?.sum??0)+next-old,count=(aggregate?.count??0)+(next?1:0)-(old?1:0);
  assert.ok(Number.isInteger(sum)&&Number.isInteger(count)&&count>=0&&sum>=count&&sum<=count*5,'Invalid existing aggregate');
  return {status,sum,count};
}
function buildUserReviewWrites({project,recipeId,reviewerId,review,aggregate,decision,updateTime,operator}){
  assert.match(recipeId,/^[A-Za-z0-9_-]{1,128}$/);assert.match(reviewerId,/^[A-Za-z0-9_-]{1,128}$/);
  assert.equal(review.uid,reviewerId);assert.ok(updateTime);assert.ok(operator);
  const {status,sum,count}=reviewDelta(review,aggregate,decision);
  const base=`projects/${project}/databases/(default)/documents`;
  const stamp={fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'};
  return [
    {update:{name:`${base}/recipes/${recipeId}/user_reviews/${reviewerId}`,fields:encode({status}).mapValue.fields},updateMask:{fieldPaths:['status']},currentDocument:{updateTime},updateTransforms:[stamp]},
    {update:{name:`${base}/recipes/${recipeId}/ratings/summary`,fields:encode({sum,count,lastReviewerId:reviewerId}).mapValue.fields},updateTransforms:[stamp]},
    {update:{name:`${base}/user_review_moderation_events/${require('node:crypto').randomUUID()}`,fields:encode({recipeId,reviewerId,decision,operator}).mapValue.fields},currentDocument:{exists:false},updateTransforms:[{fieldPath:'createdAt',setToServerValue:'REQUEST_TIME'}]},
  ];
}
module.exports={reviewDelta,buildUserReviewWrites};
