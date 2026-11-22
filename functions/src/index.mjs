import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { AiError, validateTurn } from './domain.mjs';
import { createBackend } from './store.mjs';

initializeApp();
const master = defineSecret('AI_CONFIG_ENCRYPTION_KEY');
const backend = createBackend(getFirestore(), { master: () => master.value() });
const origins = new Set(['https://bepxinh-b0be7.web.app', 'https://bepxinh-b0be7.firebaseapp.com', 'https://bepxinh-admin.web.app', 'https://bepxinh-admin.firebaseapp.com']);
export const bepXinhAi = onRequest({ region: 'asia-southeast1', secrets: [master], timeoutSeconds: 60, memory: '256MiB', minInstances: 0, maxInstances: 3, concurrency: 20, invoker: 'public' }, async (req, res) => {
  res.set('Cache-Control', 'no-store'); res.set('X-Content-Type-Options', 'nosniff');
  const origin = req.get('origin');
  if (origin) {
    if (!origins.has(origin) && !(process.env.FUNCTIONS_EMULATOR === 'true' && /^http:\/\/(localhost|127\.0\.0\.1):\d+$/.test(origin))) return res.status(403).json({ error: { code: 'origin', message: 'Địa chỉ ứng dụng chưa được cho phép.' } });
    res.set('Access-Control-Allow-Origin', origin); res.set('Vary', 'Origin');
    res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type'); res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, OPTIONS');
  }
  if (req.method === 'OPTIONS') return res.status(204).send('');
  try {
    const token = req.get('authorization')?.match(/^Bearer (\S+)$/)?.[1];
    if (!token) throw new AiError(401, 'unauthenticated', 'Vui lòng đăng nhập để trò chuyện với AI.');
    let identity;
    try { identity = await getAuth().verifyIdToken(token, true); } catch { throw new AiError(401, 'unauthenticated', 'Phiên đăng nhập đã hết hạn.'); }
    if (req.rawBody?.length > 12000) throw new AiError(413, 'too_large', 'Yêu cầu quá lớn.');
    const path = req.path.replace(/\/$/, '');
    if (req.method === 'GET' && path === '/history') {
      return res.json(req.query.page === '1'
        ? await backend.historyPage(identity.uid, req.query.before)
        : { messages: await backend.history(identity.uid) });
    }
    if (req.method === 'POST' && path === '/chat') return res.json(await backend.chat(identity.uid, validateTurn(req.body)));
    if (req.method === 'GET' && path === '/admin/config') return res.json(await backend.adminConfig(identity.uid));
    if (req.method === 'GET' && path === '/admin/stats') return res.json(await backend.adminStats(identity.uid));
    if (req.method === 'POST' && path === '/admin/models') return res.json(await backend.adminModels(identity.uid, req.body));
    if (req.method === 'PUT' && path === '/admin/config') return res.json(await backend.saveConfig(identity.uid, req.body));
    return res.status(404).json({ error: { code: 'not_found', message: 'Không tìm thấy thao tác AI.' } });
  } catch (error) {
    // Không trả lỗi gốc của SDK/provider: có thể chứa header, key hoặc nội dung chat.
    const safe = error instanceof AiError ? error : new AiError(500, 'internal', 'Chưa hoàn tất yêu cầu AI. Vui lòng thử lại.');
    return res.status(safe.status).json({ error: { code: safe.code, message: safe.message } });
  }
});
