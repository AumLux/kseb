// push — delivers an in-app notification to the user's phones via FCM.
//
// Called by the `push_notification` database trigger:
//   POST { notification_id }  with header  x-push-secret: <PUSH_WEBHOOK_SECRET>
//
// Secrets (supabase secrets set ...):
//   PUSH_WEBHOOK_SECRET   same random value stored in Vault as push_webhook_secret
//   FCM_SERVICE_ACCOUNT   Firebase service-account JSON (Project settings ›
//                         Service accounts › Generate new private key)
//
// FCM HTTP v1 is free; only the Firebase project (Spark plan) is needed.

import { adminClient, corsHeaders, json } from "../_shared/supabase.ts";

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
}

let cachedToken: { value: string; expires: number } | null = null;

function b64url(data: ArrayBuffer | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : new Uint8Array(data);
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expires > now + 60) return cachedToken.value;

  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: sa.token_uri ?? "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claims}`));
  const assertion = `${header}.${claims}.${b64url(signature)}`;

  const res = await fetch(sa.token_uri ?? "https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }),
  });
  if (!res.ok) throw new Error(`OAuth token request failed: ${res.status} ${await res.text()}`);
  const body = await res.json() as { access_token: string; expires_in: number };
  cachedToken = { value: body.access_token, expires: now + body.expires_in };
  return body.access_token;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const secret = Deno.env.get("PUSH_WEBHOOK_SECRET");
  if (!secret || req.headers.get("x-push-secret") !== secret) {
    return json({ code: "unauthorized" }, 401);
  }
  const saRaw = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!saRaw) return json({ code: "not_configured", message: "FCM_SERVICE_ACCOUNT is not set." }, 200);

  try {
    const { notification_id } = await req.json() as { notification_id?: string };
    if (!notification_id) return json({ code: "invalid" }, 400);

    const db = adminClient();
    const { data: n, error } = await db
      .from("notifications")
      .select("id, user_id, title, body, route")
      .eq("id", notification_id)
      .maybeSingle();
    if (error) throw error;
    if (!n) return json({ code: "not_found" }, 404);

    const { data: devices, error: devError } = await db
      .from("device_tokens")
      .select("token")
      .eq("user_id", n.user_id);
    if (devError) throw devError;
    if (!devices?.length) return json({ sent: 0 });

    const sa = JSON.parse(saRaw) as ServiceAccount;
    const token = await accessToken(sa);
    let sent = 0;
    for (const { token: device } of devices) {
      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
        method: "POST",
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          message: {
            token: device,
            notification: { title: n.title, body: n.body ?? "" },
            data: { route: n.route ?? "/home", notification_id: n.id },
            android: { priority: "high" },
          },
        }),
      });
      if (res.ok) {
        sent++;
      } else if (res.status === 404 || res.status === 400) {
        // UNREGISTERED / INVALID_ARGUMENT: the app was uninstalled or the
        // token rotated — prune it.
        const text = await res.text();
        if (/UNREGISTERED|registration-token-not-registered|INVALID_ARGUMENT/.test(text)) {
          await db.from("device_tokens").delete().eq("token", device);
        }
      }
    }
    return json({ sent });
  } catch (e) {
    console.error("push failed", e);
    return json({ code: "server_error" }, 500);
  }
});
