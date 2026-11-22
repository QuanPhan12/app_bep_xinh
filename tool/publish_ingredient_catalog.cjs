const fs = require("node:fs");
const path = require("node:path");
const {
  loadCatalog,
  firestoreValue: encode,
} = require("./ingredient_catalog_data.cjs");

function cliLib() {
  for (const entry of process.env.PATH.split(path.delimiter)) {
    const lib = path.resolve(entry, "../firebase-tools/lib");
    if (
      fs.existsSync(path.join(lib, "requireAuth.js")) &&
      fs.existsSync(path.join(lib, "auth.js"))
    )
      return lib;
  }
  throw new Error(
    "Run with npm exec --package=firebase-tools@15.34.2 -- node tool/publish_ingredient_catalog.cjs",
  );
}
(async () => {
  const { data, summary, contentHash } = loadCatalog();
  console.log(
    JSON.stringify({ version: data.version, ...summary, contentHash }),
  );
  if (!process.argv.includes("--apply")) {
    console.log("Validated dry run. Add --apply to publish.");
    return;
  }
  const project = process.argv[process.argv.indexOf("--project") + 1];
  if (project !== "bepxinh-b0be7")
    throw new Error("Explicit --project bepxinh-b0be7 required");
  const lib = cliLib();
  const auth = require(path.join(lib, "auth"));
  const { requireAuth } = require(path.join(lib, "requireAuth"));
  const { Client } = require(path.join(lib, "apiv2"));
  const options = { project, nonInteractive: true };
  auth.setActiveAccount(options, auth.selectAccount(undefined, process.cwd()));
  await requireAuth(options);
  const api = new Client({
    urlPrefix: "https://firestore.googleapis.com",
    auth: true,
  });
  const base = `/v1/projects/${project}/databases/(default)/documents`;
  const target = `${base}/catalogs/ingredients`;
  const current = await api.get(target, { resolveOnHTTPError: true });
  if (![200, 404].includes(current.status))
    throw new Error(`Read failed: ${current.status}`);
  if (current.status === 200) {
    if (current.body.fields?.contentHash?.stringValue === contentHash) {
      console.log("Already published; no write needed.");
      return;
    }
    if (current.body.fields?.version?.stringValue === data.version)
      throw new Error(
        "Published version differs. Increment catalog version before publishing.",
      );
  }
  const fields = encode({ ...data, contentHash }).mapValue.fields;
  await api.post(`${base}:commit`, {
    writes: [
      {
        update: {
          name: `projects/${project}/databases/(default)/documents/catalogs/ingredients`,
          fields,
        },
        currentDocument:
          current.status === 200
            ? { updateTime: current.body.updateTime }
            : { exists: false },
        updateTransforms: [
          { fieldPath: "updatedAt", setToServerValue: "REQUEST_TIME" },
        ],
      },
    ],
  });
  const check = await api.get(target);
  if (check.body.fields.contentHash.stringValue !== contentHash)
    throw new Error("Readback hash mismatch");
  console.log(
    `Published and verified ${summary.ingredients} ingredients to ${project}/catalogs/ingredients`,
  );
})().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
