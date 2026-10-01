import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

/** Error with a stable `code` the client maps to localised copy. */
export class HttpError extends Error {
  constructor(public status: number, public code: string, message: string) {
    super(message);
  }
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** First key from the new JSON key env vars, falling back to legacy names. */
function key(newVar: string, legacyVar: string): string {
  const legacy = Deno.env.get(legacyVar);
  if (legacy) return legacy;
  const raw = Deno.env.get(newVar);
  if (raw) {
    const parsed = JSON.parse(raw) as Record<string, string>;
    const first = parsed.default ?? Object.values(parsed)[0];
    if (first) return first;
  }
  throw new Error(`Missing ${legacyVar}/${newVar}`);
}

const url = () => Deno.env.get("SUPABASE_URL")!;

/** Service client: bypasses RLS. Only use after authorising the caller. */
export function adminClient(): SupabaseClient {
  return createClient(url(), key("SUPABASE_SECRET_KEYS", "SUPABASE_SERVICE_ROLE_KEY"), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/** Client acting as the caller, so RLS and RPC checks apply to them. */
export function callerClient(jwt: string): SupabaseClient {
  return createClient(url(), key("SUPABASE_PUBLISHABLE_KEYS", "SUPABASE_ANON_KEY"), {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function bearer(req: Request): string {
  const header = req.headers.get("Authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : "";
  if (!token) throw new HttpError(401, "unauthenticated", "Sign in again to continue.");
  return token;
}
