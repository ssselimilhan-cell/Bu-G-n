# BUGÜN yayın hazırlık listesi

## Uygulanan teknik değişiklikler
- [x] Android hedef API 36.
- [x] Android paket kimliği geliştirme dalında `tr.bugun.app` olarak değiştirildi.
- [x] Profilde uygulama içi hesap/veri silme akışı eklendi.
- [x] Supabase `delete-account` Edge Function etkin; kullanıcı kimliği bearer token üzerinden doğrulanıyor.
- [x] Web hesap silme sayfası Supabase Edge Function üzerinde barındırılıyor: https://yvshqvethzbwcgpqaptd.supabase.co/functions/v1/account-deletion-page
- [x] `saved_items` UPDATE RLS politikası eklendi.
- [x] Süresi geçmiş etkinlikleri pasifleştiren RPC'nin doğrudan anon/authenticated tarafından çağrılması engellendi; service_role izni doğrulandı.
- [x] `set_place_location` fonksiyonuna sabit search_path verildi.

## Yayından önce mutlaka tamamlanacaklar
- [ ] Google Play Console'da `tr.bugun.app` paket adının kullanılabilirliğini/registrasyonunu doğrula. Paket kimliği ilk yayından sonra değiştirilmesi zor olduğundan bu kontrol yapılmadan mağazaya gönderme.
- [ ] Android Developer kimlik doğrulaması ve paket adı kayıt gerekliliklerini Play Console'da kontrol et.
- [ ] Üretim imzalama anahtarını güvenli biçimde oluştur ve çevrimdışı yedekle. Anahtarı Git'e koyma.
- [ ] GitHub repository secrets olarak `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` tanımla.
- [ ] Supabase Auth > URL Configuration > Redirect URLs listesine tam adresi ekle: `https://yvshqvethzbwcgpqaptd.supabase.co/functions/v1/account-deletion-page`.
- [ ] Supabase Auth e-posta OTP ayarlarını ve e-posta bağlantısı yönlendirmesini test et.
- [ ] Hesap silmeyi gerçek bir test hesabında uçtan uca doğrula; başarısızlık ve tekrar deneme durumlarını da test et.
- [ ] Supabase güvenlik danışmanındaki sızdırılmış parola koruması ayarını etkinleştirmenin mümkün olup olmadığını kontrol et.
- [ ] Gizlilik/KVKK metnini tamamla. Supabase projesi Londra (eu-west-2) bölgesinde; yurt dışına aktarım için hukuki mekanizma doğrulanmadan yayına çıkma.
- [ ] Veri sorumlusu adı/ünvanı, yayımlanacak iletişim e-postası ve tebligat adresini doğrula.
- [ ] Gizlilik politikasını herkese açık URL'de yayımla ve uygulama içinden erişilebilir yap.
- [ ] Gezilecek yer veri toplama iş akışını doğrula: son denetimde 15 yer / 1 şehir vardı; 81 şehir kapsamı henüz doğrulanmış değil.
- [ ] Son Android APK build + `flutter analyze` başarılı olsun; AAB iş akışını ayrıca manuel çalıştırıp imzalı AAB çıktısını kontrol et.
- [ ] Play Console Data safety formu, içerik derecelendirmesi, ekran görüntüleri, açıklama ve destek bağlantısını tamamla.
- [ ] Android cihazda kayıt, giriş, parola sıfırlama, konum izni, harita, kayıtlı not, etkinlik oluşturma/katılım ve hesap silme uçtan uca testlerini tamamla.

## Önemli
Bu liste teknik hazırlık durumunu gösterir; hukuk danışmanlığı veya mağaza onayı garantisi değildir. Taslak gizlilik metni tamamlanmadan ve yurt dışı aktarım koşulları doğrulanmadan uygulama yayınlanmamalıdır.
