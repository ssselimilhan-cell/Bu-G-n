import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "GET") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const apiKey = Deno.env.get("TMDB_API_READ_ACCESS_TOKEN");
  if (!apiKey) {
    return new Response(JSON.stringify({
      error: "TMDB_API_READ_ACCESS_TOKEN secret is not configured in Supabase.",
      code: "TMDB_NOT_CONFIGURED",
    }), {
      status: 503,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const url = new URL(req.url);
  const pageRaw = Number(url.searchParams.get("page") ?? "1");
  const page = Number.isFinite(pageRaw) ? Math.min(5, Math.max(1, Math.floor(pageRaw))) : 1;
  const category = url.searchParams.get("category") === "upcoming" ? "upcoming" : "now_playing";
  const tmdbUrl = new URL(`https://api.themoviedb.org/3/movie/${category}`);
  tmdbUrl.searchParams.set("language", "tr-TR");
  tmdbUrl.searchParams.set("region", "TR");
  tmdbUrl.searchParams.set("page", String(page));

  try {
    const response = await fetch(tmdbUrl, {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        accept: "application/json",
      },
    });
    const body = await response.text();
    return new Response(body, {
      status: response.status,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
        "Cache-Control": "public, max-age=900",
      },
    });
  } catch {
    return new Response(JSON.stringify({ error: "TMDB API request failed." }), {
      status: 502,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
