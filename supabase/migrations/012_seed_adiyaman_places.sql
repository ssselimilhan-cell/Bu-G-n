-- BUGÜN: Adıyaman'ın temel kültür ve doğa rotası.
insert into public.places
  (name, category, place_type, city, address, latitude, longitude, slug,
   short_description, long_description, source_url, external_source, external_id,
   verified, trust_score, is_active, content_review_status, tags)
select v.name, v.category, v.place_type, 'Adıyaman', v.address, v.lat, v.lon, v.slug,
       v.short_description, v.long_description, v.source_url, 'curated_seed',
       'adiyaman-' || v.slug, false, 75, true, 'source_backed', v.tags::jsonb
from (values
 ('Nemrut Dağı Ören Yeri','Tarih','UNESCO Dünya Mirası / ören yeri','Kahta, Adıyaman',37.9800::float8,38.7400::float8,'nemrut-dagi-oren-yeri','Anıtsal heykelleri ve gün doğumu manzarasıyla Türkiye’nin en tanınmış arkeolojik alanlarından.','Kommagene Krallığı dönemine ait tümülüs ve dev heykelleriyle öne çıkar; yüksek rakım ve mevsim koşulları için ziyaret öncesi ulaşım durumunu kontrol edin.','https://whc.unesco.org/en/list/448/','["UNESCO","arkeoloji","tarih","manzara"]'),
 ('Cendere Köprüsü','Tarih','Roma dönemi köprüsü','Kahta, Adıyaman',37.9330::float8,38.6200::float8,'cendere-koprusu','Roma döneminden kalma anıtsal taş köprü.','Kahta çevresinde Nemrut rotasıyla birlikte görülebilen önemli Roma dönemi mühendislik yapısı.','https://tr.wikipedia.org/wiki/Cendere_K%C3%B6pr%C3%BCs%C3%BC','["Roma","köprü","tarih"]'),
 ('Arsemia Antik Kenti','Tarih','Antik kent','Kahta, Adıyaman',37.9300::float8,38.6500::float8,'arsemia-antik-kenti','Kommagene Krallığı’nın önemli yerleşim ve kült alanlarından.','Kayaya oyulmuş yapıları ve tarihî kalıntılarıyla Nemrut çevresindeki arkeolojik gezi rotasının parçasıdır.','https://tr.wikipedia.org/wiki/Arsemia','["arkeoloji","antik kent","Kommagene"]'),
 ('Karakuş Tümülüsü','Tarih','Tümülüs','Kahta, Adıyaman',37.8500::float8,38.6000::float8,'karakus-tumulusu','Kommagene hanedanıyla ilişkili anıt mezar alanı.','Kahta çevresindeki Kommagene kültürel mirasının önemli duraklarından biridir.','https://tr.wikipedia.org/wiki/Karaku%C5%9F_T%C3%BCm%C3%BCl%C3%BCs%C3%BC','["arkeoloji","tümülüs","tarih"]'),
 ('Adıyaman Müzesi','Müze','Arkeoloji müzesi','Merkez, Adıyaman',37.7640::float8,38.2760::float8,'adiyaman-muzesi','Bölgenin arkeolojik buluntularını ve kültürel geçmişini tanıtan müze.','Nemrut ve Kommagene alanlarını gezmeden önce veya sonra bölgenin tarihini anlamak için iyi bir başlangıç noktasıdır.','https://muze.gov.tr/','["müze","arkeoloji","tarih"]'),
 ('Perre Antik Kenti','Tarih','Antik kent ve kaya mezarları','Merkez, Adıyaman',37.7900::float8,38.2500::float8,'perre-antik-kenti','Kaya mezarları ve antik yerleşim kalıntılarıyla bilinen arkeolojik alan.','Kommagene bölgesinin önemli antik yerleşimlerinden biri olan Perre, kaya mezarlarıyla dikkat çeker.','https://tr.wikipedia.org/wiki/Perre','["arkeoloji","kaya mezarı","antik kent"]'),
 ('Yeni Kale','Tarih','Kale','Kahta, Adıyaman',37.9300::float8,38.6500::float8,'yeni-kale-adiyaman','Kahta Çayı vadisine hâkim tarihî kale.','Nemrut ve Cendere çevresindeki tarih rotasına eklenebilecek savunma yapısı kalıntılarıdır.','https://tr.wikipedia.org/wiki/Yeni_Kale_(Ad%C4%B1yaman)','["kale","tarih","manzara"]'),
 ('Atatürk Barajı Seyir Noktası','Doğa','Baraj ve manzara','Samsat çevresi, Adıyaman',37.5800::float8,38.5000::float8,'ataturk-baraji-seyir-noktasi','Türkiye’nin büyük baraj göllerinden birinin manzarasını izlemek için bölgesel durak.','Baraj gölü çevresindeki manzara noktaları için güncel erişim ve güvenlik koşullarını yerinde kontrol edin.','https://tr.wikipedia.org/wiki/Atat%C3%BCrk_Baraj%C4%B1','["baraj","manzara","doğa"]'),
 ('Gölbaşı Gölleri Tabiat Parkı','Doğa','Göller ve tabiat parkı','Gölbaşı, Adıyaman',37.7900::float8,37.6400::float8,'golbasi-golleri-tabiat-parki','Göller, sulak alan ve kuş yaşamıyla öne çıkan doğal alan.','Adıyaman’ın batısında doğa gözlemi ve açık hava gezileri için değerlendirilebilecek bölgedir.','https://www.tarimorman.gov.tr/DKMP','["göl","doğa","kuş gözlemi"]'),
 ('Besni Sofraz Anıtı','Tarih','Roma dönemi anıt mezarı','Besni, Adıyaman',37.6500::float8,37.9000::float8,'besni-sofraz-aniti','Sofraz çevresinde bulunan Roma dönemi anıt mezarı.','Besni çevresinin tarihî mirasını keşfetmek isteyenler için arkeolojik bir duraktır.','https://tr.wikipedia.org/wiki/Sofraz_An%C4%B1t_Mezar%C4%B1','["arkeoloji","Roma","tarih"]')
) as v(name,category,place_type,address,lat,lon,slug,short_description,long_description,source_url,tags)
where not exists (
 select 1 from public.places p
 where lower(trim(p.city))='adiyaman'
   and (lower(trim(p.name))=lower(trim(v.name)) or p.slug=trim(v.slug))
);