const {test}=require('node:test');const assert=require('node:assert/strict');
const {reviewDelta,buildUserReviewWrites}=require('./user_review_moderation_logic.cjs');
test('approve/hide cycles preserve exact sum and count',()=>{
  assert.deepEqual(reviewDelta({status:'pending',stars:4},null,'approve'),{status:'approved',sum:4,count:1});
  assert.deepEqual(reviewDelta({status:'approved',stars:4},{sum:9,count:2},'hide'),{status:'hidden',sum:5,count:1});
  assert.deepEqual(reviewDelta({status:'hidden',stars:4},{sum:5,count:1},'approve'),{status:'approved',sum:9,count:2});
});
test('reject repeated decision, broken aggregates, bad stars and identity',()=>{
  assert.throws(()=>reviewDelta({status:'approved',stars:4},{sum:4,count:1},'approve'));
  assert.throws(()=>reviewDelta({status:'approved',stars:4},{sum:0,count:0},'hide'));
  assert.throws(()=>reviewDelta({status:'pending',stars:6},null,'approve'));
  assert.throws(()=>buildUserReviewWrites({project:'demo',recipeId:'r_a',reviewerId:'a',review:{uid:'b',stars:4,status:'pending'},decision:'approve',operator:'iam:a',updateTime:'x'}));
});
test('writes bind revision, summary and immutable audit in one transaction',()=>{
  const writes=buildUserReviewWrites({project:'demo',recipeId:'r_a',reviewerId:'a',review:{uid:'a',stars:4,status:'pending'},decision:'approve',operator:'iam:a',updateTime:'revision'});
  assert.equal(writes.length,3);assert.equal(writes[0].currentDocument.updateTime,'revision');assert.equal(writes[1].update.fields.sum.integerValue,'4');assert.equal(writes[2].currentDocument.exists,false);
});
