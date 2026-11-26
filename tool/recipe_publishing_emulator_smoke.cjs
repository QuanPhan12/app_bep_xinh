const assert = require("node:assert/strict");
const { encode, decode } = require("./firebase_cli_client.cjs");
const { loadCatalog } = require("./ingredient_catalog_data.cjs");
const { buildReviewWrites } = require("./recipe_review_logic.cjs");
const { validateRecipeContent } = require("./recipe_content_validation.cjs");
const project = "demo-bepxinh",
  db = `projects/${project}/databases/(default)`,
  root = `${db}/documents`;
const base = `http://127.0.0.1:8080/v1/${root}`;
let checks = 0;
async function request(url, body, token, expected = 200, method = "POST") {
  const res = await fetch(url, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  const json = await res.json();
  assert.equal(
    res.status,
    expected,
    `check ${checks}: ${method} ${new URL(url).pathname}: ${JSON.stringify(json.error || {})}`,
  );
  checks++;
  return json;
}
const stamp = (fieldPath) => ({ fieldPath, setToServerValue: "REQUEST_TIME" });
async function commit(writes, token, expected = 200) {
  return request(`${base}:commit`, { writes }, token, expected);
}
(async () => {
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, "127.0.0.1:8080");
  const signup = () =>
    request(
      "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo",
      {
        email: `recipe-${Date.now()}-${Math.random()}@example.test`,
        password: "emulator-only-123",
        returnSecureToken: true,
      },
    );
  const author = await signup(),
    other = await signup();
  const profile = {
    schemaVersion: 1,
    id: author.localId,
    name: "Test cook",
    handle: "bep_test",
    bio: "",
    showBio: true,
    cookedCount: 0,
    role: "user",
    status: "active",
  };
  await commit(
    [
      {
        update: {
          name: `${root}/users/${author.localId}`,
          fields: encode(profile).mapValue.fields,
        },
        updateTransforms: [stamp("createdAt"), stamp("updatedAt")],
      },
    ],
    author.idToken,
  );
  const catalog = loadCatalog().data;
  const cover = {
    id: "cover",
    name: "test.png",
    url: "https://res.cloudinary.com/ddqouziau/image/upload/v1/test.png",
    publicId: "test",
  };
  const content = {
    title: "Test recipe",
    description: "",
    cover,
    photos: Array.from({ length: 9 }, (_, i) => ({ ...cover, id: `photo_${i}` })),
    preparationMinutes: 5,
    cookingMinutes: 10,
    servings: 2,
    difficulty: "easy",
    meals: ["dinner"],
    categories: ["quick"],
    storageNotes: "",
    ingredientGroups: [{ id: "main", name: "Main" }],
    ingredients: [
      {
        id: "egg",
        ingredientId: "egg",
        name: "Trứng gà",
        amount: 0.5,
        unitId: "fruit",
        note: "",
        toTaste: false,
        groupId: "main",
      },
    ],
    steps: [
      {
        id: "s1",
        title: "",
        instruction: "Cook the eggs",
        minutes: 5,
        tip: "",
        photo: null,
      },
    ],
  };
  validateRecipeContent(content, catalog);
  for (const mutate of [
    (c) => {
      c.steps[0].instruction = "";
    },
    (c) => {
      c.ingredients[0].unitId = "unknown";
    },
    (c) => {
      c.cover.bytesBase64 = "not allowed";
    },
    (c) => {
      c.status = "published";
    },
    (c) => {
      c.isBanner = "true";
    },
  ]) {
    const bad = structuredClone(content);
    mutate(bad);
    assert.throws(() => validateRecipeContent(bad, catalog));
    checks++;
  }
  const id = `r_smoke_${Date.now()}`;
  const submission = {
    schemaVersion: 2,
    id,
    author: { id: profile.id, name: profile.name, handle: profile.handle },
    isBanner: false,
    authorId: author.localId,
    status: "pending",
    revisionOf: null,
    content,
    contentHash: "a".repeat(64),
    catalogVersion: catalog.version,
    reviewedAt: null,
    reviewedBy: null,
    reviewReason: null,
  };
  for (const photos of [
    Array.from({ length: 10 }, (_, i) => ({ ...cover, id: `photo_${i}` })),
    [{ ...cover, url: "https://example.test/photo.jpg" }],
    [{ ...cover, bytesBase64: "invalid" }],
    [...content.photos.slice(0, 8), { ...cover, url: "https://example.test/last.jpg" }],
    [{ ...cover, id: 123 }],
    [{ ...cover, publicId: "" }],
    [{ ...cover, url: `${cover.url}${"x".repeat(2048)}` }],
    "invalid",
  ]) {
    const invalid = { ...submission, id: `${id}_invalid_${checks}`, content: { ...content, photos } };
    assert.throws(() => validateRecipeContent(invalid.content, catalog));
    await commit([{
      update: { name: `${root}/recipes/${invalid.id}`, fields: encode(invalid).mapValue.fields },
      updateTransforms: [stamp("submittedAt")],
    }], author.idToken, 403);
  }
  const legacy = { ...submission, id: `${id}_legacy`, content: { ...content } };
  delete legacy.content.photos;
  validateRecipeContent(legacy.content, catalog);
  await commit([{
    update: { name: `${root}/recipes/${legacy.id}`, fields: encode(legacy).mapValue.fields },
    updateTransforms: [stamp("submittedAt")],
  }], author.idToken);
  const invalidBanner = structuredClone(submission);
  invalidBanner.id = `${id}_bad_banner`;
  invalidBanner.content.isBanner = "true";
  await commit(
    [
      {
        update: {
          name: `${root}/recipes/${invalidBanner.id}`,
          fields: encode(invalidBanner).mapValue.fields,
        },
        updateTransforms: [stamp("submittedAt")],
      },
    ],
    author.idToken,
    403,
  );
  const authorBanner = structuredClone(submission);
  authorBanner.id = `${id}_author_banner`;
  authorBanner.isBanner = true;
  await commit(
    [
      {
        update: {
          name: `${root}/recipes/${authorBanner.id}`,
          fields: encode(authorBanner).mapValue.fields,
        },
        updateTransforms: [stamp("submittedAt")],
      },
    ],
    author.idToken,
    403,
  );
  const write = {
    update: {
      name: `${root}/recipes/${id}`,
      fields: encode(submission).mapValue.fields,
    },
    updateTransforms: [stamp("submittedAt")],
  };
  await commit([write], author.idToken);
  const url = `${base}/recipes/${id}`;
  const raw = await request(url, undefined, author.idToken, 200, "GET");
  await request(url, undefined, other.idToken, 403, "GET");
  await request(url, undefined, undefined, 403, "GET");
  await commit(
    [
      {
        update: {
          name: write.update.name,
          fields: encode({ status: "approved" }).mapValue.fields,
        },
        updateMask: { fieldPaths: ["status"] },
      },
    ],
    author.idToken,
    403,
  );
  await commit(
    [
      {
        update: {
          name: `${root}/recipes/${id}`,
          fields: encode({ ...content, status: "published" }).mapValue.fields,
        },
      },
    ],
    author.idToken,
    403,
  );
  const moderator = await signup();
  await commit([{
    update: {
      name: `${root}/users/${moderator.localId}`,
      fields: encode({ ...profile, id: moderator.localId, role: "moderator" }).mapValue.fields,
    },
    updateTransforms: [stamp("createdAt"), stamp("updatedAt")],
  }], "owner");
  const approve = buildReviewWrites({
    project,
    id,
    submission,
    author: profile,
    catalog,
    decision: "approve",
    reason: null,
    reviewer: moderator.localId,
    updateTime: raw.updateTime,
  });
  await commit(approve, moderator.idToken);
  const published = await request(
    `${base}/recipes/${id}`,
    undefined,
    undefined,
    200,
    "GET",
  );
  assert.equal(published.fields.isBanner.booleanValue, false);
  const bannerWrite = {
    update: {
      name: `${root}/recipes/${id}`,
      fields: encode({ isBanner: true }).mapValue.fields,
    },
    updateMask: { fieldPaths: ["isBanner"] },
  };
  await commit([bannerWrite], author.idToken, 403);
  await commit([bannerWrite], "owner");
  const adminBanner = await request(
    `${base}/recipes/${id}`,
    undefined,
    undefined,
    200,
    "GET",
  );
  assert.equal(adminBanner.fields.isBanner.booleanValue, true);
  assert.equal(
    decode({ mapValue: { fields: published.fields } }).content.ingredients[0]
      .amount,
    0.5,
  );
  await commit(approve, "owner", 400); // currentDocument precondition rejects a second moderation decision.
  const approvedRaw = await request(url, undefined, author.idToken, 200, "GET");
  assert.equal(approvedRaw.fields.status.stringValue, "approved");
  await request(
    `${base}/recipe_moderation_events/${id}`,
    undefined,
    author.idToken,
    403,
    "GET",
  );
  const rejectedId = `${id}_rejected`;
  const rejectedSubmission = { ...submission, id: rejectedId };
  await commit(
    [
      {
        ...write,
        update: {
          name: `${root}/recipes/${rejectedId}`,
          fields: encode(rejectedSubmission).mapValue.fields,
        },
      },
    ],
    author.idToken,
  );
  const rejectedRaw = await request(
    `${base}/recipes/${rejectedId}`,
    undefined,
    author.idToken,
    200,
    "GET",
  );
  await commit(
    buildReviewWrites({
      project,
      id: rejectedId,
      submission: rejectedSubmission,
      decision: "reject",
      reason: "Need clearer steps",
      reviewer: "emulator-reviewer",
      updateTime: rejectedRaw.updateTime,
    }),
    "owner",
  );
  await request(
    `${base}/recipes/${rejectedId}`,
    undefined,
    undefined,
    403,
    "GET",
  );
  const revised = {
    ...submission,
    id: `${id}_revision`,
    revisionOf: rejectedId,
  };
  await commit(
    [
      {
        ...write,
        update: {
          name: `${root}/recipes/${revised.id}`,
          fields: encode(revised).mapValue.fields,
        },
      },
    ],
    author.idToken,
  );
  console.log(
    `PASS: ${checks} recipe publishing/moderation checks; production untouched.`,
  );
})().catch((e) => {
  console.error(e.message);
  process.exitCode = 1;
});
