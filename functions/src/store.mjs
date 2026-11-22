import { createHash, randomUUID } from 'node:crypto';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { AiError, defaults, publicConfig, validateConfig, encryptKey, decryptKey, selectRecipes, parseAnswer, systemGuide } from './domain.mjs';
import { generate, listGeminiModels } from './provider.mjs';
import { aiStatsDays, summarizeAiStats } from './stats.mjs';

export function createBackend(db, { master = () => process.env.AI_CONFIG_ENCRYPTION_KEY, provider = generate, modelProvider = listGeminiModels, now = Date.now } = {}) {
  const configRef = db.doc('_ai_private/config');
  async function account(uid, admin = false) {
    const snapshot = await db.doc(`users/${uid}`).get(), value = snapshot.data();
    if (!value || value.id !== uid || (value.status ?? 'active') !== 'active' || (admin && value.role !== 'admin')) throw new AiError(403, 'forbidden', admin ? 'Chỉ quản trị viên đang hoạt động được cấu hình AI.' : 'Tài khoản chưa được phép sử dụng trợ lý.');
    return value;
  }
  const config = async () => (await configRef.get()).data() ?? defaults;
  async function adminConfig(uid) { await account(uid, true); return publicConfig(await config()); }
  async function adminStats(uid) {
    await account(uid, true);
    const time = now(), days = aiStatsDays(time);
    const [records, quotas, settings] = await Promise.all([
      db.collection('_ai_requests').where('expiresAt', '>=', Timestamp.fromMillis(days[0].start + 7 * 86400000)).where('expiresAt', '<=', Timestamp.fromMillis(time + 7 * 86400000)).orderBy('expiresAt').limit(3501).select('uid', 'status', 'leaseUntil', 'attemptedAtMillis').get(),
      db.getAll(...days.map(d => db.doc(`_ai_limits/project_${d.date}`))),
      config(),
    ]);
    await account(uid, true);
    const attempts = Object.fromEntries(quotas.map((doc, i) => [days[i].date, doc.data()?.count ?? 0]));
    return { ...summarizeAiStats(records.docs.slice(0, 3500).map(d => d.data()), attempts, time), truncated: records.size > 3500, settings: { enabled: settings.enabled, provider: settings.provider, model: settings.model } };
  }
  async function adminRateLimit(uid) {
    const minute = Math.floor(now() / 60000), limitRef = db.doc(`_ai_admin_limits/${uid}_${minute}`);
    await db.runTransaction(async tx => {
      const n = (await tx.get(limitRef)).data()?.count ?? 0;
      if (n >= 5) throw new AiError(429, 'admin_rate_limit', 'Tối đa 5 lần kiểm tra cấu hình hoặc lấy model mỗi phút.');
      tx.set(limitRef, { count: n + 1, expiresAt: Timestamp.fromMillis(now() + 86400000) });
    });
  }
  async function adminModels(uid, input) {
    await account(uid, true);
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).some(k => k !== 'apiKey')) throw new AiError(400, 'invalid_config', 'Chỉ gửi API key để lấy danh sách model.');
    const current = await config();
    const value = validateConfig({ ...defaults, apiKey: input.apiKey ?? '' });
    const key = value.apiKey || (current.provider === 'gemini' && current.keyCipher ? decryptKey(current.keyCipher, master()) : '');
    if (!key) throw new AiError(400, 'key_required', 'Nhập Gemini API key trước khi lấy danh sách model.');
    await adminRateLimit(uid);
    const models = await modelProvider(key);
    await account(uid, true);
    return { models };
  }
  async function saveConfig(uid, input) {
    await account(uid, true);
    const current = await config(), value = validateConfig(input, current);
    if (value.version !== current.version) throw new AiError(409, 'config_changed', 'Cấu hình đã thay đổi. Tải lại trước khi lưu.');
    await adminRateLimit(uid);
    let cipher = current.keyCipher;
    if (value.enabled || value.apiKey) {
      const key = value.apiKey || decryptKey(cipher, master());
      parseAnswer(await provider(value, key, systemGuide, [], 'Kiểm tra kết nối. Trả lời JSON với reply là Kết nối thành công và recipeIds là mảng rỗng.', []), []);
      if (value.apiKey) cipher = encryptKey(value.apiKey, master());
    }
    await account(uid, true);
    const saved = { provider: value.provider, endpoint: value.endpoint, model: value.model, enabled: value.enabled, dailyLimit: value.dailyLimit, version: current.version + 1, updatedBy: uid, updatedAt: FieldValue.serverTimestamp(), ...(cipher ? { keyCipher: cipher } : {}) };
    await db.runTransaction(async tx => {
      const latest = (await tx.get(configRef)).data() ?? defaults;
      const actor = (await tx.get(db.doc(`users/${uid}`))).data();
      if (latest.version !== current.version) throw new AiError(409, 'config_changed', 'Cấu hình đã thay đổi trong lúc kiểm tra. Tải lại trước khi lưu.');
      if (!actor || actor.role !== 'admin' || (actor.status ?? 'active') !== 'active') throw new AiError(403, 'forbidden', 'Quyền quản trị đã thay đổi.');
      tx.set(configRef, saved);
    });
    return publicConfig(saved);
  }
  async function history(uid) {
    await account(uid);
    const result = await db.collection(`_ai_threads/${uid}/messages`).orderBy('createdAtMillis', 'desc').limit(40).get();
    return result.docs.map(d => ({ id: d.id, ...d.data() })).reverse();
  }
  async function chat(uid, { requestId, message }) {
    await account(uid);
    const settings = await config();
    if (!settings.enabled || !settings.keyCipher) throw new AiError(503, 'ai_disabled', 'Trợ lý AI đang được chuẩn bị. Vui lòng quay lại sau.');
    const digest = createHash('sha256').update(message).digest('hex'), lease = randomUUID(), time = now();
    const day = new Date(time + 7 * 3600000).toISOString().slice(0, 10), minute = Math.floor(time / 60000);
    const requestRef = db.doc(`_ai_requests/${uid}_${requestId}`), quotaRef = db.doc(`_ai_limits/${uid}_${day}`), globalRef = db.doc(`_ai_limits/project_${day}`);
    const cached = await db.runTransaction(async tx => {
      const request = (await tx.get(requestRef)).data(), quota = (await tx.get(quotaRef)).data() ?? {}, global = (await tx.get(globalRef)).data() ?? {};
      if (request && request.digest !== digest) throw new AiError(409, 'request_changed', 'Mã yêu cầu đã được dùng cho nội dung khác.');
      if (request?.status === 'done') return request.response;
      if (request?.status === 'processing' && request.leaseUntil > time) throw new AiError(409, 'processing', 'AI vẫn đang trả lời. Vui lòng thử lại sau ít giây.');
      if (quota.activeUntil > time && quota.activeRequest !== requestId) throw new AiError(409, 'processing', 'Vui lòng chờ câu trả lời hiện tại.');
      const minuteCount = quota.minute === minute ? quota.minuteCount ?? 0 : 0;
      const projectMinuteCount = global.minute === minute ? global.minuteCount ?? 0 : 0;
      if ((global.count ?? 0) >= 500 || projectMinuteCount >= 30) throw new AiError(429, 'project_quota', 'Trợ lý đã đạt giới hạn lượt dùng chung. Vui lòng quay lại sau.');
      if ((quota.count ?? 0) >= settings.dailyLimit || minuteCount >= 5) throw new AiError(429, 'quota', 'Đã đạt giới hạn hỏi AI. Vui lòng thử lại sau.');
      tx.set(quotaRef, { count: (quota.count ?? 0) + 1, minute, minuteCount: minuteCount + 1, activeRequest: requestId, activeUntil: time + 60000, expiresAt: Timestamp.fromMillis(time + 7 * 86400000) });
      tx.set(globalRef, { count: (global.count ?? 0) + 1, minute, minuteCount: projectMinuteCount + 1, expiresAt: Timestamp.fromMillis(time + 7 * 86400000) });
      tx.set(requestRef, { uid, digest, status: 'processing', lease, leaseUntil: time + 60000, attemptedAtMillis: time, expiresAt: Timestamp.fromMillis(time + 7 * 86400000) });
      return null;
    });
    if (cached) return cached;
    try {
      const [past, records] = await Promise.all([history(uid), db.collection('recipes').where('status', '==', 'approved').orderBy('submittedAt', 'desc').limit(100).select('status', 'content.title', 'content.cover', 'content.ingredients', 'content.preparationMinutes', 'content.cookingMinutes', 'content.categories', 'content.difficulty').get()]);
      const candidates = selectRecipes(records.docs.map(d => ({ ...d.data(), id: d.id })), message);
      const apiKey = decryptKey(settings.keyCipher, master());
      const raw = await provider(settings, apiKey, systemGuide, past.slice(-8).map(m => ({ role: m.role, text: m.text.slice(0, 3000) })), message, candidates);
      if (typeof raw === 'string' && raw.includes(apiKey)) throw new AiError(502, 'provider_unsafe', 'API trả nội dung không phù hợp. Vui lòng liên hệ quản trị viên.');
      const answer = parseAnswer(raw, candidates);
      // Kiểm tra lại trạng thái món sau khi model trả lời, tránh đề xuất món vừa bị ẩn.
      const currentRecipes = await Promise.all(answer.recipes.map(r => db.doc(`recipes/${r.id}`).get()));
      answer.recipes = currentRecipes.filter(d => d.exists && d.data().status === 'approved').map(d => ({ id: d.id, title: d.data().content.title, cover: d.data().content.cover }));
      const completed = now();
      const response = { user: { id: `${requestId}_u`, role: 'user', text: message, recipes: [], createdAtMillis: completed }, assistant: { id: `${requestId}_a`, role: 'assistant', ...answer, createdAtMillis: completed + 1 } };
      await db.runTransaction(async tx => {
        const request = (await tx.get(requestRef)).data(), actor = (await tx.get(db.doc(`users/${uid}`))).data();
        if (request?.lease !== lease) throw new AiError(409, 'request_expired', 'Yêu cầu đã hết thời gian. Hãy thử lại.');
        if (!actor || actor.id !== uid || (actor.status ?? 'active') !== 'active') throw new AiError(403, 'forbidden', 'Trạng thái tài khoản đã thay đổi.');
        tx.set(db.doc(`_ai_threads/${uid}/messages/${response.user.id}`), response.user);
        tx.set(db.doc(`_ai_threads/${uid}/messages/${response.assistant.id}`), response.assistant);
        tx.update(requestRef, { status: 'done', response, leaseUntil: 0 });
        tx.update(quotaRef, { activeUntil: 0 });
      });
      return response;
    } catch (error) {
      await db.runTransaction(async tx => {
        const request = (await tx.get(requestRef)).data();
        if (request?.lease === lease && request.status === 'processing') {
          tx.update(requestRef, { status: 'failed', leaseUntil: 0 });
          tx.update(quotaRef, { activeUntil: 0 });
        }
      }).catch(() => {});
      throw error;
    }
  }
  return { account, adminConfig, adminModels, adminStats, saveConfig, history, chat };
}
