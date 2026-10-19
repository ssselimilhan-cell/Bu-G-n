# BUGÜN — KVKK Aydınlatma Metni (yayın öncesi taslak)

> **YAYINA ALINAMAZ:** Veri sorumlusu iletişim alanları henüz tamamlanmadı. Gerçek veri akışları, saklama süreleri ve özellikle yurt dışına aktarım mekanizması doğrulanmadan bu metin nihai aydınlatma metni değildir. Yayın öncesinde hukuk uzmanı tarafından kontrol edilmelidir.

## 1. Veri sorumlusu

- **Veri sorumlusu / geliştirici:** [YAYIN ÖNCESİ DOĞRULANACAK]
- **Tebligat / iş adresi:** [YAYIN ÖNCESİ EKLENECEK; EV ADRESİ YAYINLAMAYIN]
- **Gizlilik ve veri talepleri e-posta adresi:** [YAYIN ÖNCESİ DOĞRULANACAK]
- **Başvuru yöntemi:** E-posta veya yukarıdaki posta adresi üzerinden başvuru. Başvurular değerlendirilirken ilgili kişinin kimliği ve başvuru yetkisi, gereğinden fazla veri toplanmadan doğrulanmalıdır.

## 2. İşlenebilecek kişisel veri kategorileri

BUGÜN'ün mevcut işlevlerine göre aşağıdaki veriler işlenebilir:

- **Hesap ve kimlik:** hesap e-posta adresi, profil görünen adı, profil fotoğrafı ve hesap kimliği.
- **Tercihler:** seçilen şehir, ilgi alanları, bütçe/ulaşım/ziyaret süresi tercihleri ve kaydedilen yer/etkinlik notları.
- **Konum:** yalnızca cihaz konum izni verildiğinde yakınlık sıralaması için kullanılan konum verisi. İzin reddedilirse şehir elle seçilebilir.
- **Kullanıcı içeriği:** oluşturulan etkinliklerin başlığı, açıklaması, şehir/yer ve tarih bilgileri; davetler ve katılım kayıtları.
- **İletişim ve güvenlik:** uygulama içi geri bildirim, hata/içerik bildirimleri ve hizmetin güvenli çalışması için hizmet sağlayıcıların tuttuğu teknik kayıtlar.

Uygulamada gerçekten toplanmayan veri kategorileri nihai metinden çıkarılmalıdır. Analitik, reklam, cihaz tanımlayıcıları veya arka planda konum toplama kullanılmıyorsa bunlar varmış gibi gösterilmemelidir.

## 3. Amaçlar

Veriler; hesabı oluşturup yönetmek, kullanıcının seçtiği şehir ve ilgi alanlarına göre etkinlik/yerleri sunmak, kayıtlı öğeleri ve kişisel notları saklamak, kullanıcı tarafından oluşturulan etkinlik ve davet işlevlerini sağlamak, geri bildirimleri yanıtlamak, kötüye kullanımı önlemek ve hizmet güvenliğini sağlamak amacıyla işlenebilir.

## 4. Hukuki sebepler

Her amaç ve veri kategorisi için 6698 sayılı Kanun'un 5'inci maddesindeki uygun işleme şartı, gerçek veri akışına göre belirlenmelidir. Sözleşmenin kurulması/ifası, hukuki yükümlülük veya meşru menfaat şartlarının hangilerinin uygulanacağı varsayılmamalıdır. İsteğe bağlı cihaz konumu ve diğer isteğe bağlı işlemler için ayrı bilgilendirme ve gerekiyorsa uygun izin/açık rıza akışı hukuk incelemesiyle belirlenmelidir. İşletim sistemi konum izni tek başına her durumda KVKK açık rızasının yerine geçmez.

## 5. Alıcılar ve hizmet sağlayıcılar

- Supabase; kimlik doğrulama, veritabanı, dosya depolama ve sunucu işlevleri sağlayıcısıdır.
- Etkinlik/yer bilgileri ve harita görüntüleme için kullanılan kaynaklar, ilgili sayfada kendi hizmet koşulları ve gizlilik açıklamalarıyla birlikte belirtilmelidir.
- Bilet veya dış bağlantı üzerinden yapılan işlemler ilgili üçüncü tarafın kendi hizmetinde gerçekleşebilir.

## 6. Yurt dışına aktarım — yayın öncesi engel

Supabase projesinin birincil bölgesi **eu-west-2 (Londra, Birleşik Krallık)** olarak yapılandırılmıştır. Supabase, bazı hizmet ve alt işleyen faaliyetlerinde verilerin seçilen bölge dışına işlenebileceğini de belirtir. Bu nedenle kişisel veriler için yurt dışına aktarım değerlendirmesi yapılmadan “veriler yalnızca Türkiye'de saklanır” denmemelidir.

Yayından önce 6698 sayılı Kanun'un 9'uncu maddesi ve ilgili yönetmelik uyarınca uygun aktarım mekanizması belirlenmeli; gerekiyorsa KVKK Kurumu tarafından yayımlanan standart sözleşme ilgili taraflarla imzalanmalı ve yasal süresinde bildirilmelidir. Supabase'in mevcut DPA'sının Türkiye mevzuatı bakımından yeterli olduğu varsayılmamalı; sağlayıcıyla ve hukuk uzmanıyla teyit edilmelidir.

## 7. Saklama ve silme

Hesap verileri, hesap hizmeti sürdüğü sürece; kullanıcı tarafından oluşturulan içerikler ise ilgili işlev için gerekli süre boyunca saklanabilir. Hesap silme talebinde, kullanıcıyla ilişkili profil, kayıtlı öğeler/notlar, etkileşimler, geri bildirimler ve oluşturulan etkinlikler silinmek üzere tasarlanmıştır. Yedekler, güvenlik kayıtları ve mevzuat gereği tutulması gereken kayıtlar için gerçek sağlayıcı süreleri ve olası istisnalar ayrıca belirlenip açıklanmalıdır. Tamamlanmış bir silme işlemi test edilmeden “bütün kopyalar anında ve kesin olarak silinir” taahhüdü verilmemelidir.

## 8. İlgili kişinin hakları ve başvuru

İlgili kişiler, 6698 sayılı Kanun'un 11'inci maddesindeki hakları kapsamında veri sorumlusuna başvurabilir. Başvurular yukarıda belirtilen e-posta veya posta adresi üzerinden iletilebilir. Hesap silme talebi uygulama içindeki **Profil → Hesabı ve verileri sil** seçeneğiyle veya şu web sayfasından başlatılabilir:

https://yvshqvethzbwcgpqaptd.supabase.co/functions/v1/account-deletion-page

## 9. Son kontrol listesi

Bu metin yayımlanmadan önce her işleme amacının hukuki sebebi, saklama süreleri, alt işleyenler, yurt dışına aktarım mekanizması, başvuru süreci ve uygulamanın gerçek izin/SDK davranışı doğrulanmalıdır. Bu metin, teknik ve hukuki doğrulama tamamlanana kadar taslak olarak kalmalıdır.
