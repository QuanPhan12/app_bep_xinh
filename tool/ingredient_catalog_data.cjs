const fs = require("node:fs");
const path = require("node:path");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const sourcePath = path.resolve(
  __dirname,
  "../data/catalogs/ingredients.v1.json",
);
const key = (text) =>
  text
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d")
    .toLowerCase()
    .trim();
function fields(value, expected, label) {
  assert.ok(
    value && typeof value === "object" && !Array.isArray(value),
    `${label}: object required`,
  );
  assert.deepEqual(
    Object.keys(value).sort(),
    [...expected].sort(),
    `${label}: unexpected/missing fields`,
  );
}
function text(value, label) {
  assert.ok(
    typeof value === "string" &&
      value.length > 0 &&
      value.length <= 120 &&
      value.trim() === value &&
      value.normalize("NFC") === value,
    `${label}: invalid text`,
  );
}
function ids(items, label) {
  assert.ok(
    Array.isArray(items) && items.length,
    `${label}: nonempty array required`,
  );
  const seen = new Set();
  for (const item of items) {
    assert.match(item.id, /^[a-z][a-z0-9_]*$/, `${label}: invalid ID`);
    assert.ok(!seen.has(item.id), `${label}: duplicate ${item.id}`);
    seen.add(item.id);
  }
  return seen;
}
function validateCatalog(data) {
  fields(
    data,
    [
      "schemaVersion",
      "version",
      "locale",
      "categories",
      "units",
      "ingredients",
    ],
    "catalog",
  );
  assert.equal(data.schemaVersion, 1);
  assert.equal(data.locale, "vi-VN");
  assert.match(data.version, /^\d{4}-\d{2}-\d{2}\.v\d+$/);
  const categories = ids(data.categories, "categories");
  const units = ids(data.units, "units");
  const ingredientIds = ids(data.ingredients, "ingredients");
  const orders = new Set();
  for (const item of data.categories) {
    fields(item, ["id", "name", "sortOrder"], item.id);
    text(item.name, item.id);
    assert.ok(
      Number.isInteger(item.sortOrder) &&
        item.sortOrder >= 0 &&
        !orders.has(item.sortOrder),
    );
    orders.add(item.sortOrder);
    assert.ok(
      data.ingredients.some((ingredient) => ingredient.categoryId === item.id),
      `Empty category ${item.id}`,
    );
  }
  for (const item of data.units) {
    fields(item, ["id", "label", "type"], item.id);
    text(item.label, item.id);
    assert.ok(["mass", "volume", "count", "kitchen"].includes(item.type));
  }
  const names = new Set();
  for (const item of data.ingredients) {
    fields(
      item,
      ["id", "name", "categoryId", "aliases", "unitIds", "defaultUnitId"],
      item.id,
    );
    text(item.name, item.id);
    const name = item.name.normalize("NFC").toLocaleLowerCase("vi");
    assert.ok(!names.has(name), `Duplicate name ${item.name}`);
    names.add(name);
    assert.ok(categories.has(item.categoryId), `Unknown category ${item.id}`);
    assert.ok(Array.isArray(item.aliases));
    item.aliases.forEach((alias) => text(alias, item.id));
    assert.equal(
      new Set(item.aliases.map(key)).size,
      item.aliases.length,
      `Duplicate aliases ${item.id}`,
    );
    assert.ok(Array.isArray(item.unitIds) && item.unitIds.length);
    assert.equal(new Set(item.unitIds).size, item.unitIds.length);
    item.unitIds.forEach((unit) =>
      assert.ok(units.has(unit), `Unknown unit ${item.id}`),
    );
    assert.ok(
      item.unitIds.includes(item.defaultUnitId),
      `Invalid default unit ${item.id}`,
    );
  }
  const legacy = JSON.parse(
    fs.readFileSync(
      path.resolve(__dirname, "../assets/mock/ingredients.json"),
      "utf8",
    ),
  );
  legacy.ingredients.forEach((item) => {
    assert.ok(ingredientIds.has(item.id), `Missing legacy ID ${item.id}`);
    const migrated = data.ingredients.find((i) => i.id === item.id);
    item.unitIds.forEach((unit) =>
      assert.ok(
        migrated.unitIds.includes(unit),
        `Missing legacy unit ${item.id}/${unit}`,
      ),
    );
  });
  const bytes = Buffer.byteLength(JSON.stringify(data));
  assert.ok(bytes < 750000, "Catalog too large for the single-document format");
  return {
    categories: data.categories.length,
    units: data.units.length,
    ingredients: data.ingredients.length,
    bytes,
  };
}
function loadCatalog() {
  const data = JSON.parse(fs.readFileSync(sourcePath, "utf8"));
  const summary = validateCatalog(data);
  const contentHash = crypto
    .createHash("sha256")
    .update(JSON.stringify(data))
    .digest("hex");
  return { data, summary, contentHash };
}
function firestoreValue(value) {
  if (typeof value === "string") return { stringValue: value };
  if (typeof value === "number") return { integerValue: String(value) };
  if (Array.isArray(value))
    return { arrayValue: { values: value.map(firestoreValue) } };
  return {
    mapValue: {
      fields: Object.fromEntries(
        Object.entries(value).map(([k, v]) => [k, firestoreValue(v)]),
      ),
    },
  };
}
module.exports = { loadCatalog, validateCatalog, firestoreValue };
if (require.main === module) {
  const { data, summary, contentHash } = loadCatalog();
  console.log(
    JSON.stringify({ version: data.version, ...summary, contentHash }, null, 2),
  );
}
