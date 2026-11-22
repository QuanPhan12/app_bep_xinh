const fs = require("node:fs");
const path = require("node:path");
const assert = require("node:assert/strict");
const { firebaseClient, decode } = require("./firebase_cli_client.cjs");
const { unifyRecipe } = require("./unified_recipe_data.cjs");

(async () => {
  const option = (name) => {
    const i = process.argv.indexOf(name);
    return i < 0 ? undefined : process.argv[i + 1];
  };
  const project = option("--project");
  assert.equal(project, "bepxinh-b0be7", "Explicit project required");
  const { api } = await firebaseClient(project);
  const root = `projects/${project}/databases/(default)/documents`,
    base = `/v1/${root}`;
  const get = async (p) => (await api.get(`${base}/${p}`)).body;
  const list = async (collection) => {
    const result = await api.post(`${base}:runQuery`, {
      structuredQuery: { from: [{ collectionId: collection }] },
    });
    return result.body.filter((row) => row.document).map((row) => row.document);
  };
  const current = await list("recipes"),
    legacy = await list("recipe_submissions");
  const catalogDoc = await get("catalogs/ingredients");
  const catalog = decode({ mapValue: { fields: catalogDoc.fields } });
  const currentById = new Map(current.map((d) => [d.name.split("/").pop(), d]));
  const legacyById = new Map(legacy.map((d) => [d.name.split("/").pop(), d]));
  const plans = [];
  for (const id of new Set([...currentById.keys(), ...legacyById.keys()])) {
    const target = currentById.get(id),
      source = legacyById.get(id);
    if (target?.fields.schemaVersion?.integerValue === "2" && !source) continue;
    const record = decode({ mapValue: { fields: (target || source).fields } });
    const authorDoc = await get(`users/${encodeURIComponent(record.authorId)}`);
    const author = decode({ mapValue: { fields: authorDoc.fields } });
    const fields = unifyRecipe({
      id,
      current: target,
      legacy: source,
      author,
      catalog,
    });
    plans.push({ id, target, source, fields, authorDoc });
  }
  console.log(
    JSON.stringify({
      dryRun: !process.argv.includes("--apply"),
      recipes: plans.map((p) => ({
        id: p.id,
        status: p.fields.status.stringValue,
        isBanner: p.fields.isBanner.booleanValue,
      })),
    }),
  );
  if (!process.argv.includes("--apply") || !plans.length) return;
  const backupDir = path.resolve("build/firestore-migrations");
  fs.mkdirSync(backupDir, { recursive: true });
  const backup = path.join(backupDir, `recipes-${Date.now()}.json`);
  fs.writeFileSync(
    backup,
    JSON.stringify(
      {
        project,
        current,
        legacy,
        catalogDoc,
        authors: plans.map((p) => p.authorDoc),
      },
      null,
      2,
    ),
    { flag: "wx" },
  );
  console.log("Backup: " + backup);
  for (const plan of plans) {
    const writes = [
      {
        update: { name: `${root}/recipes/${plan.id}`, fields: plan.fields },
        currentDocument: plan.target
          ? { updateTime: plan.target.updateTime }
          : { exists: false },
      },
    ];
    if (plan.source)
      writes.push({
        delete: plan.source.name,
        currentDocument: { updateTime: plan.source.updateTime },
      });
    // Sao chép và xóa bản cũ cùng commit; precondition bảo vệ dữ liệu vừa đổi sau backup.
    await api.post(`${base}:commit`, { writes });
    const verified = await get(`recipes/${plan.id}`);
    assert.deepEqual(
      decode({ mapValue: { fields: verified.fields } }),
      decode({ mapValue: { fields: plan.fields } }),
    );
    console.log(`Migrated ${plan.id}`);
  }
  assert.equal(
    (await list("recipe_submissions")).length,
    0,
    "Legacy documents still exist; rerun migration",
  );
  console.log("PASS: unified recipes verified; legacy collection empty");
})().catch((e) => {
  console.error(e.message);
  process.exitCode = 1;
});
