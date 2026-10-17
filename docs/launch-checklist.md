# BUGÜN yayın hazırlık listesi

## Doğrulanmış teknik durum
- [x] Android release APK derlemesi başarılı; `flutter analyze --no-pub` ve `flutter build apk --release` tamamlandı. [Son derleme ve APK artifact'i](https://github.com/ssselimilhan-cell/Bu-G-n/actions/runs/38522171486). Bu APK, Play için imzalı AAB yerine geçmez.
- [x] Android hedef API 36.
- [x] Android paket kimliği geliştirme dalında `tr.bugun.app` olarak değiştirildi.
- [x] Profilde uygulama içi hesap/veri silme akışı eklendi.
- [x] Supabase `delete-account` Edge Function etkin; kullanıcı kimliği bearer token üzerinden doğrulanıyor.
- [x] Web hesap silme sayfası Supabase Edge Function üzerinde barındırılıyor: https://yvshqvethzbwcgpqaptd.supabase.co/functions/v1/account-deletion-page
- [x] Hesap silme sayfası v2'de oturum durumu işleme akışı iyileştirildi.
- [x] `saved_items` UPDATE RLS politikası eklendi.
- [x] Süresi geçmiş etkinlikleri pasifleştiren RPC'nin doğrudan anon/authenticated tarafından çağrılması engellendi; service_role izni doğrulandı.
- [x] `set_place_location` fonksiyonuna sabit search_path verildi.
- [x] Veri sorumlusu iletişim bilgileri, kullanıcının açık talebi doğrultusunda gizlilik taslağına eklendi.
- [x] Ticketmaster Türkiye senkronizasyonu doğrulandı: 2.358 toplam etkinlik kaydı; 2.079 gelecekteki aktif etkinlik, 66 şehir. Geçmiş etkinlikler pasifleştirildi. Kaynak URL ve görsel alanları dolu; 70 gelecekteki etkinlikte koordinat eksik.
- [x] Gezilecek yer kolektörünün Supabase upsert çakışma indeksi düzeltildi; OpenStreetMap kolektörü genişletildi ve çalıştırıldı.
- [ ] Gezilecek yer aktarımının tamamlanmasını ve 81 il genelindeki kayıt sayısı/şehir dağılımını doğrula. Ara kontrolde 81 yer vardı: 15 Ankara kaydı ve 66 OpenStreetMap kaydı İzmir'de; yeni 81 il taraması hâlâ çalışıyor ve henüz tamamlanmış sayılmıyor.

## Yayından önce mutlaka tamamlanacaklar
- [ ] Google Play Console'da `tr.bugun.app` paket adının kullanılabilirliğini/registrasyonunu doğrula. Paket kimliği ilk yayından sonra değiştirilmesi zor olduğundan bu kontrol yapılmadan mağazaya gönderme.
- [ ] Android Developer kimlik doğrulaması ve paket adı kayıt gerekliliklerini Play Console'da kontrol et.
- [ ] Üretim imzalama anahtarını güvenli biçimde oluştur ve çevrimdışı yedekle. Anahtarı Git'e koyma.
- [ ] GitHub repository secrets olarak `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` tanımla.
- [ ] AAB iş akışını manuel çalıştırıp imzalı AAB çıktısını ve imzalama sertifikasını kontrol et.
- [ ] Supabase Auth > URL Configuration > Redirect URLs listesine tam adresi ekle: `https://yvshqvethzbwcgpqaptd.supabase.co/functions/v1/account-deletion-page`.
- [ ] Supabase Auth e-posta OTP ayarlarını ve e-posta bağlantısı yönlendirmesini test et.
- [ ] Hesap silmeyi gerçek bir test hesabında uçtan uca doğrula; profil, avatar dosyaları, kayıtlar/notlar, geri bildirim, etkinlikler, davetler ve Auth hesabının silindiğini kontrol et. Başarısızlık ve tekrar deneme durumlarını da test et.
- [ ] Supabase güvenlik danışmanında görülen PostGIS `spatial_ref_sys` RLS uyarısını ve PostGIS fonksiyon izinlerini kontrollü şekilde değerlendir; uzantı sahipliği nedeniyle zorlayıcı değişiklik yapma.
- [ ] Supabase Auth'ta sızdırılmış parola korumasını etkinleştir.
- [ ] Gizlilik/KVKK metnini tamamla. Supabase projesi Londra (eu-west-2) bölgesinde; yurt dışına aktarım için hukuki mekanizma doğrulanmadan yayına çıkma.
- [ ] Uygulamanın gerçek veri akışlarını, işleme amaçlarını/hukuki sebeplerini, saklama sürelerini ve alt işleyenlerini doğrula; gizlilik metnini hukuk uzmanına kontrol ettir.
- [ ] Gizlilik politikasını nihai hale getirip herkese açık URL'de yayımla ve uygulama içinden erişilebilir yap. Mevcut `docs/privacy-policy-draft.md` yalnızca taslaktır, nihai politika olarak sunulmamalıdır.
- [ ] Gezilecek yer kolektörü tamamlandıktan sonra kayıtların ad, koordinat, kategori ve mükerrer kontrolünü yap; OSM kaynak atfını uygulamada görünür hale getir. 81 il kapsamı henüz doğrulanmadı.
- [ ] Play Console Data safety formu, içerik derecelendirmesi, ekran görüntüleri, açıklama ve destek bağlantısını tamamla.
- [ ] Android cihazda kayıt, giriş, parola sıfırlama, konum izni, harita, kayıtlı not, etkinlik oluşturma/katılım ve hesap silme uçtan uca testlerini tamamla.

## Önemli
Bu liste teknik hazırlık durumunu gösterir; hukuk danışmanlığı veya mağaza onayı garantisi değildir. Gizlilik metni tamamlanmadan, yurt dışı aktarım koşulları doğrulanmadan, imzalı AAB üretilmeden ve hesap silme akışı test edilmeden uygulama yayınlanmamalıdır.
