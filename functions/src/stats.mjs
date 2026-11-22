const dayMs = 86400000;
export function aiStatsDays(now) {
  const today = Math.floor((now + 7 * 3600000) / dayMs) * dayMs - 7 * 3600000;
  return Array.from({ length: 7 }, (_, i) => {
    const start = today - (6 - i) * dayMs;
    return { date: new Date(start + 7 * 3600000).toISOString().slice(0, 10), start };
  });
}
export function summarizeAiStats(records, attemptsByDay, now) {
  const users = new Set();
  const days = aiStatsDays(now).map(day => ({ ...day, requests: 0, users: new Set(), completed: 0, failed: 0, processing: 0, interrupted: 0, attempts: attemptsByDay[day.date] ?? 0 }));
  for (const record of records) {
    // Bản cũ đã có leaseUntil: suy ra lần thử gần nhất, không đọc nội dung hội thoại.
    const attempted = record.attemptedAtMillis ?? record.leaseUntil - 60000;
    const day = days.find(d => attempted >= d.start && attempted < d.start + dayMs);
    if (!day || typeof record.uid !== 'string') continue;
    day.requests++; day.users.add(record.uid); users.add(record.uid);
    if (record.status === 'done') day.completed++;
    else if (record.status === 'failed') day.failed++;
    else if (record.status === 'processing' && record.leaseUntil > now) day.processing++;
    else day.interrupted++;
  }
  const daily = days.map(({ start: _, users, ...row }) => ({ ...row, users: users.size }));
  const totals = { requests: 0, users: users.size, completed: 0, failed: 0, processing: 0, interrupted: 0, attempts: 0 };
  for (const row of daily) for (const key of ['requests', 'completed', 'failed', 'processing', 'interrupted', 'attempts']) totals[key] += row[key];
  const finished = totals.completed + totals.failed + totals.interrupted;
  return { asOf: now, timezone: 'UTC+7', daily, totals: { ...totals, completionRate: finished ? Math.round(totals.completed / finished * 1000) / 10 : null } };
}
