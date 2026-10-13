import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return json(401, { error: "authentication_required" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    console.error("Required Supabase function environment variables are missing.");
    return json(500, { error: "server_configuration_error" });
  }

  const token = authorization.slice("Bearer ".length);
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  try {
    // Resolve the bearer token to its user. Never accept a user id from the request body.
    const { data: authData, error: authError } = await admin.auth.getUser(token);
    if (authError || !authData.user) return json(401, { error: "invalid_session" });
    const user = authData.user;
    const userId = user.id;

    // Remove profile images belonging to this account before deleting its database rows.
    const bucket = admin.storage.from("profile-avatars");
    const { data: objects, error: listError } = await bucket.list(userId, { limit: 1000 });
    if (listError) throw listError;
    if (objects && objects.length > 0) {
      const { error: removeError } = await bucket.remove(
        objects.map((object) => `${userId}/${object.name}`),
      );
      if (removeError) throw removeError;
    }

    // Delete child rows first because the existing foreign keys do not all cascade.
    const { data: hostedActivities, error: hostedError } = await admin
      .from("community_activities").select("id").eq("host_user_id", userId);
    if (hostedError) throw hostedError;
    const activityIds = (hostedActivities ?? []).map((row) => row.id);

    if (activityIds.length > 0) {
      const { error } = await admin.from("activity_participants").delete().in("activity_id", activityIds);
      if (error) throw error;
      const { error: invitationError } = await admin.from("activity_invitations").delete().in("activity_id", activityIds);
      if (invitationError) throw invitationError;
    }

    const deletions = [
      admin.from("activity_participants").delete().eq("user_id", userId),
      admin.from("activity_invitations").delete().eq("inviter_user_id", userId),
      admin.from("app_feedback").delete().eq("user_id", userId),
      ...(user.email ? [admin.from("app_feedback").delete().ilike("email", user.email)] : []),
      admin.from("user_interactions").delete().eq("user_id", userId),
      admin.from("saved_items").delete().eq("user_id", userId),
      admin.from("content_reports").delete().eq("user_id", userId),
    ];
    if (user.email) {
      deletions.push(admin.from("activity_invitations").delete().ilike("invitee_email", user.email));
    }
    const results = await Promise.all(deletions);
    for (const result of results) {
      if (result.error) throw result.error;
    }

    // Keep public business records but detach the deleted account as their owner.
    const { error: businessError } = await admin
      .from("businesses").update({ owner_user_id: null }).eq("owner_user_id", userId);
    if (businessError) throw businessError;

    if (activityIds.length > 0) {
      const { error } = await admin.from("community_activities").delete().in("id", activityIds);
      if (error) throw error;
    }

    const { error: profileError } = await admin.from("profiles").delete().eq("id", userId);
    if (profileError) throw profileError;

    const { error: deleteUserError } = await admin.auth.admin.deleteUser(userId);
    if (deleteUserError) throw deleteUserError;

    return json(200, { success: true });
  } catch (error) {
    console.error("Account deletion failed:", error);
    return json(500, {
      error: "account_deletion_failed",
      message: "Account deletion could not be completed. Please retry or contact support.",
    });
  }
});
