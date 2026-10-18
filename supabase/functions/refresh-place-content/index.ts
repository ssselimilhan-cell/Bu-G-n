import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-content-refresh-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } });
}
function normalize(value: string): string {
  return value.toLocaleLowerCase("tr-TR").normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/ı/g, "i").replace(/[^a-z0-9 ]/g, " ").replace(/\s+/g, " ").trim();
}
function stripHtml(html: string): string {
  return html.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, " ")
    .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ").replace(/&nbsp;/gi, " ").replace(/&amp;/gi, "&")
    .replace(/&quot;/gi, '"').replace(/&#39;/gi, "'").replace(/\s+/g, " ").trim().slice(0, 12000);
}
function safePublicUrl(raw: string): URL | null {
  try {
    const url = new URL(raw);
    if (url.protocol !== "https:" || !url.hostname.includes(".")) return null;
    if (/^(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)/i.test(url.hostname)) return null;
    return url;
  } catch { return null; }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "POST required" }, 405);
  const refreshSecret = Deno.env.get("CONTENT_REFRESH_SECRET");
  if (!refreshSecret || req.headers.get("x-content-refresh-secret") !== refreshSecret) return json({ error: "Unauthorized" }, 401);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) return json({ error: "Supabase server secrets are not configured" }, 503);
  const client = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const openAiKey = Deno.env.get("OPENAI_API_KEY");
  let limit = 10;
  try {
    const body = await req.json().catch(() => ({}));
    if (Number.isInteger(body?.limit)) limit = Math.max(1, Math.min(25, body.limit));
  } catch { /* use default */ }

  const cutoff = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();
  const { data: places, error } = await client.from("places")
    .select("id,name,city,short_description,long_description,website,source_url,verified_at,content_review_status")
    .eq("is_active", true)
    .or(`content_review_status.eq.needs_review,content_review_status.eq.stale,verified_at.lt.${cutoff}`)
    .order("verified_at", { ascending: true, nullsFirst: true })
    .limit(limit);
  if (error) return json({ error: "Could not load places", details: error.message }, 500);

  const results: Array<{id: string; status: string; source?: string}> = [];
  for (const place of places ?? []) {
    try {
      let sourceUrl: string | null = null;
      let sourceText = "";
      let sourceTitle = "";

      const knownUrl = typeof place.source_url === "string" && place.source_url.trim()
        ? place.source_url : (typeof place.website === "string" ? place.website : "");
      const safeKnownUrl = knownUrl ? safePublicUrl(knownUrl) : null;
      if (safeKnownUrl) {
        const page = await fetch(safeKnownUrl.toString(), {
          headers: { "User-Agent": "BugunCityGuide/1.0 (source-based content refresh)" },
          signal: AbortSignal.timeout(8000),
          redirect: "follow",
        });
        const finalUrl = safePublicUrl(page.url);
        if (page.ok && finalUrl) {
          const type = page.headers.get("content-type") || "";
          if (type.includes("text/html") || type.includes("text/plain")) {
            sourceText = stripHtml(await page.text());
            sourceUrl = finalUrl.toString();
            sourceTitle = place.name;
          }
        }
      }

      // If no usable source URL exists, look for an exact or near-exact Turkish Wikipedia article.
      if (!sourceText) {
        const searchTerm = `${place.name} ${place.city}`;
        const searchUrl = "https://tr.wikipedia.org/w/api.php?action=query&list=search&format=json&utf8=1&srlimit=5&srsearch=" + encodeURIComponent(searchTerm);
        const searchResponse = await fetch(searchUrl, { headers: { "User-Agent": "BugunCityGuide/1.0 (source discovery)" }, signal: AbortSignal.timeout(8000) });
        if (!searchResponse.ok) {
          results.push({ id: place.id, status: "source_search_failed" });
          continue;
        }
        const searchJson = await searchResponse.json();
        const resultsList = searchJson.query?.search ?? [];
        const wanted = normalize(place.name);
        const candidate = resultsList.find((item: {title: string}) => {
          const title = normalize(item.title);
          return title === wanted || title.includes(wanted) || (wanted.length > 8 && wanted.includes(title));
        });
        if (!candidate) {
          await client.from("places").update({ content_review_status: "rejected" }).eq("id", place.id);
          results.push({ id: place.id, status: "no_reliable_wikipedia_match" });
          continue;
        }
        const summaryUrl = "https://tr.wikipedia.org/api/rest_v1/page/summary/" + encodeURIComponent(candidate.title.replace(/ /g, "_"));
        const summaryResponse = await fetch(summaryUrl, { headers: { "User-Agent": "BugunCityGuide/1.0 (source discovery)" }, signal: AbortSignal.timeout(8000) });
        if (!summaryResponse.ok) {
          results.push({ id: place.id, status: "article_summary_unavailable" });
          continue;
        }
        const summary = await summaryResponse.json();
        const summaryText = typeof summary.extract === "string" ? summary.extract.trim() : "";
        const summaryLink = summary.content_urls?.desktop?.page;
        const finalWikiUrl = typeof summaryLink === "string" ? safePublicUrl(summaryLink) : null;
        if (!summaryText || !finalWikiUrl || summaryText.length < 100) {
          results.push({ id: place.id, status: "insufficient_source_text" });
          continue;
        }
        sourceText = summaryText;
        sourceUrl = finalWikiUrl.toString();
        sourceTitle = typeof summary.title === "string" ? summary.title : candidate.title;
      }

      let shortDescription = sourceText.slice(0, 320);
      let longDescription = sourceText.slice(0, 1800);
      let status = "source_backed";
      if (openAiKey) {
        const aiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
          method: "POST",
          headers: { "Authorization": `Bearer ${openAiKey}`, "Content-Type": "application/json" },
          body: JSON.stringify({
            model: "gpt-4.1-mini",
            temperature: 0.1,
            response_format: { type: "json_object" },
            messages: [
              { role: "system", content: "Türkçe şehir rehberi editörüsün. Yalnızca kaynak metninde desteklenen olguları kullan. Kaynakta olmayan ücret, çalışma saati, ulaşım, tarih veya özellik uydurma. Kaynak yeri doğrulamıyorsa eligible=false döndür. JSON: eligible boolean, short_description string (en fazla 350 karakter), long_description string (600-1800 karakter). Kaynağı kopyalama, dikkatli özetle." },
              { role: "user", content: JSON.stringify({ name: place.name, city: place.city, source_title: sourceTitle, source_url: sourceUrl, source_text: sourceText }) },
            ],
          }),
          signal: AbortSignal.timeout(25000),
        });
        if (aiResponse.ok) {
          const aiJson = await aiResponse.json();
          const raw = aiJson.choices?.[0]?.message?.content;
          if (typeof raw === "string") {
            const generated = JSON.parse(raw);
            if (generated.eligible === true && typeof generated.short_description === "string" &&
                typeof generated.long_description === "string" && generated.short_description.trim().length >= 30 &&
                generated.long_description.trim().length >= 120) {
              shortDescription = generated.short_description.trim().slice(0, 350);
              longDescription = generated.long_description.trim().slice(0, 4000);
              status = "verified";
            }
          }
        }
      }

      const now = new Date().toISOString();
      const { error: updateError } = await client.from("places").update({
        short_description: shortDescription,
        long_description: longDescription,
        source_url: sourceUrl,
        verified_at: now,
        content_updated_at: now,
        content_review_status: status,
        updated_at: now,
      }).eq("id", place.id);
      results.push({ id: place.id, status: updateError ? "database_update_failed" : "updated", source: sourceUrl ?? undefined });
    } catch {
      results.push({ id: place.id, status: "refresh_failed" });
    }
  }

  return json({
    processed: results.length,
    updated: results.filter((item) => item.status === "updated").length,
    results,
    note: "Descriptions are derived from fetched source text; AI enrichment is used only when OPENAI_API_KEY is configured. Missing matches are not fabricated.",
  });
});
