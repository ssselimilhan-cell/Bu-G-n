-- Repair two legitimate Sinop visitor destinations mistakenly disabled in migration 075,
-- then add high-value Tokat destinations verified against public tourism sources.
update public.places
set is_active = true
where city = 'Sinop'
  and slug in ('osm-way-244779535','osm-node-2383029487');

insert into public.places
(name,category,place_type,city,address,latitude,longitude,slug,short_description,long_description,source_url,external_source,verified,trust_score,is_active,content_review_status,tags)
select v.name,v.category,v.place_type,v.city,v.address,v.lat,v.lon,v.slug,v.short_description,v.long_description,v.source_url,'curated_seed',false,85,true,'source_backed',v.tags::jsonb
from (values
('Ballıca Mağarası Tabiat Parkı','Doğa','mağara ve tabiat parkı','Tokat','Ballıca köyü, Pazar, Tokat',40.287,36.235,'curated-tokat-ballica-magarasi-tabiat-parki','Soğan sarkıtları ve geniş salonlarıyla öne çıkan, koruma altındaki mağara.','Pazar ilçesi yakınındaki Ballıca Mağarası, farklı salonları ve kendine özgü soğan sarkıtlarıyla Tokat’ın en önemli doğal miras alanlarından biridir.','https://tokat.ktb.gov.tr/TR-231640/tabiat-parklari.html','["mağara","tabiat parkı","pazar","doğa"]'),
('Zinav Gölü Tabiat Parkı','Doğa','göl ve tabiat parkı','Tokat','Yolüstü çevresi, Reşadiye, Tokat',40.500,37.170,'curated-tokat-zinav-golu-tabiat-parki','Ormanlarla çevrili göl ve yaban hayatı gözlem alanı.','Reşadiye ilçesindeki Zinav Gölü, çevresindeki orman dokusu ve kuş yaşamıyla doğa gezileri ve gözlem için öne çıkar.','https://www.kulturportali.gov.tr/turkiye/tokat/gezilecekyer/znav-golu','["göl","tabiat parkı","kuş gözlemi","reşadiye"]'),
('Kaz Gölü Yaban Hayatı Geliştirme Sahası','Doğa','sulak alan ve yaban hayatı sahası','Tokat','Kaz Gölü, Pazar-Turhal yolu çevresi, Tokat',40.450,36.330,'curated-tokat-kaz-golu-yaban-hayati','Göçmen ve yerli kuşların yaşam alanı olan sulak alan.','Kaz Gölü, çok sayıda yerli ve göçmen kuş türüne ev sahipliği yapan koruma alanıdır; kuş gözlemi ve doğa keşfi açısından önem taşır.','https://tokat.ktb.gov.tr/TR-231640/tabiat-parklari.html','["sulak alan","kuş gözlemi","yaban hayatı"]'),
('Latifoğlu Konağı Müze Evi','Kültür','tarihî konak ve müze','Tokat','Tokat Merkez, Tokat',40.313,36.554,'curated-tokat-latifoglu-konagi-muze-evi','18. yüzyıl Osmanlı-Barok sivil mimarisini yansıtan müze ev.','Tokat merkezindeki Latifoğlu Konağı, geleneksel konak düzeni ve bezemeli iç mekânıyla kentin sivil mimarlık mirasını tanıtır.','https://tokat.goturkiye.com/tr-tr/gor','["tarih","müze","konak","osmanlı"]'),
('Niksar Kalesi','Tarih','kale','Tokat','Niksar ilçe merkezi, Tokat',40.591,36.955,'curated-tokat-niksar-kalesi','Danişmendli döneminin önemli merkezlerinden Niksar’a hâkim tarihî kale.','Niksar’ın tarihî merkezine hâkim konumdaki kale, kentin Danişmendli ve sonraki dönemlerdeki stratejik önemini yansıtan başlıca miras alanlarındandır.','https://tokat.goturkiye.com/tr-tr/gor','["tarih","kale","niksar"]'),
('Zile Kalesi','Tarih','kale','Tokat','Zile ilçe merkezi, Tokat',40.304,35.886,'curated-tokat-zile-kalesi','Zile kent merkezindeki tarihî kale ve yerleşim simgesi.','Zile Kalesi, ilçe merkezinde yükselen tarihî savunma yapısıdır; çevresindeki kent dokusuyla birlikte ilçenin öne çıkan ziyaret noktalarındandır.','https://tokat.goturkiye.com/tr-tr/gor','["tarih","kale","zile"]')
) as v(name,category,place_type,city,address,lat,lon,slug,short_description,long_description,source_url,tags)
where not exists (select 1 from public.places p where p.slug=v.slug);