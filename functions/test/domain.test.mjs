import test from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { defaults, validateConfig, publicConfig, encryptKey, decryptKey, validateTurn, selectRecipes, parseAnswer } from '../src/domain.mjs';
const valid = () => ({ ...defaults, enabled: true, apiKey: 'test-key-only-123456' });
test('Config accepts Gemini and compatible API; public response never contains ciphertext/key', () => {
  assert.equal(validateConfig(valid()).provider, 'gemini');
  assert.equal(validateConfig({ ...valid(), provider: 'openai-compatible', endpoint: 'https://provider.example/v1/', model: 'example-model' }).endpoint, 'https://provider.example/v1');
  const view = publicConfig({ ...defaults, keyCipher: { value: 'private' }, apiKey: 'hidden' });
  assert.equal(view.hasKey, true); assert.ok(!JSON.stringify(view).includes('private')); assert.ok(!('apiKey' in view));
});
test('Config rejects insecure endpoints, unknown fields, bad model/key and quota', () => {
  for (const endpoint of ['http://example.com/v1','https://user:pass@example.com/v1','https://example.com:8443/v1','https://example.com/v1?key=x']) assert.throws(() => validateConfig({ ...valid(), provider: 'openai-compatible', endpoint }));
  for (const patch of [{ model: '../models/x?key=x' }, { apiKey: 'too short' }, { dailyLimit: 101 }, { dailyLimit: 0 }, { provider: 'arbitrary' }, { hasKey: true }]) assert.throws(() => validateConfig({ ...valid(), ...patch }));
});
test('Changing destination requires a new key, while disabling can keep existing key', () => {
  const old = { ...defaults, keyCipher: { value: 'existing' } };
  assert.throws(() => validateConfig({ ...valid(), apiKey: '', provider: 'openai-compatible', endpoint: 'https://new.example/v1' }, old));
  assert.equal(validateConfig({ ...valid(), enabled: false, apiKey: '' }, old).enabled, false);
});
test('AES-GCM encrypts with unique IV and detects wrong key or tampering', () => {
  const master = randomBytes(32).toString('base64'), key = 'test-only-key-123456';
  const a = encryptKey(key, master), b = encryptKey(key, master);
  assert.notEqual(a.iv, b.iv); assert.equal(decryptKey(a, master), key); assert.ok(!JSON.stringify(a).includes(key));
  assert.throws(() => decryptKey(a, randomBytes(32).toString('base64')));
  assert.throws(() => decryptKey({ ...a, value: Buffer.from('tampered').toString('base64') }, master));
});
test('Turn only accepts bounded text and requestId, never client identity/history', () => {
  const value = { requestId: 'a'.repeat(32), message: '  Hôm nay ăn gì?  ' };
  assert.equal(validateTurn(value).message, 'Hôm nay ăn gì?');
  for (const patch of [{ uid: 'other' }, { history: [] }, { message: 'x'.repeat(2001) }, { message: ' ' }, { requestId: '../other' }]) assert.throws(() => validateTurn({ ...value, ...patch }));
});
const row = (id, status, title) => ({ id, status, content: { title, cover: { url: 'https://example.test/image' }, preparationMinutes: 5, cookingMinutes: 10, ingredients: [{ name: 'Trứng' }] } });
test('Retrieval only uses approved recipes and ranks matching Vietnamese ingredients', () => {
  const rows = [row('unrelated','approved','Cơm chiên'), row('hidden','hidden','Trứng'), row('match','approved','Trứng chiên')];
  const result = selectRecipes(rows, 'trung chien');
  assert.equal(result[0].id, 'match'); assert.ok(!result.some(r => r.id === 'hidden'));
});
test('Structured answer strips invented/duplicate recipe IDs and bounds result', () => {
  const candidates = [row('real','approved','Món thật')];
  const answer = parseAnswer('{"reply":"Gợi ý món thật","recipeIds":["invented","real","real"]}', candidates);
  assert.deepEqual(answer.recipes.map(r => r.id), ['real']);
  assert.throws(() => parseAnswer('not json', candidates));
  assert.throws(() => parseAnswer('{"reply":"","recipeIds":[]}', candidates));
});
