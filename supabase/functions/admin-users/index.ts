// admin-users — the only way accounts are created or changed.
//
// Actions (POST JSON, caller's access token in Authorization):
//   create         { employee_code | auto_code: true, full_name, role, section_id, team_id?, email?, phone?, dob?, extra_section_ids? }
//                  auto_code allocates the next AUM0001-style code (ADR-0003), retrying on a race.
//   update         { user_id, full_name?, role?, section_id?, team_id?, email?, phone?, dob?, extra_section_ids? }
//   set_status     { user_id, status: "active" | "suspended" | "exited" }
//   reset_password { user_id }
//
// Rules (mirror the database helpers in private.*):
//   * caller must be active and manager or above — except reset_password,
//     which a supervisor may use for staff in teams they supervise;
//   * caller must strictly outrank the target's current and new role
//     (a director may manage directors);
//   * managers act only within their sections; COO/Director everywhere;
//   * accounts are never hard-deleted: "exited" bans the login and keeps history.
//
// Login identity: officers with a real email sign in with it; crew without
// email sign in with their employee code, mapped to <code>@staff.aumlux.internal
// (the same mapping the app uses). Temporary passwords are returned once and
// must be changed at first sign-in.

import {
  adminClient,
  bearer,
  callerClient,
  corsHeaders,
  HttpError,
  json,
} from "../_shared/supabase.ts";

const ROLES = ["staff", "supervisor", "manager", "coo", "director"] as const;
type Role = (typeof ROLES)[number];
const RANK: Record<Role, number> = { director: 0, coo: 1, manager: 2, supervisor: 3, staff: 4 };
export const CREW_LOGIN_DOMAIN = "staff.aumlux.internal";

interface Caller {
  id: string;
  jwt: string;
  role: Role;
  status: string;
  section_ids: string[];
  team_ids: string[];
}

interface TargetProfile {
  id: string;
  role: Role;
  section_id: string | null;
  team_id: string | null;
  employee_code: string;
}

const isExec = (c: Caller) => c.role === "coo" || c.role === "director";

function assertRole(value: unknown): Role {
  if (typeof value !== "string" || !ROLES.includes(value as Role)) {
    throw new HttpError(400, "invalid_role", "Choose a valid role.");
  }
  return value as Role;
}

function assertOutranks(caller: Caller, target: Role) {
  if (!(RANK[caller.role] < RANK[target] || caller.role === "director")) {
    throw new HttpError(403, "forbidden_role", "You can only manage roles below your own.");
  }
}

function assertSectionInScope(caller: Caller, sectionId: string | null | undefined) {
  if (isExec(caller)) return;
  if (!sectionId || !caller.section_ids.includes(sectionId)) {
    throw new HttpError(403, "forbidden_scope", "You can only manage people in your own sections.");
  }
}

/** 10 chars, unambiguous alphabet, always letters + digits (meets policy). */
function tempPassword(): string {
  const letters = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ";
  const digits = "23456789";
  const all = letters + digits;
  const bytes = crypto.getRandomValues(new Uint8Array(10));
  const chars = Array.from(bytes, (b) => all[b % all.length]);
  chars[0] = letters[bytes[0] % letters.length];
  chars[9] = digits[bytes[9] % digits.length];
  return chars.join("");
}

function loginEmail(employeeCode: string, email?: string | null): string {
  const real = email?.trim();
  return real ? real.toLowerCase() : `${employeeCode.trim().toLowerCase()}@${CREW_LOGIN_DOMAIN}`;
}

function clean(value: unknown): string | null {
  if (value === undefined || value === null) return null;
  const s = String(value).trim();
  return s.length ? s : null;
}

async function loadCaller(jwt: string): Promise<Caller> {
  const admin = adminClient();
  const { data: auth, error } = await admin.auth.getUser(jwt);
  if (error || !auth.user) throw new HttpError(401, "unauthenticated", "Sign in again to continue.");

  const { data: me, error: meError } = await callerClient(jwt).rpc("me");
  if (meError || !me) throw new HttpError(403, "not_active", "Your account is not active.");
  if (me.status !== "active") throw new HttpError(403, "not_active", "Your account is not active.");
  const role = assertRole(me.role);
  if (RANK[role] > RANK.supervisor) {
    throw new HttpError(403, "forbidden_role", "Only supervisors and above can manage accounts.");
  }
  return {
    id: me.id,
    jwt,
    role,
    status: me.status,
    section_ids: me.section_ids ?? [],
    team_ids: me.team_ids ?? [],
  };
}

