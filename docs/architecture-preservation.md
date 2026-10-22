# BUGÜN — mevcut mimariyi koruma notu

## Değişiklik kuralı
- Çalışan ekranlar yeniden tasarlanmaz; yeni özellikler mevcut akışlara eklenir.
- Ana gezinme, renkler, logo, şehir seçimi, Bugün sekmesinin tarih filtresi ve mevcut öneri akışı korunur.
- Etkinlikler `public.events` + `EventService`; yerler `public.places` + `PlaceService`; şehir tercihi `CityPreferenceService` üzerinden okunur/yazılır.
- Yeni ekranlar doğrudan tabloya dağınık sorgular eklemek yerine mevcut servis/veri modelini izlemeli.
- Gerçek kaynak verisi yoksa uydurma kayıt gösterilmez; boş durum açıkça anlatılır.

## Şehir fırsatları
- Kullanıcılar Keşfet > Fırsatlar sekmesinden yayındaki fırsatları okuyabilir.
- Yeni fırsat ekleme/düzenleme/silme yalnızca Supabase Auth `app_metadata.role = 'admin'` yetkisiyle RLS tarafından kabul edilir. Ekrandaki gizleme yalnızca kullanıcı deneyimidir; asıl güvenlik veritabanı politikalarıdır.
- BUGÜN yöneticisi `ssselimilhan@gmail.com` hesabına `role=admin` app metadata değeri atanmıştır. Yeni JWT almak için uygulamada oturumu kapatıp yeniden açmak gerekir.
- Fırsat tablosu: `public.offers`; güvenlik ve topluluk etkinliği tabloları: `supabase/migrations/011_city_offers_and_community_events.sql`.

## Birlikte etkinlik / davet
- Keşfet > Birlikte sekmesi `public.community_events` tablosunu kullanır.
- Oluşturulan davet kodu veritabanında saklanır, sonradan görüntülenip kopyalanabilir.
- Etkinlik oluşturmak için giriş gerekir. RLS, kullanıcının yalnızca kendi oluşturduğu etkinliği değiştirmesine izin verir.

## Veri kaynakları ve sınırlar
- Yer/etkinlik verileri Supabase'ten gelir; şehir filtresi mevcut şehir tercihine bağlıdır.
- Sinema katalog tabloları `cinema_venues`, `cinema_movies`, `cinema_screenings` olarak ayrıdır. Şu anda canlı veritabanında bu tablolarda sinema salonu/seans kaydı bulunmadığı için seanslar gösterilemez. Gerçek seanslar için lisanslı/resmî bir veri sağlayıcısı veya doğrulanmış veri aktarımı bağlanmalıdır; sahte seans üretilmemelidir.
- Özellik dalı `restore-core-features` üzerinde APK derlemesi ve `flutter analyze` çalıştıran doğrulama iş akışı bulunur.


## 2026-10-22 bağlantı ve sinema kontrolü
- Flutter uygulamasındaki `AppConfig` varsayılan URL'si `https://yvshqvethzbwcgpqaptd.supabase.co`; kontrol edilen Supabase projesiyle eşleşiyor.
- Supabase'te `public.places` tablosunda 2.985 kayıt var ve sorgulanan şehirlerde `is_active=true` kayıtları mevcut (ör. Ankara 97, Adana 43). `public.events` tablosunda da aktif ve ileri tarihli etkinlikler mevcut (ör. Ankara 204, Adana 42). `places` ve `events` için anon/authenticated SELECT politikaları yalnızca aktif kayıtları okumaya izin veriyor. Bu, veritabanında veri bulunduğunu ve uygulama yapılandırmasının doğru projeye işaret ettiğini doğrular; gerçek Android cihazdaki ağ isteği ayrıca cihazda çalıştırılarak doğrulanmalıdır.
- Sinema tabloları canlı veritabanında boş: `cinema_venues=0`, `cinema_movies=0`, `cinema_screenings=0`. Dolayısıyla sinema ekranının boş olmasının doğrudan nedeni veri aktarımının/sağlayıcı bağlantısının henüz kurulmamasıdır; Supabase bağlantısı genel olarak yanlış projeye gitmiyor.
- Araştırmada TMDB, film kataloğu/görsel API'si sunuyor; ücretsiz kullanım ticari olmayan projeler ve atıf koşullarıyla sınırlı, ticari kullanım için lisans görüşmesi gerekiyor. TMDB film katalog API'si Türkiye'deki gerçek sinema seanslarının kaynağı değildir. Paribu Cineverse resmî sitesinde güncel seanslar yayınlanıyor ancak kamuya açık, lisanslı bir seans API'si doğrulanamadı. Uygulamaya resmî Paribu Cineverse sitesine yönlendirme eklendi; izinsiz site API'si kazınmıyor. Uygulama içinde otomatik seans göstermek için sağlayıcıdan yazılı veri/API izni ve kimlik bilgileri gerekir.


