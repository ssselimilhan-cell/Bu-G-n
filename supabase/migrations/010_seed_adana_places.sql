-- Seed a small, source-linked starter catalog so Adana's Explore tab is useful
-- immediately. Records stay in needs_review until their source details are checked.
insert into public.places
  (name, category, city, address, latitude, longitude, slug,
   short_description, long_description, source_url, external_source, external_id,
   verified, trust_score, is_active, content_review_status)
select v.name, v.category, 'Adana', v.address, v.latitude, v.longitude, v.slug,
       v.short_description, v.long_description, v.source_url, 'curated_seed',
       v.slug, false, 55, true, 'needs_review'
from (values
  ('Taşköprü','Tarih','Seyhan Nehri üzeri, Adana',36.9919::float8,35.3315::float8,'taskopru','Roma döneminden günümüze ulaşan tarihî taş köprü.','Adana’nın simge yapılarından Taşköprü, Seyhan Nehri üzerinde yer alır.','https://tr.wikipedia.org/wiki/Ta%C5%9Fk%C3%B6pr%C3%BC_(Adana)'),
  ('Sabancı Merkez Camii','Tarih','Reşatbey, Seyhan, Adana',36.9912::float8,35.3328::float8,'sabanci-merkez-camii','Seyhan Nehri kıyısındaki öne çıkan mimari yapılardan biri.','Sabancı Merkez Camii, Seyhan Nehri kıyısında yer alan büyük ölçekli bir camidir.','https://tr.wikipedia.org/wiki/Sabanc%C4%B1_Merkez_Camii'),
  ('Adana Ulu Camii','Tarih','Ali Münif Yeğenağa Caddesi, Seyhan, Adana',36.9864::float8,35.3252::float8,'adana-ulu-camii','Ramazanoğulları döneminden kalan tarihî cami ve külliye.','Adana Ulu Camii, kent merkezindeki önemli tarihî yapılardan biridir.','https://tr.wikipedia.org/wiki/Adana_Ulu_Camii'),
  ('Ramazanoğlu Konağı','Tarih','Ulu Cami çevresi, Seyhan, Adana',36.9861::float8,35.3246::float8,'ramazanoglu-konagi','Adana’nın tarihî merkezinde bulunan geleneksel konak yapısı.','Ramazanoğlu Konağı, Adana’nın tarihî merkezindeki kültürel miras noktalarındandır.','https://tr.wikipedia.org/wiki/Ramazano%C4%9Flu_Kona%C4%9F%C4%B1'),
  ('Adana Arkeoloji Müzesi','Müze','Döşeme Mahallesi, Seyhan, Adana',36.9910::float8,35.3258::float8,'adana-arkeoloji-muzesi','Çukurova ve çevresinin arkeolojik mirasını tanımak için müze.','Adana Arkeoloji Müzesi, bölgenin arkeolojik geçmişine ilişkin eserleri tanıtan bir kültür durağıdır.','https://tr.wikipedia.org/wiki/Adana_Arkeoloji_M%C3%BCzesi'),
  ('Adana Sinema Müzesi','Müze','Kayalıbağ Mahallesi, Seyhan, Adana',36.9895::float8,35.3236::float8,'adana-sinema-muzesi','Adana’nın sinema kültürüne odaklanan müze.','Adana Sinema Müzesi, kentle özdeşleşen sinema kültürünü ve sanatçılarını tanıtır.','https://tr.wikipedia.org/wiki/Adana_Sinema_M%C3%BCzesi'),
  ('Merkez Park','Park','Reşatbey, Seyhan, Adana',36.9918::float8,35.3310::float8,'merkez-park','Seyhan Nehri kıyısında yürüyüş ve açık havada dinlenme alanı.','Merkez Park, nehir kıyısındaki yeşil alanlarıyla yürüyüş ve dinlenme için tercih edilen bir kent parkıdır.','https://tr.wikipedia.org/wiki/Merkez_Park_(Adana)'),
  ('Büyük Saat','Tarih','Ali Münif Yeğenağa Caddesi, Seyhan, Adana',36.9860::float8,35.3254::float8,'buyuk-saat','Adana’nın tarihî merkezindeki simge saat kulesi.','Büyük Saat, Adana’nın tarihî merkezinde yer alan simge yapılardandır.','https://tr.wikipedia.org/wiki/B%C3%BCy%C3%BCk_Saat'),
  ('Varda Köprüsü','Doğa','Hacıkırı, Karaisalı, Adana',37.2510::float8,34.9750::float8,'varda-koprusu','Dağlık çevrede yer alan tarihî demiryolu köprüsü ve manzara noktası.','Varda Köprüsü, Karaisalı çevresinde yer alan tarihî bir demiryolu köprüsüdür; ulaşımı önceden planlamak gerekir.','https://tr.wikipedia.org/wiki/Varda_K%C3%B6pr%C3%BCs%C3%BC'),
  ('Kapıkaya Kanyonu','Doğa','Kapıkaya, Karaisalı, Adana',37.1130::float8,35.0640::float8,'kapikaya-kanyonu','Doğa yürüyüşü ve manzara için tercih edilen kanyon alanı.','Kapıkaya Kanyonu, Karaisalı ilçesi çevresinde doğa ve yürüyüş amacıyla ziyaret edilen bir alandır.','https://tr.wikipedia.org/wiki/Kap%C4%B1kaya_Kanyonu')
) as v(name,category,address,latitude,longitude,slug,short_description,long_description,source_url)
where not exists (
  select 1 from public.places p
  where lower(trim(p.city)) = 'adana'
    and lower(trim(p.name)) = lower(trim(v.name))
);
