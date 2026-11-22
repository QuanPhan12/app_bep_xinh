import test from 'node:test';
import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { publicAddress, postJson, generate, providerFailure, listGeminiModels } from '../src/provider.mjs';
test('Private, metadata, loopback, mapped IPv6 and multicast addresses are rejected', () => {
  for (const ip of ['127.0.0.1','10.0.0.1','169.254.169.254','172.16.0.1','192.168.1.1','100.64.0.1','0.0.0.0','224.0.0.1','::1','fc00::1','fe80::1','::ffff:127.0.0.1']) assert.equal(publicAddress(ip), false, ip);
  for (const ip of ['8.8.8.8','1.1.1.1','2606:4700:4700::1111']) assert.equal(publicAddress(ip), true, ip);
});
test('DNS private/mixed destinations never reach HTTP transport', async () => {
  for (const addresses of [[{address:'127.0.0.1',family:4}],[{address:'8.8.8.8',family:4},{address:'10.0.0.1',family:4}]]) await assert.rejects(postJson('https://example.test/v1', {}, {}, { resolve: async () => addresses, transport: () => assert.fail('must not connect') }), e => e.code === 'private_endpoint');
});
function transport(statusCode, responseBody, inspect = () => {}) {
  return (url, options, callback) => {
    inspect(url, options);
    const request = new EventEmitter(); request.destroy = () => {};
    request.end = () => queueMicrotask(() => {
      const response = new EventEmitter(); response.statusCode = statusCode; response.destroy = () => {}; callback(response);
      response.emit('data', Buffer.from(responseBody)); response.emit('end');
    });
    return request;
  };
}
test('Real connection lookup is pinned to the validated DNS result', async () => {
  let pinned;
  const result = await postJson('https://example.test/v1', {authorization:'Bearer test-only'}, {}, {resolve: async () => [{address:'8.8.8.8',family:4}], transport: transport(200,'{"ok":true}', (url, options) => { assert.equal(url.search, ''); options.lookup('example.test', {}, (_, address) => { pinned = address; }); })});
  assert.equal(pinned, '8.8.8.8'); assert.equal(result.ok, true);
});
test('Redirect and provider error bodies cannot disclose API key or be followed', async () => {
  for (const status of [302,401,429,500]) await assert.rejects(postJson('https://example.test/v1', {}, {}, {resolve: async () => [{address:'8.8.8.8',family:4}], transport: transport(status, 'echo-private-key')}), e => !e.message.includes('echo-private-key') && e.code === 'provider_rejected');
});
test('Provider failures distinguish key, permission, model and quota without returning raw content', () => {
  for (const [status, reason, expected] of [[400,'API_KEY_INVALID','không hợp lệ'],[401,'ACCESS_TOKEN_TYPE_UNSUPPORTED','ACCESS_TOKEN_TYPE_UNSUPPORTED'],[403,'API_KEY_HTTP_REFERRER_BLOCKED','website'],[403,'API_KEY_IP_ADDRESS_BLOCKED','IP'],[403,'SERVICE_DISABLED','Generative Language API'],[403,'BILLING_DISABLED','billing'],[404,'','model'],[429,'','quota']]) {
    const error = providerFailure(status, JSON.stringify({error:{message:'secret-api-key and private chat',details:[{reason,metadata:{apiKey:'secret-api-key'}}]}}));
    assert.ok(error.message.includes(expected)); assert.ok(error.message.includes(String(status)));
    assert.ok(!error.message.includes('secret-api-key')); assert.ok(!error.message.includes('private chat'));
  }
  assert.ok(providerFailure(403, JSON.stringify({error:{message:'Your API key was reported as leaked. secret-value'}})).message.includes('Google đã chặn'));
  const legacy = providerFailure(404, JSON.stringify({error:{message:'This model models/gemini-2.5-flash-lite is no longer available to new users. secret-value'}}));
  assert.ok(legacy.message.includes('project đã từng sử dụng')); assert.ok(legacy.message.includes('gemini-3.5-flash-lite')); assert.ok(!legacy.message.includes('secret-value'));
  assert.ok(!providerFailure(400, '<html>secret-value</html>').message.includes('secret-value'));
});
test('Provider adapters send keys only in headers and request structured output', async () => {
  let captured;
  const call = async (url, headers, body) => { captured={url,headers,body}; return {candidates:[{content:{parts:[{text:'{"reply":"ok","recipeIds":[]}' }]}}]}; };
  await generate({provider:'gemini',model:'gemini-2.5-flash'}, 'private-test-key', 'system', [], 'question', [], call);
  assert.ok(!captured.url.includes('private-test-key')); assert.equal(captured.headers['x-goog-api-key'],'private-test-key'); assert.equal(captured.body.generationConfig.responseMimeType,'application/json');
  await generate({provider:'openai-compatible',endpoint:'https://example.test/v1',model:'example'}, 'private-test-key', 'system', [], 'question', [], async (url,headers,body) => { captured={url,headers,body}; return {choices:[{message:{content:'{"reply":"ok","recipeIds":[]}'}}]}; });
  assert.equal(captured.url,'https://example.test/v1/chat/completions'); assert.equal(captured.headers.authorization,'Bearer private-test-key'); assert.equal(captured.body.response_format.type,'json_object');
  assert.equal(captured.body.max_tokens,2048);
  await generate({provider:'openai-compatible',endpoint:'https://api.openai.com/v1',model:'example'}, 'private-test-key', 'system', [], 'question', [], async (_,__,body) => { assert.equal(body.max_completion_tokens,2048); assert.ok(!('max_tokens' in body)); assert.ok(!('temperature' in body)); return {choices:[{message:{content:'{"reply":"ok","recipeIds":[]}'}}]}; });
});
test('Gemini model discovery uses authenticated GET, pagination and only content models', async () => {
  let calls = 0;
  const models = await listGeminiModels('private-test-key', async (url, headers, body, options) => {
    assert.equal(options.method, 'GET'); assert.equal(body, null);
    assert.equal(headers['x-goog-api-key'], 'private-test-key');
    assert.ok(!url.includes('private-test-key'));
    if (++calls === 1) return {models:[{name:'models/gemini-available-flash',supportedGenerationMethods:['generateContent']},{name:'models/gemini-available-image',supportedGenerationMethods:['generateContent']},{name:'models/gemini-embedding',supportedGenerationMethods:['embedContent']}],nextPageToken:'second-page'};
    assert.equal(new URL(url).searchParams.get('pageToken'),'second-page');
    return {models:[{name:'models/gemini-available-pro',supportedGenerationMethods:['generateContent']}]};
  });
  assert.equal(calls, 2);
  assert.deepEqual(models.map(m => m.id),['gemini-available-flash','gemini-available-pro']);
  await postJson('https://example.test/models', {}, null, {method:'GET',resolve:async()=>[{address:'8.8.8.8',family:4}],transport:transport(200,'{}',(_,options)=>{assert.equal(options.method,'GET');assert.equal(options.headers['content-length'],0);})});
});
