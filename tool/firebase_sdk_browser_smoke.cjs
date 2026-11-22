const { spawn } = require("node:child_process");
const path = require("node:path");
const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

(async () => {
  // Serve duy nhất artifact demo, không tái sử dụng profile Chrome của người dùng.
  const publishing = process.argv.includes("--publishing");
  const communications = process.argv.includes("--communications");
  const accountAccess = process.argv.includes('--account-access');
  const server = spawn(
    "python",
    [
      "-m",
      "http.server",
      "11300",
      "--bind",
      "127.0.0.1",
      "--directory",
      accountAccess ? 'build/account-access-smoke-web' : communications ? "build/communication-smoke-web" : publishing
        ? "build/recipe-publishing-smoke-web"
        : "build/firebase-smoke-web",
    ],
    { windowsHide: true, stdio: "ignore" },
  );
  const chrome = spawn(
    process.env.CHROME_EXECUTABLE ||
      "C:/Program Files/Google/Chrome/Application/chrome.exe",
    [
      "--headless",
      "--no-sandbox",
      "--no-first-run",
      "--disable-extensions",
      "--remote-debugging-port=11302",
      `--user-data-dir=${path.resolve("build/firebase-sdk-browser-" + Date.now())}`,
      "about:blank",
    ],
    { windowsHide: true, stdio: "ignore" },
  );
  let ws;
  try {
    let pages;
    for (let attempt = 0; attempt < 30; attempt++) {
      try {
        pages = await (await fetch("http://127.0.0.1:11302/json/list")).json();
        break;
      } catch {
        await delay(500);
      }
    }
    if (!pages) throw new Error("Cannot start headless Chrome");
    ws = new WebSocket(
      (
        pages.find(
          (page) => page.type === "page" && page.url === "about:blank",
        ) || pages.find((page) => page.type === "page")
      ).webSocketDebuggerUrl,
    );
    await new Promise((resolve) =>
      ws.addEventListener("open", resolve, { once: true }),
    );
    let sequence = 0;
    const pending = new Map();
    ws.addEventListener("message", (event) => {
      const message = JSON.parse(event.data);
      if (
        message.method === "Network.responseReceived" &&
        message.params.response.status >= 400 &&
        message.params.response.url.includes(":9099/")
      ) {
        call("Network.getResponseBody", {
          requestId: message.params.requestId,
        }).then((response) => {
          try {
            const body = JSON.parse(response.body);
            console.error("Auth emulator error: " + body.error?.message);
          } catch {}
        });
      }
      if (pending.has(message.id)) {
        pending.get(message.id)(message.result);
        pending.delete(message.id);
      }
    });
    const call = (method, params = {}) =>
      new Promise((resolve) => {
        const id = ++sequence;
        pending.set(id, resolve);
        ws.send(JSON.stringify({ id, method, params }));
      });
    await call("Runtime.enable");
    await call("Network.enable");
    await call("Network.setBypassServiceWorker", { bypass: true });
    await call("Network.setCacheDisabled", { cacheDisabled: true });
    await call("Network.setBlockedURLs", {
      urls: [
        "https://identitytoolkit.googleapis.com/*",
        "https://securetoken.googleapis.com/*",
      ],
    });
    await call("Page.addScriptToEvaluateOnNewDocument", {
      source:
        "sessionStorage.setItem('[DEFAULT]-firebaseEmulatorOrigin','http://127.0.0.1:9099');",
    });
    await call("Runtime.evaluate", {
      expression: "globalThis.firebaseSmokeResult = undefined",
    });
    await call("Page.navigate", { url: "http://127.0.0.1:11300/" });
    let reviewed = false;
    const liveActions = new Set();
    for (let attempt = 0; attempt < 120; attempt++) {
      const result = await call("Runtime.evaluate", {
        expression: "globalThis.firebaseSmokeResult",
        returnByValue: true,
      });
      const status = result?.result?.value;
      if (accountAccess && typeof status === 'string' && /^(ACCOUNT_LOCK|ACCOUNT_UNLOCK):/.test(status) && !liveActions.has(status)) {
        if (process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080') throw new Error('Loopback emulator required');
        const [action, uid] = status.split(':');
        if (!/^[a-zA-Z0-9]+$/.test(uid)) throw new Error('Unexpected test UID');
        const {encode} = require('./firebase_cli_client.cjs');
        const locked = action === 'ACCOUNT_LOCK';
        const prefix = 'projects/demo-bepxinh/databases/(default)/documents';
        const response = await fetch(`http://127.0.0.1:8080/v1/${prefix}:commit`, {
          method:'POST', headers:{'Content-Type':'application/json',Authorization:'Bearer owner'},
          body:JSON.stringify({writes:[{
            update:{name:`${prefix}/users/${uid}`,fields:encode({status:locked ? 'locked' : 'active',lockReason:locked ? 'SDK lock test' : null,...(!locked ? {lockedAt:null} : {})}).mapValue.fields},
            updateMask:{fieldPaths:['status','lockReason',...(!locked ? ['lockedAt'] : [])]},
            updateTransforms:['updatedAt',...(locked ? ['lockedAt'] : [])].map(fieldPath => ({fieldPath,setToServerValue:'REQUEST_TIME'})),
          }]}),
        });
        if (!response.ok) throw new Error('Cannot update emulator lock state');
        liveActions.add(status);
      }
      if (communications && typeof status === 'string' && status.startsWith('COMMUNICATION_SEED:')) {
        if (process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080') throw new Error('Loopback emulator required');
        const [alice,bob] = JSON.parse(status.substring('COMMUNICATION_SEED:'.length));
        const {encode} = require('./firebase_cli_client.cjs');
        const prefix = 'projects/demo-bepxinh/databases/(default)/documents';
        const response = await fetch(`http://127.0.0.1:8080/v1/${prefix}:commit`, {
          method:'POST', headers:{'Content-Type':'application/json',Authorization:'Bearer owner'},
          body:JSON.stringify({writes:[['alice',alice,'Alice'],['bob',bob,'Bob']].map(([label,uid,name]) => ({
            update:{name:`${prefix}/recipes/communication_${label}_recipe`, fields:encode({
              id:`communication_${label}_recipe`,status:'approved',authorId:uid,
              author:{id:uid,name,handle:`bep_${uid}`},content:{title:'Món thử nghiệm'},
            }).mapValue.fields}, updateTransforms:['submittedAt','reviewedAt'].map(fieldPath => ({fieldPath,setToServerValue:'REQUEST_TIME'})),
          }))}),
        });
        if (!response.ok) throw new Error('Cannot seed emulator communication recipes');
        await call('Runtime.evaluate',{expression:"globalThis.firebaseSmokeResult = 'COMMUNICATION_SEEDED'"});
      }
      if (
        publishing &&
        typeof status === "string" &&
        /^(MANUAL_APPROVE|LIVE_BANNER_ON|LIVE_BANNER_OFF|LIVE_RECIPE_REMOVE):r_/.test(
          status,
        ) &&
        !liveActions.has(status)
      ) {
        const [action, id] = status.split(":");
        await require("./review_recipe_in_emulator.cjs").updateRecipeInEmulator(
          id,
          action,
        );
        liveActions.add(status);
      }
      if (
        publishing &&
        !reviewed &&
        typeof status === "string" &&
        status.startsWith("REVIEW:")
      ) {
        await require("./review_recipe_in_emulator.cjs").reviewInEmulator(
          status.substring(7),
        );
        reviewed = true;
      }
      if (typeof status === "string" && status.startsWith("PASS:")) {
        console.log(status);
        return;
      }
      if (typeof status === "string" && status.startsWith("FAIL:"))
        throw new Error(status);
      await delay(1000);
    }
    throw new Error("Firebase SDK browser smoke timed out");
  } finally {
    if (ws?.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ id: 9999, method: "Browser.close" }));
      ws.close();
    }
    chrome.kill();
    server.kill();
  }
})().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
