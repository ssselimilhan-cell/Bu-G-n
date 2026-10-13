# BUGÜN — Codespaces / Android

Flutter tabanlı şehir keşif uygulaması. Supabase, etkinlik ve mekân verileri, şehir tercihi ve kullanıcı profiliyle çalışır.

## GitHub Codespaces'te açma

1. GitHub'da `bugun-codespaces-ready` dalını açın.
2. **Code → Codespaces → Create codespace on bugun-codespaces-ready** seçin.
3. Terminalde bağımlılıkları alın:

   ```bash
   flutter pub get
   ```

4. Android APK oluşturun:

   ```bash
   flutter build apk --release
   ```

5. APK dosyası `build/app/outputs/flutter-apk/app-release.apk` yolunda oluşur.

Linux masaüstü hedefi yerine Android APK hedefi kullanılır. Codespaces Android emülatörünü otomatik sağlamaz; APK'yı telefona indirip kurabilirsiniz.

## Otomatik APK derlemesi

GitHub Actions bu dala push yapıldığında APK derler. Workflow tamamlandığında **Actions → Android APK → Artifacts → bugun-android-release** yolundan alabilirsiniz. Workflow ayrıca elle çalıştırılabilir.

## Supabase yapılandırması

Uygulama mevcut Supabase proje URL'si ve istemci publishable key'iyle `lib/core/config.dart` dosyasında yapılandırılmıştır. Başka ortama geçerken `SUPABASE_URL` ve `SUPABASE_ANON_KEY` dart-define'ları kullanılabilir:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

İstemci anahtarı gizli servis rolü anahtarı değildir. Supabase service-role key uygulamaya veya repoya kesinlikle eklenmemelidir. Veritabanı erişimi RLS politikalarıyla korunmalıdır.

## Şehir tercihi

Profil ekranından Türkiye'nin 81 ili aranıp seçilebilir. Misafir kullanıcının tercihi cihazda, oturum açmış kullanıcının tercihi profilde ve cihazda saklanır. Ana sayfa ve keşif ekranı şehir tercihini kullanarak etkinlik ve mekân sorgularını filtreler.

## Not

Canlı içeriklerin görünmesi Supabase veritabanındaki etkinlik/mekân kayıtlarının güncelliğine ve seçilen şehir adıyla eşleşmesine bağlıdır. Dış veri sağlayıcılarının API anahtarları ve arka plan veri toplama servisleri ayrıca yapılandırılmalıdır.

## Supabase güvenlik migration'ı

Bu geliştirme dalında `supabase/migrations/008_user_data_security.sql` dosyası da bulunur. Mevcut Supabase projesinde tablolar için daha önce RLS politikaları çalıştırıldıysa bu dosya, aynı kullanıcı-verisi izolasyonunu proje deposunda sürümlü ve tekrar kurulabilir hale getirir. Yeni bir veritabanı kurulumunda migration dosyalarını sırayla uygulayın; migration'ları uygulamadan hesaplara ait kayıtları bulut üzerinde saklama özelliğinin çalıştığını varsaymayın.

## Kullanıcı kayıtları ve gizlilik

- Misafir kayıtları cihazdaki uygulama tercihleri içinde tutulur.
- Oturum açılmış kullanıcıların kaydedilmiş etkinlikleri ve mekânları `saved_items` tablosunda kullanıcı kimliğiyle saklanır.
- Profil, kaydedilen öğeler ve etkileşim kayıtları için RLS kullanıcıya göre erişimi sınırlar.
- Bildirim izni kullanıcı isteğiyle istenir. Gerçek push bildirimi göndermek için ayrıca sunucu/FCM kurulumu gerekir; izin verilmesi tek başına bildirim gönderimi sağlamaz.
- Yayına çıkmadan önce işletmeci bilgileri ve saklama süreleri içeren gerçek KVKK aydınlatma metni/Gizlilik Politikası hazırlanmalıdır.