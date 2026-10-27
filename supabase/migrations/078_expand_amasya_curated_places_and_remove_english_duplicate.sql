-- Add notable Amasya heritage sites listed by the Provincial Governorate/Culture Portal.
INSERT INTO public.places
(name,category,place_type,city,address,latitude,longitude,slug,short_description,long_description,source_url,external_source,verified,trust_score,is_active,content_review_status,tags)
SELECT v.name,v.category,v.place_type,v.city,v.address,v.latitude,v.longitude,v.slug,v.short_description,v.long_description,v.source_url,'curated_seed',false,85,true,'source_backed',v.tags::jsonb
FROM (VALUES
('Fethiye Camii','Tarihî Yapı','Cami','Amasya','Fethiye Mahallesi, Amasya Merkez',40.6540,35.8265,'curated-amasya-fethiye-camii','Bizans dönemine uzanan geçmişiyle dikkat çeken, kiliseden camiye dönüştürülmüş tarihî yapı.','Amasya’daki Fethiye Camii, eski bir Bizans kilisesinin Danişmendli döneminde camiye çevrilmesiyle oluşmuştur; yapının tarihî katmanları kentin çok dönemli mirasını yansıtır.','https://kulturportali.gov.tr/turkiye/amasya/gezilecekyer/fethye-cam','["tarih","mimari","inanç kültürü"]'),
('Gümüşlü Camii','Tarihî Yapı','Cami','Amasya','Gümüşlü Mahallesi, Amasya Merkez',40.6532,35.8310,'curated-amasya-gumuslu-camii','Osmanlı dönemi taş mimarisi ve kalem işi bezemeleriyle öne çıkan tarihî cami.','İlk kez 14. yüzyılda yaptırılan ve çeşitli yangın ve depremlerden sonra onarılan Gümüşlü Camii, Amasya merkezindeki önemli tarihî yapılardandır.','https://kulturportali.gov.tr/turkiye/amasya/gezilecekyer/gumuslu-camii','["tarih","mimari","Osmanlı"]'),
('Bayezid Paşa Camii','Tarihî Yapı','Cami','Amasya','Bayezid Paşa Mahallesi, Amasya Merkez',40.6550,35.8275,'curated-amasya-bayezid-pasa-camii','Erken Osmanlı döneminin Amasya’daki önemli tarihî camilerinden biri.','Bayezid Paşa Camii, Amasya’nın tarihî dini mimari mirasının parçalarındandır ve kentin eski mahalle dokusuyla birlikte ziyaret edilebilir.','https://amasya.ktb.gov.tr/TR-59524/diger-tarihi-yapilar.html','["tarih","mimari","Osmanlı"]'),
('Bimarhane (Darüşşifa)','Tarihî Yapı','Darüşşifa','Amasya','Merkez, Amasya',40.6525,35.8325,'curated-amasya-bimarhane-darussifa','Tıp tarihi ve mimarlık mirası açısından önemli tarihî darüşşifa.','Amasya’daki Bimarhane, tarihî sağlık yapıları arasında yer alır; kentin bilim, tıp ve mimarlık geçmişini tanıtan kültür duraklarından biridir.','https://amasya.ktb.gov.tr/TR-59524/diger-tarihi-yapilar.html','["tıp tarihi","mimari","tarih"]')
) AS v(name,category,place_type,city,address,latitude,longitude,slug,short_description,long_description,source_url,tags)
WHERE NOT EXISTS (SELECT 1 FROM public.places p WHERE p.slug=v.slug)
  AND NOT EXISTS (SELECT 1 FROM public.places p WHERE p.city=v.city AND lower(trim(p.name))=lower(trim(v.name)));

-- Deactivate only the English duplicate of the already curated Ferhat ile Şirin museum.
UPDATE public.places
SET is_active=false
WHERE city='Amasya' AND slug='osm-node-5113720182'
  AND name='Ferhat and Şirin Lovers Museum';