const assert = require("node:assert/strict");
const { decode, encode } = require("./firebase_cli_client.cjs");
const { buildReviewWrites } = require("./recipe_review_logic.cjs");
async function reviewInEmulator(id) {
  assert.match(id, /^r_[A-Za-z0-9_-]+$/);
  const base =
    "http://127.0.0.1:8080/v1/projects/demo-bepxinh/databases/(default)/documents";
  const get = async (path) => {
    const response = await fetch(`${base}/${path}`, {
      headers: { Authorization: "Bearer owner" },
    });
    assert.equal(response.status, 200);
    return response.json();
  };
  const raw = await get(`recipes/${id}`),
    submission = decode({ mapValue: { fields: raw.fields } });
  const author = decode({
    mapValue: { fields: (await get(`users/${submission.authorId}`)).fields },
  });
  const catalog = decode({
    mapValue: { fields: (await get("catalogs/ingredients")).fields },
  });
  const writes = buildReviewWrites({
    project: "demo-bepxinh",
    id,
    submission,
    author,
    catalog,
    decision: "approve",
    reason: null,
    reviewer: "emulator-sdk-review",
    updateTime: raw.updateTime,
  });
  const response = await fetch(`${base}:commit`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: "Bearer owner",
    },
    body: JSON.stringify({ writes }),
  });
  assert.equal(response.status, 200, JSON.stringify(await response.json()));
}
async function updateRecipeInEmulator(id, action) {
  assert.match(id, /^r_[A-Za-z0-9_-]+$/);
  assert.ok(
    [
      "MANUAL_APPROVE",
      "LIVE_BANNER_ON",
      "LIVE_BANNER_OFF",
      "LIVE_RECIPE_REMOVE",
    ].includes(action),
  );
  const root = "projects/demo-bepxinh/databases/(default)/documents";
  const name = `${root}/recipes/${id}`;
  const patch =
    action === "MANUAL_APPROVE"
      ? { status: "approved" }
      : action === "LIVE_BANNER_ON"
        ? { isBanner: true, "content.title": "Realtime admin update" }
        : { isBanner: false };
  const writes =
    action === "LIVE_RECIPE_REMOVE"
      ? [{ delete: name }]
      : [
          {
            update: {
              name,
              fields: encode(
                action === "LIVE_BANNER_ON"
                  ? {
                      isBanner: true,
                      content: { title: "Realtime admin update" },
                    }
                  : patch,
              ).mapValue.fields,
            },
            updateMask: { fieldPaths: Object.keys(patch) },
          },
        ];
  const response = await fetch(`http://127.0.0.1:8080/v1/${root}:commit`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: "Bearer owner",
    },
    body: JSON.stringify({ writes }),
  });
  assert.equal(response.status, 200, JSON.stringify(await response.json()));
}
module.exports = { reviewInEmulator, updateRecipeInEmulator };
