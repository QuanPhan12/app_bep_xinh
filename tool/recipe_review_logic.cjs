const assert = require("node:assert/strict");
const { encode } = require("./firebase_cli_client.cjs");
const { validateRecipeContent } = require("./recipe_content_validation.cjs");
function buildReviewWrites({
  project,
  id,
  submission,
  author,
  catalog,
  decision,
  reason,
  reviewer,
  updateTime,
}) {
  assert.equal(submission.schemaVersion, 2);
  assert.equal(submission.id, id);
  assert.equal(submission.status, "pending");
  assert.ok(
    typeof submission.authorId === "string" && submission.authorId.length > 0,
  );
  assert.ok(["approve", "reject"].includes(decision));
  assert.ok(
    reason === null ||
      (typeof reason === "string" &&
        reason.trim().length > 0 &&
        reason.length <= 500),
  );
  if (decision === "reject") assert.ok(reason, "Rejection reason required");
  if (decision === "approve") {
    assert.equal(author?.id, submission.authorId);
    assert.equal(author.status ?? "active", "active");
    validateRecipeContent(submission.content, catalog);
  }
  const name = `projects/${project}/databases/(default)/documents`;
  const status = decision === "approve" ? "approved" : "rejected";
  const writes = [
    {
      update: {
        name: `${name}/recipes/${id}`,
        fields: encode({ status, reviewedBy: reviewer, reviewReason: reason })
          .mapValue.fields,
      },
      updateMask: { fieldPaths: ["status", "reviewedBy", "reviewReason"] },
      currentDocument: { updateTime },
      updateTransforms: [
        { fieldPath: "reviewedAt", setToServerValue: "REQUEST_TIME" },
      ],
    },
    {
      update: {
        name: `${name}/recipe_moderation_events/${id}`,
        fields: encode({
          submissionId: id,
          authorId: submission.authorId,
          decision,
          reviewer,
          reason,
        }).mapValue.fields,
      },
      currentDocument: { exists: false },
      updateTransforms: [
        { fieldPath: "createdAt", setToServerValue: "REQUEST_TIME" },
      ],
    },
  ];
  return writes;
}
module.exports = { buildReviewWrites };
