import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const packageId = "tr.bugun.app";
const storeUrl = "https://play.google.com/store/apps/details?id=" + packageId;

function escapeHtml(value: unknown): string {
  return String(value ?? "").replace(/[&<>"']/g, (char) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  }[char] ?? char));
}

function html(body: string, status = 200): Response {
  return new Response(body, {
    status,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
      "Referrer-Policy": "no-referrer",
    },
  });
}

Deno.serve(async (req: Request) => {
  const requestUrl = new URL(req.url);
  const code = (requestUrl.searchParams.get("code") ?? "").trim().toLowerCase();
  if (!/^[a-f0-9]{8,32}$/.test(code)) {
    return html("<!doctype html><html lang='tr'><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>BUGÜN daveti</title><body style='font-family:system-ui;max-width:560px;margin:12vh auto;padding:24px'><h1>Geçersiz davet bağlantısı</h1><p>Arkadaşından yeni bir davet bağlantısı istemelisin.</p><a href='" + storeUrl + "'>BUGÜN'ü Google Play'de aç</a></body></html>", 400);
  }

  const endpoint = new URL(supabaseUrl + "/rest/v1/community_activities");
  endpoint.searchParams.set("select", "title,description,city,venue,address,starts_at,activity_type,is_free,estimated_cost,status,invite_code");
  endpoint.searchParams.set("invite_code", "eq." + code);
  endpoint.searchParams.set("status", "eq.open");
  endpoint.searchParams.set("limit", "1");

  const result = await fetch(endpoint, {
    headers: { apikey: anonKey, Authorization: "Bearer " + anonKey },
  });
  if (!result.ok) {
    return html("<!doctype html><html lang='tr'><meta charset='utf-8'><body style='font-family:system-ui;max-width:560px;margin:12vh auto;padding:24px'><h1>Davet şu anda açılamıyor</h1><p>Lütfen biraz sonra tekrar dene.</p></body></html>", 503);
  }
  const rows = await result.json();
  const activity = rows?.[0];
  if (!activity) {
    return html("<!doctype html><html lang='tr'><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Etkinlik bulunamadı · BUGÜN</title><body style='font-family:system-ui;max-width:560px;margin:12vh auto;padding:24px'><h1>Bu etkinlik bulunamadı</h1><p>Davet kapanmış veya bağlantının süresi dolmuş olabilir.</p><a href='" + storeUrl + "'>BUGÜN'ü Google Play'de aç</a></body></html>", 404);
  }

  const title = escapeHtml(activity.title);
  const description = escapeHtml(activity.description);
  const city = escapeHtml(activity.city);
  const venue = escapeHtml(activity.venue);
  const address = escapeHtml(activity.address);
  const type = escapeHtml(activity.activity_type);
  const date = escapeHtml(new Intl.DateTimeFormat("tr-TR", {
    dateStyle: "full", timeStyle: "short", timeZone: "Europe/Istanbul"
  }).format(new Date(activity.starts_at)));
  const cost = activity.is_free ? "Ücretsiz" :
    (activity.estimated_cost == null ? "Ücret belirtilmedi" : "Kişi başı yaklaşık ₺" + escapeHtml(activity.estimated_cost));
  const appLink = "bugun://invite?code=" + encodeURIComponent(code);
  const fallbackStore = storeUrl + "&referrer=" + encodeURIComponent("invite_code=" + code);
  const intentLink = "intent://invite?code=" + encodeURIComponent(code) +
    "#Intent;scheme=bugun;package=" + packageId +
    ";S.browser_fallback_url=" + encodeURIComponent(fallbackStore) + ";end";

  return html(`<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,nofollow">
<meta name="theme-color" content="#f7f7f5">
<title>${title} · BUGÜN daveti</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#f7f7f5;color:#171717;font-family:system-ui,-apple-system,sans-serif}
main{max-width:560px;margin:0 auto;padding:24px 18px 40px}.brand{font-weight:900;letter-spacing:-1px;font-size:26px;margin:12px 0 26px}
.card{background:white;border:1px solid #e7e7e2;border-radius:24px;padding:24px;box-shadow:0 8px 28px #00000008}
.eyebrow{font-size:12px;letter-spacing:1.3px;font-weight:800;color:#65665f;text-transform:uppercase}
h1{font-size:30px;line-height:1.08;letter-spacing:-.7px;margin:8px 0 18px}
.detail{padding:10px 0;border-bottom:1px solid #efefeb}.detail:last-child{border:0}
p{line-height:1.55;color:#4d4d48}.btn{display:block;text-align:center;text-decoration:none;border-radius:14px;padding:15px 18px;font-weight:800;margin-top:12px}
.primary{background:#171717;color:white}.secondary{border:1px solid #d7d7d0;color:#171717}
.code{background:#f1f2ed;border-radius:12px;padding:12px;text-align:center;font-weight:900;letter-spacing:2px;margin-top:16px}
small{display:block;text-align:center;color:#777;margin-top:16px}
</style></head>
<body><main><div class="brand">BUGÜN</div><section class="card">
<div class="eyebrow">${type} · Etkinlik daveti</div><h1>${title}</h1>
<div class="detail">📅 ${date}</div><div class="detail">📍 ${city}${venue ? " · " + venue : ""}</div>
${address ? '<div class="detail">🗺️ ' + address + '</div>' : ""}
<div class="detail">🎟️ ${escapeHtml(cost)}</div>
${description ? "<p>" + description + "</p>" : ""}
<p>Bir arkadaşın seni BUGÜN üzerinden davet etti. Etkinlik ayrıntılarını uygulamada açıp katılımını bildirebilirsin.</p>
<a class="btn primary" href="${intentLink}">BUGÜN uygulamasında aç</a>
<a class="btn secondary" href="${fallbackStore}">Uygulama yok mu? Google Play'den indir</a>
<div class="code">Davet kodu: ${escapeHtml(code.toUpperCase())}</div>
<small>Kurulumdan sonra davet kodunu kullanmak için bu sayfaya geri dönebilirsin.</small>
</section></main>
<script>
document.querySelector('.primary').addEventListener('click', function() {
  setTimeout(function(){}, 800);
});
</script></body></html>`);
});