async function loadTarget(userId: unknown): Promise<TargetProfile> {
  if (typeof userId !== "string") throw new HttpError(400, "invalid_user", "User is required.");
  const { data, error } = await adminClient()
    .from("profiles")
    .select("id, role, section_id, team_id, employee_code")
    .eq("id", userId)
    .maybeSingle();
  if (error) throw error;
  if (!data) throw new HttpError(404, "not_found", "User not found.");
  return data as TargetProfile;
}

async function setExtraSections(userId: string, caller: Caller, ids: unknown) {
  if (ids === undefined) return;
  if (!Array.isArray(ids)) throw new HttpError(400, "invalid_sections", "Sections must be a list.");
  ids.forEach((s) => assertSectionInScope(caller, s));
  const admin = adminClient();
  const { error: delError } = await admin.from("user_sections").delete().eq("user_id", userId);
  if (delError) throw delError;
  if (ids.length) {
    const { error } = await admin.from("user_sections")
      .insert(ids.map((section_id) => ({ user_id: userId, section_id })));
    if (error) throw error;
  }
}

/** A unique-code clash that a fresh generated code can resolve. */
class CodeTaken extends Error {}

async function create(caller: Caller, body: Record<string, unknown>) {
  const role = assertRole(body.role);
  assertOutranks(caller, role);
  const sectionId = clean(body.section_id);
  if (role !== "coo" && role !== "director") assertSectionInScope(caller, sectionId);
  const fullName = clean(body.full_name);
  if (!fullName) throw new HttpError(400, "invalid_name", "Full name is required.");
  const email = clean(body.email);
  const auto = body.auto_code === true;

  // Auto codes: two managers adding staff at the same moment get the same
  // suggestion; the loser of the race simply takes the next number.
  for (let attempt = 0; ; attempt++) {
    const code = auto ? await nextCode(caller) : clean(body.employee_code);
    if (!code || !/^[A-Za-z0-9][A-Za-z0-9_-]{1,31}$/.test(code)) {
      throw new HttpError(400, "invalid_code", "Employee code: 2–32 letters, digits, - or _.");
    }
    try {
      return await provision(caller, body, { code, role, sectionId, fullName, email });
    } catch (e) {
      if (e instanceof CodeTaken && auto && attempt < 4) continue;
      if (e instanceof CodeTaken) {
        throw new HttpError(409, "duplicate", "This employee code is already in use.");
      }
      throw e;
    }
  }
}

async function nextCode(caller: Caller): Promise<string> {
  const { data, error } = await callerClient(caller.jwt).rpc("next_employee_code");
  if (error || typeof data !== "string") throw error ?? new Error("next_employee_code failed");
  return data;
}

async function provision(
  caller: Caller,
  body: Record<string, unknown>,
  p: { code: string; role: Role; sectionId: string | null; fullName: string; email: string | null },
) {
  const { code, role, sectionId, fullName, email } = p;
  const admin = adminClient();
  const password = tempPassword();
  const { data: created, error: authError } = await admin.auth.admin.createUser({
    email: loginEmail(code, email),
    password,
    email_confirm: true,
    user_metadata: { employee_code: code, full_name: fullName },
  });
  if (authError || !created.user) {
    const msg = authError?.message ?? "";
    // Without an email the login is derived from the code, so a clash on it is
    // a code clash. Two simultaneous creates of the same login surface from
    // GoTrue as a generic "Database error creating new user" (unique violation).
    if (!email && /already.*registered|exists|database error creating new user/i.test(msg)) {
      throw new CodeTaken();
    }
    if (/already.*registered|exists/i.test(msg)) {
      throw new HttpError(409, "duplicate_login", "An account with this email already exists.");
    }
    throw authError ?? new Error("createUser failed");
  }

  const userId = created.user.id;
  const { error: profileError } = await admin.from("profiles").insert({
    id: userId,
    employee_code: code,
    full_name: fullName,
    role,
    section_id: sectionId,
    team_id: clean(body.team_id),
    email,
    phone: clean(body.phone),
    dob: clean(body.dob),
    must_change_password: true,
    created_by: caller.id,
  });
  if (profileError) {
    // Compensate: never leave a login without a profile.
    await admin.auth.admin.deleteUser(userId);
    if (profileError.code === "23505") {
      if (/employee_code/.test(`${profileError.message} ${profileError.details ?? ""}`)) throw new CodeTaken();
      throw new HttpError(409, "duplicate", "Phone or email is already in use.");
    }
    throw profileError;
  }

  try {
    await setExtraSections(userId, caller, body.extra_section_ids);
  } catch (e) {
    await admin.from("profiles").delete().eq("id", userId);
    await admin.auth.admin.deleteUser(userId);
    throw e;
  }

  return {
    user_id: userId,
    login_id: email ? loginEmail(code, email) : code,
    temp_password: password,
  };
}

