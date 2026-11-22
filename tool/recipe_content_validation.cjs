const assert = require("node:assert/strict");
function exact(value, keys) {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  assert.deepEqual(Object.keys(value).sort(), [...keys].sort());
}
function text(value, max, required = false) {
  assert.equal(typeof value, "string");
  assert.ok(value.length <= max && (!required || value.trim().length > 0));
}
function integer(value, min, max) {
  assert.ok(Number.isInteger(value) && value >= min && value <= max);
}
function unique(list) {
  assert.equal(new Set(list).size, list.length);
}
function image(value) {
  exact(value, ["id", "name", "url", "publicId"]);
  text(value.id, 128, true);
  text(value.name, 255);
  text(value.publicId, 500, true);
  const url = new URL(value.url);
  assert.equal(url.protocol, "https:");
  assert.equal(url.hostname, "res.cloudinary.com");
  assert.ok(url.pathname.startsWith("/ddqouziau/image/upload/"));
  assert.ok(!url.username && !url.password && !url.search && !url.hash);
  assert.ok(value.url.length <= 2048);
}
function validateRecipeContent(c, catalog) {
  exact(c, [
    ...(Object.hasOwn(c, "isBanner") ? ["isBanner"] : []),
    "title",
    "description",
    "cover",
    "preparationMinutes",
    "cookingMinutes",
    "servings",
    "difficulty",
    "meals",
    "categories",
    "storageNotes",
    "ingredientGroups",
    "ingredients",
    "steps",
  ]);
  if (Object.hasOwn(c, "isBanner")) assert.equal(typeof c.isBanner, "boolean");
  text(c.title, 80, true);
  text(c.description, 500);
  text(c.storageNotes, 500);
  image(c.cover);
  integer(c.preparationMinutes, 0, 240);
  integer(c.cookingMinutes, 1, 720);
  integer(c.servings, 1, 50);
  assert.ok(["easy", "medium", "hard"].includes(c.difficulty));
  for (const [list, allowed] of [
    [
      c.meals,
      ["breakfast", "lunch", "dinner", "snack", "gathering", "weekend"],
    ],
    [c.categories, ["eat_clean", "quick", "soup", "vegetarian"]],
  ]) {
    assert.ok(Array.isArray(list));
    unique(list);
    list.forEach((v) => assert.ok(allowed.includes(v)));
  }
  assert.ok(
    Array.isArray(c.ingredientGroups) &&
      c.ingredientGroups.length >= 1 &&
      c.ingredientGroups.length <= 8,
  );
  unique(c.ingredientGroups.map((g) => g.id));
  c.ingredientGroups.forEach((g) => {
    exact(g, ["id", "name"]);
    text(g.id, 128, true);
    text(g.name, 60, true);
  });
  assert.ok(
    Array.isArray(c.ingredients) &&
      c.ingredients.length >= 1 &&
      c.ingredients.length <= 30,
  );
  unique(c.ingredients.map((i) => i.id));
  unique(
    c.ingredients.map(
      (i) => i.ingredientId || `custom:${i.name.toLowerCase().trim()}`,
    ),
  );
  const units = new Set(catalog.units.map((u) => u.id));
  const known = new Map(catalog.ingredients.map((i) => [i.id, i]));
  for (const i of c.ingredients) {
    exact(i, [
      "id",
      "ingredientId",
      "name",
      "amount",
      "unitId",
      "note",
      "toTaste",
      "groupId",
    ]);
    text(i.id, 128, true);
    text(i.name, 80, true);
    text(i.note, 160);
    assert.equal(typeof i.toTaste, "boolean");
    assert.ok(c.ingredientGroups.some((g) => g.id === i.groupId));
    if (i.ingredientId !== null) assert.ok(known.has(i.ingredientId));
    if (i.toTaste) {
      assert.equal(i.amount, null);
      assert.equal(i.unitId, null);
    } else {
      assert.ok(
        Number.isFinite(i.amount) && i.amount > 0 && i.amount <= 100000,
      );
      assert.ok(units.has(i.unitId));
      if (i.ingredientId !== null)
        assert.ok(known.get(i.ingredientId).unitIds.includes(i.unitId));
    }
  }
  assert.ok(
    Array.isArray(c.steps) && c.steps.length >= 1 && c.steps.length <= 20,
  );
  unique(c.steps.map((s) => s.id));
  for (const s of c.steps) {
    exact(s, ["id", "title", "instruction", "minutes", "tip", "photo"]);
    text(s.id, 128, true);
    text(s.title, 80);
    text(s.instruction, 2000, true);
    text(s.tip, 500);
    if (s.minutes !== null) integer(s.minutes, 1, 720);
    if (s.photo !== null) image(s.photo);
  }
  assert.ok(Buffer.byteLength(JSON.stringify(c)) <= 400000);
  return c;
}
module.exports = { validateRecipeContent };
