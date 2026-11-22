import test from 'node:test';
import assert from 'node:assert/strict';
import { aiStatsDays, summarizeAiStats } from '../src/stats.mjs';

test('AI stats use UTC+7, deduplicate users and distinguish active/expired requests', () => {
  const now = Date.UTC(2026, 10, 16, 17, 0, 30), days = aiStatsDays(now);
  assert.equal(days[6].date, '2026-11-17'); assert.equal(days[0].date, '2026-11-11');
  const records = [
    {uid:'a',status:'done',attemptedAtMillis:now-1000},
    {uid:'a',status:'failed',leaseUntil:now+59000},
    {uid:'b',status:'processing',leaseUntil:now+59000},
    {uid:'b',status:'processing',leaseUntil:now-1000},
    {uid:'outside',status:'done',attemptedAtMillis:days[0].start-1},
  ];
  const stats = summarizeAiStats(records, {'2026-11-17':5}, now);
  assert.equal(stats.daily.length,7); assert.equal(stats.totals.requests,4);
  assert.equal(stats.totals.users,2); assert.equal(stats.totals.completed,1);
  assert.equal(stats.totals.failed,1); assert.equal(stats.totals.processing,1);
  assert.equal(stats.totals.interrupted,1); assert.equal(stats.totals.attempts,5);
  assert.equal(stats.totals.completionRate,33.3);
  assert.ok(!JSON.stringify(stats).includes('outside'));
  assert.equal(summarizeAiStats([],{},now).totals.completionRate,null);
});
