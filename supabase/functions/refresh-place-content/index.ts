import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-content-refresh-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function stripHtml(html: string): string {
  return html
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, " ")
    .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/&#(\d+);/g, (_m, n) => String.fromCodePoint(Number(n)))
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 12000);
}

function safePublicUrl(raw: string): URL | null {
  try {
    const url = new URL(raw);
    if (url.protocol !== "https:" || !url.hostname.includes(".")) return null;
    if (/^(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)/i.test(url.hostname)) return null;
    return url;
  } catch {
    return null;
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "POST required" }, 405);

  const refreshSecret = Deno.env.get("CONTENT_REFRESH_SECRET");
  if (!refreshSecret || req.headers.get("x-content-refresh-secret") !== refreshSecret) {
    return json({ error: "Unauthorized" }, 401);
  }

  const openAiKey = Deno.env.get("OPENAI_API_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!openAiKey || !supabaseUrl || !serviceKey) {
    return json({ error: "Server secrets are not configured" }, 503);
  }

  const client = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  let limit = 5;
  try {
    const body = await req.json().catch(() => ({}));
    if (Number.isInteger(body?.limit)) limit = Math.max(1, Math.min(10, body.limit));
  } catch {
    // Use the safe default batch size.
  }

  const { data: places, error } = await client
    .from("places")
    .select("id,name,city,short_description,long_description,website,source_url,verified,trust_score")
    .eq("is_active", true)
    .eq("verified", true)
    .not("website", "is", null)
    .order("verified_at", { ascending: true, nullsFirst: true })
    .limit(limit);

  if (error) return json({ error: "Could not load places", details: error.message }, 500);

  const results: Array<{ id: string; status: string }> = [];
  for (const place of places ?? []) {
    const rawUrl = place.source_url || place.website;
    const sourceUrl = typeof rawUrl === "string" ? safePublicUrl(rawUrl) : null;
    if (!sourceUrl) {
      results.push({ id: place.id, status: "skipped_invalid_source" });
      continue;
    }

    try {
      const response = await fetch(sourceUrl.toString(), {
        headers: { "User-Agent": "BugunCityGuide/1.0 (source-based content refresh)" },
        signal: AbortSignal.timeout(10000),
        redirect: "follow",
      });
      if (!response.ok) {
        results.push({ id: place.id, status: "source_unavailable" });
        continue;
      }
      const finalUrl = new URL(response.url);
      if (finalUrl.protocol !== "https:") {
        results.push({ id: place.id, status: "unsafe_redirect" });
        continue;
      }
      const contentType = response.headers.get("content-type") || "";
      if (!contentType.includes("text/html") && !contentType.includes("text/plain")) {
        results.push({ id: place.id, status: "unsupported_source_type" });
        continue;
      }

      const sourceText = stripHtml(await response.text());
      if (sourceText.length < 250) {
        results.push({ id: place.id, status: "insufficient_source_text" });
        continue;
      }

      const prompt = {
        place_name: place.name,
        city: place.city,
        current_short_description: place.short_description,
        current_long_description: place.long_description,
        source_url: finalUrl.toString(),
        source_text: sourceText,
      };

      const aiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${openAiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4.1-mini",
          temperature: 0.1,
          response_format: { type: "json_object" },
          messages: [
            {
              role: "system",
              content: "Türkçe şehir rehberi editörüsün. Yalnızca verilen kaynak metninde desteklenen olguları kullan. Kaynakta bulunmayan ücret, saat, ulaşım, tarih, özellik veya iddia uydurma. Kaynak yeri doğrulamıyorsa eligible=false döndür. JSON alanları: eligible (boolean), short_description (string), long_description (string). short_description en fazla 350 karakter; long_description 600-1800 karakter. Kaynak metnini kopyalama, özgün ve temkinli biçimde özetle.",
            },
            { role: "user", content: JSON.stringify(prompt) },
          ],
        }),
        signal: AbortSignal.timeout(30000),
      });

      if (!aiResponse.ok) {
        results.push({ id: place.id, status: "ai_request_failed" });
        continue;
      }
      const aiJson = await aiResponse.json();
      const content = aiJson.choices?.[0]?.message?.content;
      if (typeof content !== "string") {
        results.push({ id: place.id, status: "empty_ai_response" });
        continue;
      }
      const generated = JSON.parse(content);
      if (generated.eligible !== true ||
          typeof generated.short_description !== "string" ||
          typeof generated.long_description !== "string" ||
          generated.short_description.trim().length < 30 ||
          generated.long_description.trim().length < 120) {
        results.push({ id: place.id, status: "source_not_sufficiently_relevant" });
        continue;
      }

      const now = new Date().toISOString();
      const { error: updateError } = await client
        .from("places")
        .update({
          short_description: generated.short_description.trim().slice(0, 350),
          long_description: generated.long_description.trim().slice(0, 4000),
          source_url: finalUrl.toString(),
          verified_at: now,
          content_updated_at: now,
          content_review_status: "verified",
          updated_at: now,
        })
        .eq("id", place.id);

      results.push({ id: place.id, status: updateError ? "database_update_failed" : "updated" });
    } catch {
      results.push({ id: place.id, status: "refresh_failed" });
    }
  }

  return json({
    processed: results.length,
    updated: results.filter((r) => r.status === "updated").length,
    results,
    note: "Only verified places with a reachable HTTPS source were considered. No unsupported facts are intentionally added.",
  });
});
