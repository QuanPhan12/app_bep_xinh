const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { firebaseClient } = require('./firebase_cli_client.cjs');

const PROJECT = 'bepxinh-b0be7';
const SITE = 'bepxinh-b0be7';
const URL_PATH = '/.well-known/assetlinks.json';
const ROOT = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(ROOT, 'web', URL_PATH), 'utf8');
const statements = JSON.parse(source);
assert.equal(statements.length, 1);
assert.deepEqual(statements[0].relation, ['delegate_permission/common.handle_all_urls']);
assert.equal(statements[0].target.namespace, 'android_app');
assert.equal(statements[0].target.package_name, 'com.example.app_bep_xinh');
assert.ok(statements[0].target.sha256_cert_fingerprints.length > 0);
for (const fingerprint of statements[0].target.sha256_cert_fingerprints) {
  assert.match(fingerprint, /^(?:[0-9A-F]{2}:){31}[0-9A-F]{2}$/);
}

async function verifyPublic() {
  const response = await fetch(`https://${SITE}.web.app${URL_PATH}`, {
    redirect: 'manual',
    signal: AbortSignal.timeout(30000),
  });
  assert.equal(response.status, 200, 'Association must return HTTP 200 without redirect');
  assert.match(response.headers.get('content-type') || '', /application\/json/i);
  assert.deepEqual(await response.json(), statements);
  console.log('PASS: public Android association matches the workspace');
}

async function listFiles(api, version) {
  const files = new Map();
  let pageToken;
  do {
    const response = await api.get(`/${version}/files`, {
      queryParams: { pageSize: 1000, ...(pageToken ? { pageToken } : {}) },
    });
    for (const file of response.body.files || []) files.set(file.path, file.hash);
    pageToken = response.body.nextPageToken;
  } while (pageToken);
  return files;
}

(async () => {
  const args = process.argv.slice(2);
  assert.ok(args.every(arg => ['--apply', '--verify'].includes(arg)), 'Use --apply or --verify');
  assert.ok(args.length <= 1, 'Choose one mode');
  if (args.includes('--verify')) return verifyPublic();

  // Chỉ dùng phiên Firebase CLI đã đăng nhập; không đọc hoặc in token/secret.
  await firebaseClient(PROJECT);
  const lib = process.env.PATH.split(path.delimiter)
    .map(entry => path.resolve(entry, '../firebase-tools/lib'))
    .find(candidate => fs.existsSync(path.join(candidate, 'requireAuth.js')));
  assert.ok(lib, 'Run through the pinned firebase-tools npm exec command');
  const { Client } = require(path.join(lib, 'apiv2'));
  const hosting = require(path.join(lib, 'hosting/api'));
  const { Uploader } = require(path.join(lib, 'deploy/hosting/uploader'));
  const api = new Client({
    urlPrefix: 'https://firebasehosting.googleapis.com',
    apiVersion: 'v1beta1',
    auth: true,
  });
  const live = await hosting.getChannel(PROJECT, SITE, 'live');
  const previous = live?.release?.version?.name;
  assert.ok(previous?.includes(`sites/${SITE}/versions/`), 'Expected a live app release');
  const current = (await api.get(`/${previous}`)).body;
  const originalFiles = await listFiles(api, previous);
  assert.ok(originalFiles.has('/index.html') && originalFiles.has('/main.dart.js'));
  console.log(JSON.stringify({ site: SITE, sourceVersion: previous,
    filesRetained: originalFiles.size, path: URL_PATH, apply: args.includes('--apply') }));
  if (!args.includes('--apply')) return;

  // Sao chép bản đang live, thêm đúng file xác minh để không phát hành nhầm artifact local.
  const cloned = await hosting.cloneVersion(PROJECT, SITE, previous, false);
  const version = cloned.name;
  assert.ok(version?.includes(`sites/${SITE}/versions/`));
  const clonedConfig = (await api.get(`/${version}`)).body.config;
  assert.deepEqual(clonedConfig, current.config, 'Cloned serving config must match live');
  await new Uploader({ version, projectRoot: ROOT, public: path.join(ROOT, 'web'),
    files: [URL_PATH.slice(1)] }).start();

  const files = await listFiles(api, version);
  assert.ok(files.has(URL_PATH));
  assert.equal(files.size, originalFiles.size + (originalFiles.has(URL_PATH) ? 0 : 1));
  for (const [file, hash] of originalFiles) {
    if (file !== URL_PATH) assert.equal(files.get(file), hash, `Unexpected change: ${file}`);
  }
  const config = {
    ...current.config,
    headers: [
      ...(current.config?.headers || []).filter(header => header.glob !== URL_PATH),
      { glob: URL_PATH, headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'public, max-age=300',
      } },
    ],
  };
  await api.patch(`/${version}`, { config, status: 'FINALIZED' }, {
    queryParams: { updateMask: 'config,status' },
  });
  // Dừng nếu có người vừa phát hành bản khác, tránh ghi đè release mới hơn.
  const latest = await hosting.getChannel(PROJECT, SITE, 'live');
  assert.equal(latest?.release?.version?.name, previous, 'Live changed; inspect and rerun');
  const released = await hosting.createRelease(PROJECT, SITE, 'live', version, {
    message: 'Add verified Android recipe App Links association',
  });
  console.log(JSON.stringify({ version, release: released.name, retainedHashesVerified: true }));
  await verifyPublic();
})().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});
