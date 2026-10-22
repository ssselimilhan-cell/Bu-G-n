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
