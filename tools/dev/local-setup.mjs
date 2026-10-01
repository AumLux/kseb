#!/usr/bin/env node
// LOCAL STACK ONLY. Prepares `supabase start` for testing the app:
//   1. writes env/local.json (gitignored) for --dart-define-from-file
//   2. creates one demo account per role, with a known password and no
//      forced password change (see docs/LOCAL_TESTING.md)
//
// Usage:  node tools/dev/local-setup.mjs        (re-run after `supabase db reset`)
//
// Refuses to run against anything but 127.0.0.1 / localhost.

import { execSync } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";

const PASSWORD = "LocalTest2026y"; // local demo password, documented in docs/LOCAL_TESTING.md
const KALOOR = "44444444-0000-4000-8000-000000000001";
const ALUVA = "44444444-0000-4000-8000-000000000003";

const status = Object.fromEntries(
  execSync("supabase status -o env", { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] })
    .split(/\r?\n/)
    .map((l) => l.match(/^([A-Z_0-9]+)="?(.*?)"?$/))
    .filter(Boolean)
    .map((m) => [m[1], m[2]]),
);
const url = status.API_URL;
const publishable = status.PUBLISHABLE_KEY ?? status.ANON_KEY;
const secret = status.SECRET_KEY ?? status.SERVICE_ROLE_KEY;
if (!url || !/^http:\/\/(127\.0\.0\.1|localhost)(:\d+)?$/.test(url)) {
  console.error(`Refusing: "${url}" is not the local stack. Is \`supabase start\` running?`);
  process.exit(1);
}

mkdirSync("env", { recursive: true });
writeFileSync(
  "env/local.json",
  JSON.stringify(
    { SUPABASE_URL: url, SUPABASE_PUBLISHABLE_KEY: publishable, ENABLE_BONUS_MODULE: "true" },
    null,
    2,
  ) + "\n",
);
console.log("Wrote env/local.json");

const svc = { apikey: secret, "Content-Type": "application/json" };
if (secret.startsWith("eyJ")) svc.Authorization = `Bearer ${secret}`;

async function call(path, { method = "GET", body, headers = {}, token } = {}) {
  const res = await fetch(url + path, {
    method,
    headers: token
      ? { apikey: publishable, "Content-Type": "application/json", Authorization: `Bearer ${token}`, ...headers }
      : { ...svc, ...headers },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${method} ${path} → ${res.status}: ${text}`);
  return text ? JSON.parse(text) : null;
}

const profileByCode = async (code) =>
  (await call(`/rest/v1/profiles?employee_code=eq.${code}&select=id`))[0]?.id;

async function finish(id) {
  await call(`/auth/v1/admin/users/${id}`, { method: "PUT", body: { password: PASSWORD } });
  await call(`/rest/v1/profiles?id=eq.${id}`, {
    method: "PATCH",
    headers: { Prefer: "return=minimal" },
    body: { must_change_password: false },
  });
}

// Director: created directly, the same way tools/bootstrap does it.
let directorId = await profileByCode("AUM0001");
if (!directorId) {
  const user = await call("/auth/v1/admin/users", {
    method: "POST",
    body: { email: "director@aumlux.test", password: PASSWORD, email_confirm: true },
  });
  await call("/rest/v1/profiles", {
    method: "POST",
    headers: { Prefer: "return=minimal" },
    body: { id: user.id, employee_code: "AUM0001", full_name: "Anita Menon", email: "director@aumlux.test", role: "director" },
  });
  directorId = user.id;
}
await finish(directorId);

const signIn = await fetch(`${url}/auth/v1/token?grant_type=password`, {
  method: "POST",
  headers: { apikey: publishable, "Content-Type": "application/json" },
  body: JSON.stringify({ email: "director@aumlux.test", password: PASSWORD }),
});
if (!signIn.ok) throw new Error(`director sign-in → ${signIn.status}: ${await signIn.text()}`);
const session = await signIn.json();

// Everyone else goes through the real admin-users function.
async function ensure(user) {
  let id = await profileByCode(user.employee_code);
  if (!id) {
    const created = await call("/functions/v1/admin-users", {
      method: "POST",
      token: session.access_token,
      body: { action: "create", ...user },
    });
    id = created.user_id;
  }
  await finish(id);
  return id;
}

await ensure({ employee_code: "AUM0002", full_name: "Rajesh Nair", role: "coo", section_id: KALOOR, email: "coo@aumlux.test" });
await ensure({ employee_code: "AUM0100", full_name: "Kaloor Manager", role: "manager", section_id: KALOOR, email: "manager@aumlux.test" });
const supervisorId = await ensure({ employee_code: "AUM0200", full_name: "Suresh Kumar", role: "supervisor", section_id: KALOOR, email: "supervisor@aumlux.test" });

let teamId = (await call(`/rest/v1/teams?section_id=eq.${KALOOR}&name=eq.Kaloor%20Line%20Team&select=id`))[0]?.id;
if (!teamId) {
  teamId = (
    await call("/rest/v1/teams", {
      method: "POST",
      headers: { Prefer: "return=representation" },
      body: { section_id: KALOOR, name: "Kaloor Line Team", supervisor_id: supervisorId },
    })
  )[0].id;
}
await call(`/rest/v1/profiles?id=eq.${supervisorId}`, { method: "PATCH", headers: { Prefer: "return=minimal" }, body: { team_id: teamId } });

await ensure({ employee_code: "AUM0301", full_name: "Line Worker One", role: "staff", section_id: KALOOR, team_id: teamId });
await ensure({ employee_code: "AUM0302", full_name: "Aluva Worker", role: "staff", section_id: ALUVA });

console.log("Demo accounts ready (passwords: docs/LOCAL_TESTING.md):");
console.table([
  { role: "director", "sign in with": "director@aumlux.test" },
  { role: "coo", "sign in with": "coo@aumlux.test" },
  { role: "manager (Kaloor)", "sign in with": "manager@aumlux.test" },
  { role: "supervisor (Kaloor team)", "sign in with": "supervisor@aumlux.test" },
  { role: "staff (Kaloor team)", "sign in with": "AUM0301" },
  { role: "staff (Aluva, out of scope)", "sign in with": "AUM0302" },
]);
