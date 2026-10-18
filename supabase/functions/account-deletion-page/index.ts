import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const html = `<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>BUGÜN – Hesap ve Veri Silme</title>
<style>
:root{font-family:system-ui,-apple-system,"Segoe UI",sans-serif;color-scheme:light}
body{margin:0;background:#f5f5f2;color:#181818}
main{max-width:640px;margin:8vh auto;padding:28px;background:#fff;border-radius:22px;box-shadow:0 8px 32px #0000000d}
h1{margin-top:0;font-size:1.7rem}p,li{line-height:1.6}
label{display:block;margin:18px 0 6px;font-weight:700}
input{box-sizing:border-box;width:100%;padding:13px;border:1px solid #bbb;border-radius:10px;font:inherit}
button{margin-top:14px;padding:13px 18px;border:0;border-radius:10px;background:#181818;color:white;font:inherit;font-weight:700;cursor:pointer}
button:disabled{opacity:.5;cursor:wait}.danger{background:#b42318}
#status{margin-top:16px;padding:12px;background:#f5f5f2;border-radius:10px;white-space:pre-wrap}
#confirm{display:none}small{color:#555}
</style>
</head>
<body><main>
<h1>BUGÜN hesabını ve verilerini sil</h1>
<p>Hesabınla ilişkili verilerin silinmesini istemek için hesabına ait e-posta adresini gir. Sana bir doğrulama bağlantısı gönderilir. Bağlantıyı yalnızca hesabın sahibi açabilir.</p>
<p>Silme işlemi profilini, kayıtlı yerlerini ve notlarını, kişisel etkileşimlerini, hesabına bağlı geri bildirimleri ve oluşturduğun etkinlikleri siler. İşlem geri alınamaz.</p>
<section id="request"><label for="email">Hesap e-posta adresi</label><input id="email" type="email" autocomplete="email" required placeholder="ornek@eposta.com"><button id="send">Doğrulama bağlantısı gönder</button></section>
<section id="confirm"><p>Hesap doğrulandı. Silme işlemini tamamlamak için aşağıdaki düğmeye bas.</p><button id="delete" class="danger">Hesabımı ve verilerimi kalıcı olarak sil</button></section>
<div id="status" role="status" aria-live="polite">Silme işlemi yalnızca doğrulama bağlantısını açan hesap sahibi tarafından tamamlanabilir.</div>
<p><small>BUGÜN hesap silme kaynağı. Talep başarısız olursa uygulama içindeki Profil → Ayarlar → Hesabı ve verileri sil seçeneğini kullanabilirsin.</small></p>
</main>
<script type="module">
import {createClient} from "https://esm.sh/@supabase/supabase-js@2";
const supabase=createClient("https://yvshqvethzbwcgpqaptd.supabase.co","sb_publishable_OEVkps-n_bkL2ykgC1oS_A_A_WK3ppN",{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
const request=document.querySelector("#request"), confirmBox=document.querySelector("#confirm"), status=document.querySelector("#status"), send=document.querySelector("#send"), remove=document.querySelector("#delete");
const setStatus=t=>status.textContent=t;
async function refresh(){const {data,error}=await supabase.auth.getSession();if(error){setStatus("Oturum doğrulanamadı. Yeni doğrulama bağlantısı iste.");return}if(data.session?.user){request.style.display="none";confirmBox.style.display="block";setStatus("E-posta doğrulandı. Silme işlemini sen başlatabilirsin.")}}
send.addEventListener("click",async()=>{const email=document.querySelector("#email").value.trim();if(!email||!email.includes("@")){setStatus("Geçerli bir e-posta adresi gir.");return}send.disabled=true;try{const {error}=await supabase.auth.signInWithOtp({email,options:{shouldCreateUser:false,emailRedirectTo:location.origin+location.pathname}});if(error)throw error;setStatus("Hesabın varsa doğrulama bağlantısı e-posta adresine gönderildi. Gelen kutunu kontrol et.")}catch(_){setStatus("Bağlantı gönderilemedi. Supabase e-posta ve yönlendirme ayarlarını kontrol edip tekrar dene.")}finally{send.disabled=false}});
remove.addEventListener("click",async()=>{if(!confirm("Hesabın ve ilişkili verilerin kalıcı olarak silinecek. Geri alınamaz. Devam edilsin mi?"))return;remove.disabled=true;try{const {error}=await supabase.functions.invoke("delete-account",{method:"POST"});if(error)throw error;await supabase.auth.signOut();request.style.display="none";confirmBox.style.display="none";setStatus("Hesabın ve ilişkili verilerin silindi.")}catch(_){setStatus("Silme işlemi tamamlanamadı. Tekrar dene veya uygulama içinden destek talebi gönder.");remove.disabled=false}});
supabase.auth.onAuthStateChange((_event,session)=>{if(session?.user)refresh()});await refresh();
</script></body></html>`;

Deno.serve((req: Request) => {
  if (req.method !== "GET" && req.method !== "HEAD") {
    return new Response("Method not allowed", { status: 405, headers: { "Allow": "GET, HEAD" } });
  }
  return new Response(req.method === "HEAD" ? null : html, {
    status: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
      "Referrer-Policy": "no-referrer",
      "Content-Security-Policy": "default-src 'self' https://esm.sh https://yvshqvethzbwcgpqaptd.supabase.co; script-src 'self' 'unsafe-inline' https://esm.sh; style-src 'self' 'unsafe-inline'; connect-src https://yvshqvethzbwcgpqaptd.supabase.co https://esm.sh; img-src 'self' data:; base-uri 'none'; frame-ancestors 'none'",
    },
  });
});
