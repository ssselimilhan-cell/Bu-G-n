-- Continue curated Edirne catalogue and deactivate clearly irrelevant rejected OSM imports.
update public.places
set is_active = false
where city = 'Edirne'
  and is_active = true
  and content_review_status = 'rejected'
  and slug in (
    'osm-node-13702460411', -- Baca
    'osm-node-13761148207', -- Balıkçı Heykeli
    'osm-node-13188276616', -- Çardaklı/Eski Değirmen Yolu
    'osm-node-8292248396',  -- Çayırtarla Tepesi
    'osm-node-13184336632', -- Çukurçayır
    'osm-node-14025099157', -- Kıymet Teyze Parkı
    'osm-node-4244682598',  -- tavuk çiftliği
    'osm-node-3846398986',  -- Welcome to Asian Highway
    'osm-node-2579984324'   -- Cyrillic-only monument name
  );

insert into public.places
(name, category, place_type, city, address, latitude, longitude, slug, short_description, long_description, source_url, external_source, external_id, verified, trust_score, is_active, content_review_status, tags)
select v.name, v.category, v.place_type, 'Edirne', v.address, v.latitude, v.longitude, v.slug, v.short_description, v.long_description, v.source_url, 'curated_seed', v.external_id, false, 85, true, 'source_backed', to_jsonb(v.tags)
from (values
('Ekmekçizade Ahmet Paşa Kervansarayı','Tarih ve mimari','Kervansaray','Edirne merkez',41.6815,26.5590,'ekmekcizade-ahmet-pasa-kervansarayi','Osmanlı döneminden kalan tarihî kervansaray','Ekmekçizade Ahmet Paşa Kervansarayı, Edirne’nin Osmanlı dönemi ticaret ve konaklama mimarisini temsil eden tarihî yapılardandır.','https://edirne.ktb.gov.tr/TR-76381/gezilecek-yerler-ve-muzelerimiz.html','edirne-ekmekcizade-ahmet-pasa-kervansarayi',array['tarih','mimari','osmanlı']::text[]),
('Muradiye Camii','Tarih ve mimari','Tarihî cami','Muradiye, Edirne merkez',41.6840,26.5660,'muradiye-camii-edirne','Osmanlı dönemine ait tarihî cami','Muradiye Camii, Edirne’nin Osmanlı mimari mirasının önemli örneklerinden biridir; iç mekân süslemeleri ve tarihî çevresiyle bilinir.','https://goturkiye.com/tr/edirne/edirne-rotalari','edirne-muradiye-camii',array['tarih','mimari','osmanlı']::text[]),
('Deveci Hanı','Tarih ve mimari','Tarihî han','Edirne merkez',41.6778,26.5557,'deveci-hani-edirne','Tarihî şehir dokusundaki han yapısı','Deveci Hanı, Edirne’nin tarihî ticaret yapıları arasında yer alır ve şehir merkezindeki kültür rotasına dâhil edilebilir.','https://edirne.ktb.gov.tr/TR-76381/gezilecek-yerler-ve-muzelerimiz.html','edirne-deveci-hani',array['tarih','mimari','han']::text[]),
('Sokullu Mehmet Paşa Hamamı','Tarih ve mimari','Tarihî hamam','Edirne merkez',41.6785,26.5575,'sokullu-mehmet-pasa-hamami','Osmanlı hamam mimarisini temsil eden tarihî yapı','Sokullu Mehmet Paşa Hamamı, Edirne’nin tarihî yapı rotalarında anılan Osmanlı dönemi hamam yapılarındandır.','https://goturkiye.com/tr/edirne/edirne-rotalari','edirne-sokullu-mehmet-pasa-hamami',array['tarih','mimari','osmanlı']::text[]),
('Beylerbeyi Camii','Tarih ve mimari','Tarihî cami','Edirne merkez',41.6797,26.5595,'beylerbeyi-camii-edirne','Edirne’nin tarihî camilerinden biri','Beylerbeyi Camii, Edirne’nin Osmanlı dönemine uzanan tarihî dini mimari mirasının bir parçasıdır.','https://goturkiye.com/tr/edirne/edirne-rotalari','edirne-beylerbeyi-camii',array['tarih','mimari','osmanlı']::text[]),
('Gazimihal Köprüsü','Tarih ve mimari','Tarihî köprü','Edirne merkez, Tunca Nehri',41.6860,26.5480,'gazimihal-koprusu-edirne','Tunca üzerindeki tarihî köprü','Gazimihal Köprüsü, Edirne’nin tarihî ulaşım yapıları arasında yer alır ve Gazi Mihal Camii çevresindeki miras rotasıyla birlikte görülebilir.','https://goturkiye.com/tr/edirne/edirne-rotalari','edirne-gazimihal-koprusu',array['tarih','köprü','osmanlı']::text[])
) as v(name,category,place_type,address,latitude,longitude,slug,short_description,long_description,source_url,external_id,tags)
where not exists (
  select 1 from public.places p
  where p.city = 'Edirne' and (p.slug = v.slug or p.external_id = v.external_id)
);