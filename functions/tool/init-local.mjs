import { existsSync, writeFileSync } from 'node:fs';
import { randomBytes } from 'node:crypto';
const path = new URL('../.secret.local', import.meta.url);
if (!existsSync(path)) writeFileSync(path, `AI_CONFIG_ENCRYPTION_KEY=${randomBytes(32).toString('base64')}\n`, { mode: 0o600 });
console.log('Local encryption secret ready; no provider key stored by this script.');
