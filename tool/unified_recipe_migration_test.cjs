const assert = require("node:assert/strict");
const { encode, decode } = require("./firebase_cli_client.cjs");
const { unifyRecipe } = require("./unified_recipe_data.cjs");
const catalog = require("./ingredient_catalog_data.cjs").loadCatalog().data;
const author = {
  id: "test",
  name: "Test cook",
  handle: "bep_test",
  status: "active",
};
const content = {
  title: "Eggs",
  description: "",
  cover: {
    id: "cover",
    name: "test.jpg",
    url: "https://res.cloudinary.com/ddqouziau/image/upload/v1/test.jpg",
    publicId: "test",
  },
  preparationMinutes: 5,
  cookingMinutes: 10,
  servings: 2,
  difficulty: "easy",
  meals: [],
  categories: [],
  storageNotes: "",
  ingredientGroups: [{ id: "main", name: "Main" }],
  ingredients: [
    {
      id: "row",
      ingredientId: "egg",
      name: "Egg",
      amount: 1,
      unitId: "fruit",
      note: "",
      toTaste: false,
      groupId: "main",
    },
  ],
  steps: [
    {
      id: "step",
      title: "",
      instruction: "Cook eggs",
      minutes: null,
      tip: "",
      photo: null,
    },
  ],
  isBanner: true,
};
const legacy = {
  fields: encode({
    schemaVersion: 1,
    id: "r_test",
    authorId: "test",
    status: "published",
    content,
    contentHash: "a".repeat(64),
    catalogVersion: catalog.version,
    revisionOf: null,
  }).mapValue.fields,
};
legacy.fields.submittedAt = { timestampValue: "2026-11-09T00:00:00Z" };
const convert = (doc = legacy, current) =>
  decode({
    mapValue: {
      fields: unifyRecipe({
        id: "r_test",
        legacy: doc,
        current,
        author,
        catalog,
      }),
    },
  });
let result = convert();
assert.equal(result.status, "approved");
assert.equal(result.schemaVersion, 2);
assert.equal(result.isBanner, false);
assert.equal(result.content.isBanner, undefined);
assert.equal(result.submittedAt, "2026-11-09T00:00:00Z");
assert.deepEqual(result.author, {
  id: author.id,
  name: author.name,
  handle: author.handle,
});
const rejected = structuredClone(legacy);
rejected.fields.status = { stringValue: "rejected" };
assert.equal(convert(rejected).status, "rejected");
const missingDate = structuredClone(legacy);
delete missingDate.fields.submittedAt;
assert.throws(() => convert(missingDate));
const bad = structuredClone(legacy);
bad.fields.content.mapValue.fields.cover.mapValue.fields.url = {
  stringValue: "https://invalid.example/photo.jpg",
};
assert.throws(() => convert(bad));
const current = {
  fields: encode({ ...result, isBanner: true }).mapValue.fields,
};
current.fields.submittedAt = legacy.fields.submittedAt;
assert.equal(convert(legacy, current).isBanner, true);
console.log(
  "PASS: unified recipe migration preserves content/status/timestamps and protects admin banner selection",
);
