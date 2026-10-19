# BUGÜN — Google Play yayın hazırlığı

Bu belge yayın öncesi teknik ve mağaza adımlarını takip eder. Bir CI derlemesinin başarılı olması, Google Play incelemesinden geçildiği veya uygulamanın kullanıcıya açıklandığı anlamına gelmez.

## Kod tarafında mevcut durum

- Android uygulama kimliği: `tr.bugun.app` — Play Console'da kullanılabilirliği ve kalıcılığı ilk yüklemeden önce doğrulanmalı.
- Hedef SDK: Android 16 / API 36.
- Google Play AAB iş akışı: `.github/workflows/android-aab.yml`.
- Hesap silme web sayfası: `https://yvshqvethzbwcgpqaptd.supabase.co/functions/v1/account-deletion-page`.
- Ayrıntılı KVKK/gizlilik metni hâlâ taslak; hukuk ve gerçek veri akışı kontrolü olmadan yayımlanamaz.
- APK CI iş akışı, derleme ve statik analiz kontrolü yapar. Bu, gerçek Android cihazda uçtan uca testin yerine geçmez.

## AAB imzası için GitHub Actions secrets

GitHub deposu → **Settings → Secrets and variables → Actions** altında aşağıdaki dört repository secret tanımlanmalı. Gizli değerleri kaynak koda veya sohbete koymayın.

- `ANDROID_KEYSTORE_BASE64`: özel olarak oluşturulmuş upload keystore dosyasının Base64 içeriği.
- `ANDROID_KEYSTORE_PASSWORD`: keystore parolası.
- `ANDROID_KEY_ALIAS`: keystore içindeki anahtar takma adı.
- `ANDROID_KEY_PASSWORD`: anahtar parolası.

Upload keystore dosyasının şifreli yedeklerini güvenli çevrimdışı yerde saklayın. Keystore/parolalar kaybolursa gelecekteki güncellemeler zorlaşabilir. Google Play App Signing kullanılsa bile upload key'i koruyun. Daha önce Play'e yüklenmiş bir paket varsa aynı uygulama kimliği ve doğru upload key kullanılmalı.

Secrets tanımlandıktan sonra GitHub → **Actions → BUGUN Google Play AAB → Run workflow** çalıştırılmalı. İş akışı analiz, otomatik test, imza anahtarı doğrulaması ve imzalı `.aab` üretimini kontrol eder.

## Play Console'da tamamlanacak işlemler

- [ ] Play Console geliştirici hesabı ve kimlik/doğrulama adımları tamamlandı.
- [ ] `tr.bugun.app` uygulama kimliği kullanılabilirliği doğrulandı; uygulama oluşturulurken sabitlendi.
- [ ] İmzalı AAB yüklenip Internal testing kanalında gerçek Android cihazlarda test edildi.
- [ ] Mağaza adı, kısa açıklama, tam açıklama ve destek iletişim bilgileri tamamlandı.
- [ ] Uygulama simgesi, telefon ekran görüntüleri ve 1024×500 özellik grafiği hazırlandı.
- [ ] Gizlilik politikası, uygulama içinden de açılabilen, herkese açık ve nihai bir HTTPS URL'sinde yayımlandı.
- [ ] Veri Güvenliği (Data safety) formu, uygulama kodu ve kullanılan servislerin gerçek veri davranışına göre dolduruldu.
- [ ] Hesap silme web URL'si ve uygulama içindeki silme akışı test edildi; ilişkili verilerin silindiği doğrulandı.
- [ ] İçerik derecelendirmesi, hedef kitle, reklam durumu, uygulama erişimi ve gerekli politika beyanları dolduruldu.
- [ ] Mağaza incelemesi için gereken test hesabı/erişim talimatları hazırlandı; gerçek parola veya gizli bilgiler herkese açık metne yazılmadı.
- [ ] Supabase RLS, kullanıcılar arası veri izolasyonu, profil fotoğrafı depolaması ve hesap silme işlevi üretim verisiyle güvenli biçimde test edildi.
- [ ] KVKK aydınlatma metni, saklama süreleri ve yurt dışına veri aktarımı hukuken doğrulandı.

## Yayın engelleri / dikkat

1. `docs/privacy-policy-draft.md` nihai politika değildir. Supabase'in bölgesi, alt işleyenleri, gerçek veri akışı, saklama süreleri ve KVKK aktarım mekanizması doğrulanmadan yayımlamayın.
2. Gizlilik politikasında veri sorumlusu ve iletişim alanları doğru bilgilerle tamamlanmalı. Kişisel ev adresi yerine uygun iş/tebligat adresi veya hukuk danışmanının onayladığı yöntem kullanılmalı.
3. Play Console'daki Data safety cevapları, uygulamanın gerçekten topladığı/verdiği verilerle aynı olmalı; varsayımla işaretlenmemeli.
4. Google Play'e gönderim ve yayın, yalnızca uygulama sahibi Play Console hesabından tamamlanabilir. Bu depo tek başına mağaza yayını yapmaz.
