#!/usr/bin/env node
// Creates the FIRST Director account on a fresh AumLux Supabase project.
// Every other account is then created in-app (admin-users function).
//
// Usage (PowerShell):
//   $env:SUPABASE_URL = "https://<ref>.supabase.co"
//   $env:SUPABASE_SECRET_KEY = "<sb_secret_... or service_role key>"   # never commit this
//   node tools/bootstrap/create-director.mjs --code AUM0001 --name "Full Name" --email you@company.com
//
// Prints a temporary password once; it must be changed at first sign-in.

import { randomInt } from "node:crypto";
import { parseArgs } from "node:util";

const { values: args } = parseArgs({
  options: {
    code: { type: "string" },
    name: { type: "string" },
    email: { type: "string" },
    phone: { type: "string" },
  },
});

const url = process.env.SUPABASE_URL?.replace(/\/$/, "");
const key = process.env.SUPABASE_SECRET_KEY ?? process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) {
  console.error("Set SUPABASE_URL and SUPABASE_SECRET_KEY (or SUPABASE_SERVICE_ROLE_KEY).");
  process.exit(1);
}
if (!args.code || !/^[A-Za-z0-9][A-Za-z0-9_-]{1,31}$/.test(args.code) || !args.name || !args.email) {
  console.error('Required: --code <EMPLOYEE_CODE> --name "<Full Name>" --email <email>');
  process.exit(1);
}

const headers = { apikey: key, "Content-Type": "application/json" };
// Legacy service_role keys are JWTs and also go in Authorization.
if (key.startsWith("eyJ")) headers.Authorization = `Bearer ${key}`;

async function call(path, init) {
  const res = await fetch(`${url}${path}`, { ...init, headers: { ...headers, ...init?.headers } });
  const text = await res.text();
  if (!res.ok) throw new Error(`${init?.method ?? "GET"} ${path} → ${res.status}: ${text}`);
  return text ? JSON.parse(text) : null;
}

const existing = await call("/rest/v1/profiles?role=eq.director&select=id&limit=1");
if (existing.length) {
  console.error("A Director already exists. Create further accounts from the app.");
  // Not process.exit(): exiting with open sockets crashes Node on Windows.
  process.exitCode = 1;
} else {
  await createDirector();
}

async function createDirector() {
  const alphabet = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789";
  const password =
    Array.from({ length: 11 }, () => alphabet[randomInt(alphabet.length)]).join("") + randomInt(2, 10);

  const user = await call("/auth/v1/admin/users", {
    method: "POST",
    body: JSON.stringify({
      email: args.email.trim().toLowerCase(),
      password,
      email_confirm: true,
      user_metadata: { employee_code: args.code, full_name: args.name },
    }),
  });

  try {
    await call("/rest/v1/profiles", {
      method: "POST",
      headers: { Prefer: "return=minimal" },
      body: JSON.stringify({
        id: user.id,
        employee_code: args.code,
        full_name: args.name,
        email: args.email.trim().toLowerCase(),
        phone: args.phone ?? null,
        role: "director",
        must_change_password: true,
      }),
    });
  } catch (e) {
    await call(`/auth/v1/admin/users/${user.id}`, { method: "DELETE" });
    throw e;
  }

  console.log("Director created.");
  console.log(`  Sign in with: ${args.email.trim().toLowerCase()}`);
  console.log(`  Temporary password: ${password}`);
  console.log("  You will be asked to set a new password at first sign-in.");
}