async function update(caller: Caller, body: Record<string, unknown>) {
  const target = await loadTarget(body.user_id);
  if (target.id === caller.id) throw new HttpError(403, "forbidden_self", "You cannot change your own account here.");
  assertOutranks(caller, target.role);
  assertSectionInScope(caller, target.section_id);

  const patch: Record<string, unknown> = {};
  if (body.role !== undefined) {
    const role = assertRole(body.role);
    assertOutranks(caller, role);
    patch.role = role;
  }
  if (body.section_id !== undefined) {
    const sectionId = clean(body.section_id);
    assertSectionInScope(caller, sectionId);
    patch.section_id = sectionId;
    if (body.team_id === undefined) patch.team_id = null;
  }
  for (const field of ["full_name", "team_id", "email", "phone", "dob"]) {
    if (body[field] !== undefined) patch[field] = clean(body[field]);
  }
  if (Object.keys(patch).length) {
    const { error } = await adminClient().from("profiles").update(patch).eq("id", target.id);
    if (error) {
      if (error.code === "23505") throw new HttpError(409, "duplicate", "Phone or email is already in use.");
      throw error;
    }
  }
  await setExtraSections(target.id, caller, body.extra_section_ids);
  return { user_id: target.id };
}

async function setStatus(caller: Caller, body: Record<string, unknown>) {
  const status = body.status;
  if (status !== "active" && status !== "suspended" && status !== "exited") {
    throw new HttpError(400, "invalid_status", "Choose active, suspended or exited.");
  }
  const target = await loadTarget(body.user_id);
  if (target.id === caller.id) throw new HttpError(403, "forbidden_self", "You cannot change your own status.");
  assertOutranks(caller, target.role);
  assertSectionInScope(caller, target.section_id);

  const admin = adminClient();
  const { error } = await admin.from("profiles").update({ status }).eq("id", target.id);
  if (error) throw error;
  // Ban stops new sign-ins and token refresh; RLS already treats the user as
  // inactive on their very next request.
  const { error: banError } = await admin.auth.admin.updateUserById(target.id, {
    ban_duration: status === "active" ? "none" : "876000h",
  });
  if (banError) throw banError;
  return { user_id: target.id, status };
}

async function resetPassword(caller: Caller, body: Record<string, unknown>) {
  const target = await loadTarget(body.user_id);
  if (target.id === caller.id) {
    throw new HttpError(403, "forbidden_self", "Change your own password from your profile.");
  }
  assertOutranks(caller, target.role);
  if (caller.role === "supervisor") {
    if (target.role !== "staff" || !target.team_id || !caller.team_ids.includes(target.team_id)) {
      throw new HttpError(403, "forbidden_scope", "You can only reset passwords for your own team.");
    }
  } else {
    assertSectionInScope(caller, target.section_id);
  }

  const admin = adminClient();
  const password = tempPassword();
  const { error } = await admin.auth.admin.updateUserById(target.id, { password });
  if (error) throw error;
  const { error: flagError } = await admin.from("profiles")
    .update({ must_change_password: true }).eq("id", target.id);
  if (flagError) throw flagError;
  return { user_id: target.id, temp_password: password };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed", message: "Use POST." }, 405);

  try {
    const caller = await loadCaller(bearer(req));
    const body = await req.json().catch(() => {
      throw new HttpError(400, "invalid_json", "Request body must be JSON.");
    }) as Record<string, unknown>;

    if (caller.role === "supervisor" && body.action !== "reset_password") {
      throw new HttpError(403, "forbidden_role", "Only managers and above can manage accounts.");
    }

    switch (body.action) {
      case "create":
        return json(await create(caller, body), 201);
      case "update":
        return json(await update(caller, body));
      case "set_status":
        return json(await setStatus(caller, body));
      case "reset_password":
        return json(await resetPassword(caller, body));
      default:
        throw new HttpError(400, "invalid_action", "Unknown action.");
    }
  } catch (e) {
    if (e instanceof HttpError) return json({ code: e.code, message: e.message }, e.status);
    console.error("admin-users failed", e);
    return json({ code: "server_error", message: "Something went wrong. Try again." }, 500);
  }
});
