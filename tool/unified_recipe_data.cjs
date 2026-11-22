const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const { encode, decode } = require("./firebase_cli_client.cjs");
const { validateRecipeContent } = require("./recipe_content_validation.cjs");

function unifyRecipe({ id, current, legacy, author, catalog }) {
  const source = current || legacy;
  assert.ok(source, "Recipe source required");
  const read = (doc) =>
    doc ? decode({ mapValue: { fields: doc.fields } }) : null;
  const existing = read(current),
    previous = read(legacy);
  const data = existing || previous;
  const envelope = data.content ? data : previous;
  assert.ok(envelope, "Legacy public recipe needs its original submission");
  assert.equal(data.authorId, author.id);
  assert.equal(envelope.authorId, author.id);
  const status = data.status === "published" ? "approved" : data.status;
  assert.ok(
    ["pending", "approved", "rejected"].includes(status),
    "Unsupported recipe status",
  );
  let content = data.content;
  if (!content) {
    const keys = [
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
    ];
    content = Object.fromEntries(keys.map((key) => [key, data[key]]));
  }
  content = { ...content };
  // Cờ từ form cũ không được biến thành quyết định banner của admin.
  delete content.isBanner;
  if (status === "approved") {
    assert.equal(author.status ?? "active", "active");
    validateRecipeContent(content, catalog);
  }
  const fields = encode({
    schemaVersion: 2,
    id,
    authorId: author.id,
    author: { id: author.id, name: author.name, handle: author.handle },
    status,
    isBanner: typeof data.isBanner === "boolean" ? data.isBanner : false,
    revisionOf: envelope.revisionOf ?? null,
    content,
    contentHash:
      envelope.contentHash ||
      crypto.createHash("sha256").update(JSON.stringify(content)).digest("hex"),
    catalogVersion: envelope.catalogVersion || catalog.version,
    reviewedAt: null,
    reviewedBy: envelope.reviewedBy ?? null,
    reviewReason: envelope.reviewReason ?? null,
  }).mapValue.fields;
  const date =
    current?.fields.submittedAt ||
    legacy?.fields.submittedAt ||
    current?.fields.publishedAt;
  assert.ok(date?.timestampValue, "Recipe needs a valid submittedAt timestamp");
  fields.submittedAt = date;
  const reviewedAt = current?.fields.reviewedAt || legacy?.fields.reviewedAt;
  if (reviewedAt?.timestampValue) fields.reviewedAt = reviewedAt;
  return fields;
}
module.exports = { unifyRecipe };
