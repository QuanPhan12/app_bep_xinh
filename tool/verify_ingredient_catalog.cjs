const assert = require("node:assert/strict");
const { loadCatalog } = require("./ingredient_catalog_data.cjs");
function decode(value) {
  if ("stringValue" in value) return value.stringValue;
  if ("integerValue" in value) return Number(value.integerValue);
  if ("arrayValue" in value) return (value.arrayValue.values || []).map(decode);
  if ("mapValue" in value)
    return Object.fromEntries(
      Object.entries(value.mapValue.fields || {}).map(([k, v]) => [
        k,
        decode(v),
      ]),
    );
  throw new Error("Unsupported catalog field type");
}
(async () => {
  const { data, summary, contentHash } = loadCatalog();
  const response = await fetch(
    "https://firestore.googleapis.com/v1/projects/bepxinh-b0be7/databases/(default)/documents/catalogs/ingredients",
  );
  assert.equal(response.status, 200, "Public catalog read must succeed");
  const remote = await response.json();
  const fields = remote.fields;
  assert.equal(fields.contentHash.stringValue, contentHash);
  const document = Object.fromEntries(
    Object.keys(data).map((key) => [key, decode(fields[key])]),
  );
  assert.deepEqual(
    document,
    data,
    "Published catalog differs from validated source",
  );
  console.log(
    JSON.stringify({
      project: "bepxinh-b0be7",
      version: data.version,
      ...summary,
      publicRead: true,
      sourceMatches: true,
    }),
  );
})().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
