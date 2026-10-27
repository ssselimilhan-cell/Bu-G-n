-- 088: Muğla, Muş, Osmaniye ve Zonguldak için kaynak doğrulaması ve bariz mükerrer temizliği.
UPDATE public.places SET name='Kerimoğlu Türküsü Evi', source_url='https://mugla.ktb.gov.tr/TR-296590/nereye-gidilir.html', short_description='Kerimoğlu Eyüp’ün yaşam öyküsü ve ünlü zeybek türküsüyle ilişkilendirilen, restore edilerek ziyarete açılmış tarihî ev.', verified=true, trust_score=greatest(coalesce(trust_score,0),90), content_review_status='source_backed', updated_at=now()
WHERE city='Muğla' AND slug='osm-node-1411943935' AND is_active=true;

UPDATE public.places SET name='Akyaka Plajı', source_url='https://mugla.ktb.gov.tr/TR-296420/ne-yapilir.html', short_description='Gökova kıyısında, sığ denizi ve çevresindeki doğal peyzajıyla bilinen sahil alanı.', verified=true, trust_score=greatest(coalesce(trust_score,0),88), content_review_status='source_backed', updated_at=now()
WHERE city='Muğla' AND slug='osm-way-252221647' AND is_active=true;

UPDATE public.places SET name='Tarihi Murat Köprüsü', source_url='https://mus.ktb.gov.tr/TR-321685/mus-gezi-rotalari.html', short_description='Muş-Varto yolu üzerinde Murat Nehri’ni geçen tarihî taş köprü.', verified=true, trust_score=greatest(coalesce(trust_score,0),90), content_review_status='source_backed', updated_at=now()
WHERE city='Muş' AND slug='osm-node-8639208584' AND is_active=true;

UPDATE public.places SET name='Muş Atatürk Şehir Müzesi', source_url='https://mus.ktb.gov.tr/TR-56130/gezilecek-yerler.html', short_description='Muş’un yerel tarihini ve kültürel mirasını tanımaya yönelik şehir müzesi.', verified=true, trust_score=greatest(coalesce(trust_score,0),87), content_review_status='source_backed', updated_at=now()
WHERE city='Muş' AND slug='osm-way-168719534' AND is_active=true;

UPDATE public.places SET name='Karatepe-Aslantaş Açık Hava Müzesi', source_url='https://osmaniye.ktb.gov.tr/TR-60812/muzeler-ve-orenyerleri.html', short_description='Geç Hitit dönemine ait kale yerleşimi, anıtsal kapıları ve yazıtlarıyla tanınan açık hava müzesi.', verified=true, trust_score=greatest(coalesce(trust_score,0),93), content_review_status='source_backed', updated_at=now()
WHERE city='Osmaniye' AND slug='osm-way-126603893' AND is_active=true;

UPDATE public.places SET name='Kastabala-Hierapolis Antik Kenti', source_url='https://osmaniye.ktb.gov.tr/TR-60828/muzeler-ve-orenyerleri.html', short_description='Ceyhan Nehri yakınındaki ovaya hâkim konumda, kale ve antik kent kalıntılarını bir arada barındıran arkeolojik alan.', verified=true, trust_score=greatest(coalesce(trust_score,0),92), content_review_status='source_backed', updated_at=now()
WHERE city='Osmaniye' AND slug='osm-way-353549847' AND is_active=true;

UPDATE public.places SET name='Osmaniye Müzesi', source_url='https://osmaniye.ktb.gov.tr/TR-60812/muzeler-ve-orenyerleri.html', short_description='Osmaniye ve çevresinin arkeolojik kültür varlıklarını tanıtan müze.', verified=true, trust_score=greatest(coalesce(trust_score,0),88), content_review_status='source_backed', updated_at=now()
WHERE city='Osmaniye' AND slug='osm-way-328237690' AND is_active=true;

UPDATE public.places SET name='Gökgöl Mağarası', source_url='https://zonguldak.ktb.gov.tr/TR-92811/magara-turizmi.html', short_description='Aydınlatılmış gezi güzergâhları ve damlataş oluşumlarıyla Zonguldak’ın öne çıkan mağaralarından biri.', verified=true, trust_score=greatest(coalesce(trust_score,0),92), content_review_status='source_backed', updated_at=now()
WHERE city='Zonguldak' AND slug='osm-node-4763076034' AND is_active=true;

UPDATE public.places SET name='Zonguldak Maden Müzesi', source_url='https://zonguldak.ktb.gov.tr/TR-92909/gezilecek-yerler.html', short_description='Zonguldak’ın kömür madenciliği tarihini ve kent kültüründeki yerini anlatan müze.', verified=true, trust_score=greatest(coalesce(trust_score,0),91), content_review_status='source_backed', updated_at=now()
WHERE city='Zonguldak' AND slug='osm-way-1303447545' AND is_active=true;

UPDATE public.places SET is_active=false, content_review_status='rejected', updated_at=now()
WHERE city='Muş' AND slug='osm-node-1550732894'
  AND EXISTS (SELECT 1 FROM public.places p WHERE p.city='Muş' AND p.slug='osm-node-8639208584' AND p.is_active=true);

UPDATE public.places SET is_active=false, content_review_status='rejected', updated_at=now()
WHERE city='Zonguldak' AND slug IN ('osm-node-12050192397','osm-way-1303447544')
  AND EXISTS (
    SELECT 1 FROM public.places p
    WHERE p.city='Zonguldak' AND p.is_active=true
      AND ((p.slug='osm-way-1303213231' AND p.name='Kapuz Plajı' AND public.places.slug='osm-node-12050192397')
        OR (p.slug='osm-way-1303447545' AND p.name='Zonguldak Maden Müzesi' AND public.places.slug='osm-way-1303447544'))
  );

UPDATE public.places SET is_active=false, content_review_status='rejected', updated_at=now()
WHERE city='Zonguldak' AND slug IN ('osm-node-12071415231','osm-node-12071415232')
  AND EXISTS (SELECT 1 FROM public.places p WHERE p.city='Zonguldak' AND p.slug='osm-way-1272559778' AND p.name='Varagel Tüneli' AND p.is_active=true);