## TMDB entegrasyonu ve zorunlu bilgilendirme (2026-10-22)
- Supabase Edge Function `tmdb-cinema` canlı projeye dağıtıldı. API Read Access Token istemciye gömülmez; `TMDB_API_READ_ACCESS_TOKEN` adıyla Supabase Edge Function Secret olarak ayarlanmalıdır. Secret ayarlanana kadar fonksiyon `TMDB_NOT_CONFIGURED` / HTTP 503 döndürür.
- Fonksiyon TMDB v3 `/movie/now_playing` uç noktasını `language=tr-TR`, `region=TR` parametreleriyle çağırır; sayfa parametresi 1-5 aralığında sınırlandırılır ve API token sunucu tarafında kalır.
- Flutter Sinema ekranı TMDB kataloğundan Türkiye'de vizyondaki film başlığı, vizyon tarihi, özet ve afişleri göstermeyi dener. Bu, şehir bazlı sinema salonu veya gerçek seans saati verisi değildir; bu ayrım kullanıcıya açıkça belirtilir.
- Profil > Hakkında ve veri kaynakları bölümüne TMDB atıf metni ve resmi atıf koşulları bağlantısı eklendi. Sinema ekranında da bildirim gösterilir. TMDB'nin resmi koşulları ayrıca onaylı TMDB logosunun uygulamada kullanılmasını ve şu metnin görünür olmasını ister: `This product uses the TMDB API but is not endorsed or certified by TMDB.` Logo varlığı henüz repoya eklenmediği için logo şartı tamamlanmış sayılmaz; TMDB'nin resmi logo/atıf sayfasından uygun varlık alınarak uygulamanın Hakkında bölümüne eklenmelidir.
- TMDB geliştirici API'si ücretsiz ancak yalnızca ticari olmayan kullanım ve kaynak atfı koşullarıyla sunulur. Uygulamanın temel amacı gelir elde etmekse ticari lisans için TMDB ile iletişime geçilmelidir. Kaynak: https://developer.themoviedb.org/docs/faq
- TMDB, Türkiye'deki gerçek sinema seans saatlerinin kaynağı değildir. Gerçek seans entegrasyonu için sinema işletmecisi/dağıtıcıdan ayrı ve uygun lisanslı bir kaynak gerekir.
- API limitlerinde HTTP 429 yanıtına uyulmalı; TMDB dokümanındaki yaklaşık 40 istek/saniye üst sınırı değişebilir, gereksiz toplu istek yapılmamalıdır. Kaynak: https://developer.themoviedb.org/docs/rate-limiting
- Kurulum: Supabase Dashboard > Edge Functions > Secrets > Add new secret; name `TMDB_API_READ_ACCESS_TOKEN`, value TMDB hesabındaki API Settings > API Read Access Token. Bu değer uygulama koduna, GitHub'a veya istemciye eklenmemelidir.
