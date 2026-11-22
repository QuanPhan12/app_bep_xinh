const fs = require("node:fs");
const path = require("node:path");
async function firebaseClient(project) {
  let lib;
  for (const entry of process.env.PATH.split(path.delimiter)) {
    const candidate = path.resolve(entry, "../firebase-tools/lib");
    if (fs.existsSync(path.join(candidate, "requireAuth.js"))) {
      lib = candidate;
      break;
    }
  }
  if (!lib)
    throw new Error(
      "Run using npm exec --package=firebase-tools@15.34.2 -- node ...",
    );
  const auth = require(path.join(lib, "auth"));
  const options = { project, nonInteractive: true };
  auth.setActiveAccount(options, auth.selectAccount(undefined, process.cwd()));
  await require(path.join(lib, "requireAuth")).requireAuth(options);
  const { Client } = require(path.join(lib, "apiv2"));
  return {
    api: new Client({
      urlPrefix: "https://firestore.googleapis.com",
      auth: true,
    }),
    user: options.user,
  };
}
function encode(value) {
  if (value === null) return { nullValue: null };
  if (typeof value === "string") return { stringValue: value };
  if (typeof value === "boolean") return { booleanValue: value };
  if (typeof value === "number")
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  if (Array.isArray(value))
    return { arrayValue: { values: value.map(encode) } };
  return {
    mapValue: {
      fields: Object.fromEntries(
        Object.entries(value).map(([k, v]) => [k, encode(v)]),
      ),
    },
  };
}
function decode(value) {
  if ("nullValue" in value) return null;
  if ("stringValue" in value) return value.stringValue;
  if ("booleanValue" in value) return value.booleanValue;
  if ("integerValue" in value) return Number(value.integerValue);
  if ("doubleValue" in value) return value.doubleValue;
  if ("timestampValue" in value) return value.timestampValue;
  if ("arrayValue" in value) return (value.arrayValue.values || []).map(decode);
  if ("mapValue" in value)
    return Object.fromEntries(
      Object.entries(value.mapValue.fields || {}).map(([k, v]) => [
        k,
        decode(v),
      ]),
    );
  throw new Error("Unsupported Firestore value");
}
module.exports = { firebaseClient, encode, decode };
