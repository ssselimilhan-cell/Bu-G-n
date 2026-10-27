-- 090: Elazığ, Erzincan, Eskişehir ve Gaziantep için kaynak doğrulaması ve mükerrer temizliği.
UPDATE public.places SET source_url='https://elazig.ktb.gov.tr/TR-58582/magara-turizmi.html', short_description='Harput’un kuzeydoğusunda yer alan, doğal buz oluşumlarıyla tanınan mağara; resmî kaynağa göre şu anda ziyarete kapalıdır.', verified=true, trust_score=greatest(coalesce(trust_score,0),89), content_review_status='source_backed', updated_at=now()
WHERE city='Elazığ' AND slug='buzluk-magarasi' AND is_active=true;

UPDATE public.places SET source_url='https://elazig.ktb.gov.tr/TR-245739/olbe-vadisi.html', short_description='Harput yakınındaki tarihî kervan yolu, doğal oluşumlar ve yürüyüş rotalarıyla öne çıkan vadi.', verified=true, trust_score=greatest(coalesce(trust_score,0),90), content_review_status='source_backed', updated_at=now()
WHERE city='Elazığ' AND slug='olbe-vadisi' AND is_active=true;

UPDATE public.places SET source_url='https://erzincan.ktb.gov.tr/TR-57407/mesire-yerleri.html', short_description='Erzincan’ın güneydoğusunda, doğal çağlayanları ve serin ortamıyla bilinen şelale.', verified=true, trust_score=greatest(coalesce(trust_score,0),92), content_review_status='source_backed', updated_at=now()
WHERE city='Erzincan' AND slug='girlevik-selalesi' AND is_active=true;

UPDATE public.places SET source_url='https://eskisehir.ktb.gov.tr/TR-339469/eti-arkeoloji-muzesi-odunpazari.html', short_description='Eskişehir ve çevresindeki arkeolojik kazılardan elde edilen eserleri kronolojik olarak sergileyen müze.', verified=true, trust_score=greatest(coalesce(trust_score,0),92), content_review_status='source_backed', updated_at=now()
WHERE city='Eskişehir' AND slug='osm-node-2397675612' AND is_active=true;

UPDATE public.places SET name='Tarihi Odunpazarı Evleri', source_url='https://eskisehir.ktb.gov.tr/TR-362647/odunpazari.html', short_description='Geleneksel sivil mimarisi, dar sokakları ve restore edilmiş tarihî evleriyle kentin kültürel dokusunu yansıtan bölge.', verified=true, trust_score=greatest(coalesce(trust_score,0),92), content_review_status='source_backed', updated_at=now()
WHERE city='Eskişehir' AND slug='tarihi-odunpazari-evleri' AND is_active=true;

UPDATE public.places SET source_url='https://gaziantep.ktb.gov.tr/TR-131846/muzeler.html', short_description='Roma döneminden mozaik koleksiyonuyla öne çıkan, Zeugma ve çevresindeki buluntuları sergileyen müze.', verified=true, trust_score=greatest(coalesce(trust_score,0),94), content_review_status='source_backed', updated_at=now()
WHERE city='Gaziantep' AND slug='zeugma-mozaik-muzesi' AND is_active=true;

UPDATE public.places SET source_url='https://gaziantep.ktb.gov.tr/TR-131688/antik-kentler.html', short_description='Fırat kıyısındaki antik kent; Helenistik dönemden Roma ve Bizans dönemlerine uzanan yerleşim geçmişiyle bilinir.', verified=true, trust_score=greatest(coalesce(trust_score,0),93), content_review_status='source_backed', updated_at=now()
WHERE city='Gaziantep' AND slug='zeugma-antik-kenti' AND is_active=true;

UPDATE public.places SET is_active=false, content_review_status='rejected', updated_at=now()
WHERE (city='Elazığ' AND slug='osm-way-97700117' AND EXISTS (SELECT 1 FROM public.places p WHERE p.city='Elazığ' AND p.slug='harput-kalesi' AND p.is_active=true))
   OR (city='Erzincan' AND slug='osm-node-6482303685' AND EXISTS (SELECT 1 FROM public.places p WHERE p.city='Erzincan' AND p.slug='girlevik-selalesi' AND p.is_active=true))
   OR (city='Eskişehir' AND slug IN ('osm-node-2397678980','osm-node-11958098769') AND EXISTS (SELECT 1 FROM public.places p WHERE p.city='Eskişehir' AND p.is_active=true AND ((p.slug='cagdas-cam-sanatlari-muzesi' AND public.places.slug='osm-node-2397678980') OR (p.slug='devrim-arabalari-muzesi' AND public.places.slug='osm-node-11958098769'))));
