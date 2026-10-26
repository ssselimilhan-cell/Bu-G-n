-- BUGÜN: Ağrı'nın temel kültür ve doğa rotası.
insert into public.places
  (name, category, place_type, city, address, latitude, longitude, slug,
   short_description, long_description, source_url, external_source, external_id,
   verified, trust_score, is_active, content_review_status, tags)
select v.name, v.category, v.place_type, 'Ağrı', v.address, v.lat, v.lon, v.slug,
       v.short_description, v.long_description, v.source_url, 'curated_seed',
       'agri-' || v.slug, false, 75, true, 'source_backed', v.tags::jsonb
from (values
 ('Ağrı Dağı Milli Parkı','Doğa','Milli park ve dağ','Doğubayazıt, Ağrı',39.7000::float8,44.3000::float8,'agri-dagi-milli-parki','Türkiye’nin en yüksek dağı çevresinde etkileyici dağ manzaraları.','Ağrı Dağı ve çevresindeki doğal alanlar milli park kapsamında değerlendirilir; dağcılık ve yüksek irtifa faaliyetleri izin, hava ve güvenlik koşullarına bağlıdır.','https://www.tarimorman.gov.tr/DKMP','["dağ","milli park","doğa"]'),
 ('İshak Paşa Sarayı','Tarih','Osmanlı saray kompleksi','Doğubayazıt, Ağrı',39.5170::float8,44.1280::float8,'ishak-pasa-sarayi','Doğu Anadolu’nun en tanınmış tarihî mimari eserlerinden biri.','Osmanlı döneminden kalma saray kompleksi, taş işçiliği ve dağlık çevresiyle Ağrı’nın başlıca ziyaret noktasıdır.','https://tr.wikipedia.org/wiki/%C4%B0shak_Pa%C5%9Fa_Saray%C4%B1','["tarih","mimari","saray"]'),
 ('Ahmed-i Hani Türbesi','Kültür','Türbe ve ziyaret yeri','Doğubayazıt, Ağrı',39.5200::float8,44.1300::float8,'ahmed-i-hani-turbesi','İshak Paşa Sarayı yakınında yer alan kültürel ziyaret noktası.','Bölgenin düşünce ve edebiyat tarihiyle ilişkilendirilen Ahmed-i Hani’nin türbesi, saray gezisiyle birlikte ziyaret edilir.','https://tr.wikipedia.org/wiki/Ahmed-i_Hani','["kültür","tarih","ziyaret"]'),
 ('Doğubayazıt Eski Bayezid Camii','Tarih','Tarihî cami','Doğubayazıt, Ağrı',39.5200::float8,44.1300::float8,'dogubayazit-eski-bayezid-camii','Eski Bayezid yerleşimindeki tarihî dini yapı.','İshak Paşa Sarayı çevresindeki tarihî yerleşim dokusunu keşfederken değerlendirilebilecek bir duraktır.','https://tr.wikipedia.org/wiki/Do%C4%9Fubayaz%C4%B1t','["tarih","mimari","kültür"]'),
 ('Meteor Çukuru','Doğa','Jeolojik oluşum','Doğubayazıt, Ağrı',39.4500::float8,44.3700::float8,'meteor-cukuru-agri','Türkiye-İran sınırına yakın bölgede tanınan büyük meteor çukuru.','Doğubayazıt çevresinde yer alan jeolojik oluşum, bölgedeki doğa gezilerinde ziyaret edilen noktalardandır; sınır bölgesi erişim koşulları kontrol edilmelidir.','https://tr.wikipedia.org/wiki/Meteor_%C3%A7ukuru','["jeoloji","doğa","manzara"]'),
 ('Balık Gölü','Doğa','Krater gölü','Taşlıçay, Ağrı',40.0400::float8,42.9000::float8,'balik-golu-agri','Yüksek rakımlı doğal göl ve çevresindeki dağ manzarası.','Ağrı’nın Taşlıçay çevresindeki yüksek rakımlı gölü, doğa ve fotoğraf gezileri için bilinen duraklardandır.','https://tr.wikipedia.org/wiki/Bal%C4%B1k_G%C3%B6l%C3%BC','["göl","doğa","fotoğraf"]'),
 ('Diyadin Kaplıcaları','Termal','Kaplıca ve jeotermal alan','Diyadin, Ağrı',39.5400::float8,43.6700::float8,'diyadin-kaplicalari','Termal kaynaklarıyla tanınan doğal alan.','Diyadin çevresindeki jeotermal kaynaklar bölgenin bilinen doğal ziyaret noktaları arasındadır; tesis ve erişim durumu ziyaret öncesi kontrol edilmelidir.','https://tr.wikipedia.org/wiki/Diyadin','["termal","jeotermal","doğa"]'),
 ('Diyadin Kanyonu','Doğa','Kanyon','Diyadin, Ağrı',39.5500::float8,43.6800::float8,'diyadin-kanyonu','Akarsu ve kaya oluşumlarıyla dikkat çeken doğal alan.','Diyadin çevresindeki kanyon manzaraları doğa gezileri için ilgi çekicidir; arazi koşullarına uygun ekipman ve dikkat gerekir.','https://tr.wikipedia.org/wiki/Diyadin','["kanyon","doğa","manzara"]'),
 ('Ağrı İbrahim Çeçen Üniversitesi Bilim ve Kültür Alanı','Kültür','Kent alanı','Merkez, Ağrı',39.7200::float8,43.0500::float8,'agri-kent-kultur-alani','Ağrı kent merkezinde modern kent yaşamını tanımaya yönelik durak.','Kent merkezindeki ziyaret planında çevredeki kamusal alanlar ve yerel yaşamla birlikte değerlendirilebilir.','https://www.agri.edu.tr/','["şehir","kültür"]'),
 ('Doğubayazıt Kalesi','Tarih','Kale kalıntısı','Doğubayazıt, Ağrı',39.5200::float8,44.1300::float8,'dogubayazit-kalesi','Eski Bayezid çevresindeki tarihî savunma yapısı kalıntıları.','İshak Paşa Sarayı ve eski yerleşim çevresindeki tarihî mirasın bir parçasıdır; kalıntılara erişim durumu yerinde kontrol edilmelidir.','https://tr.wikipedia.org/wiki/Do%C4%9Fubayaz%C4%B1t','["kale","tarih","arkeoloji"]')
) as v(name,category,place_type,address,lat,lon,slug,short_description,long_description,source_url,tags)
where not exists (
 select 1 from public.places p
 where lower(trim(p.city)) in ('ağrı','agri')
   and (lower(trim(p.name))=lower(trim(v.name)) or p.slug=trim(v.slug))
);