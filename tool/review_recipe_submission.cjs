const crypto = require("node:crypto");
const { firebaseClient, encode, decode } = require("./firebase_cli_client.cjs");
const { buildReviewWrites } = require("./recipe_review_logic.cjs");
function option(name) {
  const i = process.argv.indexOf(name);
  return i < 0 ? undefined : process.argv[i + 1];
}
(async () => {
  const project = option("--project");
  if (project !== "bepxinh-b0be7")
    throw new Error("Explicit --project bepxinh-b0be7 required");
  const { api, user } = await firebaseClient(project);
  const base = `/v1/projects/${project}/databases/(default)/documents`;
  if (process.argv.includes("--list")) {
    const result = await api.post(`${base}:runQuery`, {
      structuredQuery: {
        from: [{ collectionId: "recipes" }],
        where: {
          fieldFilter: {
            field: { fieldPath: "status" },
            op: "EQUAL",
            value: { stringValue: "pending" },
          },
        },
        limit: 50,
      },
    });
    for (const row of result.body)
      if (row.document) {
        const d = decode({ mapValue: { fields: row.document.fields } });
        console.log(
          JSON.stringify({
            id: d.id,
            authorId: d.authorId,
            title: d.content?.title ?? "(invalid content)",
            status: d.status,
          }),
        );
      }
    return;
  }
  const id = option("--id"),
    decision = option("--decision"),
    reason = option("--reason") || null;
  if (
    !/^r_[A-Za-z0-9_-]{1,64}$/.test(id || "") ||
    !["approve", "reject"].includes(decision)
  )
    throw new Error("--id r_... --decision approve|reject required");
  if (reason !== null && (reason.length > 500 || !reason.trim()))
    throw new Error("Reason must be 1..500 characters");
  if (decision === "reject" && !reason)
    throw new Error("Rejection reason required");
  const principal = user?.user_id || user?.sub || user?.email;
  if (!principal) throw new Error("Cannot identify authenticated IAM reviewer");
  const reviewer = `iam:${crypto.createHash("sha256").update(principal).digest("hex").slice(0, 32)}`;
  for (let attempt = 0; attempt < 3; attempt++) {
    const begun = await api.post(`${base}:beginTransaction`, {});
    const transaction = begun.body.transaction;
    let committed = false;
    try {
      const read = async (path) =>
        api.get(path, { queryParams: { transaction } });
      const response = await read(`${base}/recipes/${id}`);
      const submission = decode({ mapValue: { fields: response.body.fields } });
      let author, catalog;
      if (decision === "approve") {
        const authorResponse = await read(
          `${base}/users/${encodeURIComponent(submission.authorId)}`,
        );
        author = decode({ mapValue: { fields: authorResponse.body.fields } });
        const catalogResponse = await read(`${base}/catalogs/ingredients`);
        catalog = decode({ mapValue: { fields: catalogResponse.body.fields } });
      }
      const writes = buildReviewWrites({
        project,
        id,
        submission,
        author,
        catalog,
        decision,
        reason,
        reviewer,
        updateTime: response.body.updateTime,
      });
      console.log(
        JSON.stringify({
          id,
          authorId: submission.authorId,
          decision,
          dryRun: !process.argv.includes("--apply"),
        }),
      );
      if (!process.argv.includes("--apply")) return;
      await api.post(`${base}:commit`, { transaction, writes });
      committed = true;
      console.log(`Reviewed ${id}: ${decision}`);
      return;
    } catch (error) {
      if (
        attempt === 2 ||
        (!String(error.message).includes("ABORTED") && error.status !== 409)
      )
        throw error;
      await new Promise((resolve) => setTimeout(resolve, 250 * (attempt + 1)));
    } finally {
      if (!committed)
        await api.post(`${base}:rollback`, { transaction }).catch(() => {});
    }
  }
})().catch((e) => {
  console.error(e.message);
  process.exitCode = 1;
});
