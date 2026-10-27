-- 089: Van, Uşak, Yalova ve Tekirdağ için resmî kaynak bağlantıları ve Türkçe açıklamalar.
UPDATE public.places SET name='Van Kalesi', source_url='https://van.ktb.gov.tr/TR-437548/tarihi-ve-turistik-yerler.html', short_description='Van Gölü kıyısında yükselen, Urartu döneminden izler taşıyan tarihî kale.', verified=true, trust_score=greatest(coalesce(trust_score,0),93), content_review_status='source_backed', updated_at=now()
WHERE city='Van' AND slug='osm-way-135564251' AND is_active=true;

UPDATE public.places SET name='Van Müzesi', source_url='https://van.ktb.gov.tr/TR-437096/van-muze-mudurlugu.html', short_description='Van ve çevresinin farklı dönemlerine ait arkeolojik ve kültürel eserlerini sergileyen müze.', verified=true, trust_score=greatest(coalesce(trust_score,0),92), content_review_status='source_backed', updated_at=now()
WHERE city='Van' AND slug='osm-way-895580700' AND is_active=true;

UPDATE public.places SET name='Çavuştepe Kalesi', source_url='https://van.ktb.gov.tr/TR-437548/tarihi-ve-turistik-yerler.html', short_description='Urartu döneminden kalıntılarıyla bilinen tarihî kale ve arkeolojik alan.', verified=true, trust_score=greatest(coalesce(trust_score,0),91), content_review_status='source_backed', updated_at=now()
WHERE city='Van' AND slug='osm-way-184072597' AND is_active=true;

UPDATE public.places SET name='Yürüyen Köşk', source_url='https://yalova.ktb.gov.tr/TR-75636/yuruyen-kosk.html', short_description='Atatürk’ün isteğiyle yanındaki çınarı korumak için raylar üzerinde kaydırılan tarihî köşk.', verified=true, trust_score=greatest(coalesce(trust_score,0),93), content_review_status='source_backed', updated_at=now()
WHERE city='Yalova' AND slug='osm-way-665876362' AND is_active=true;

UPDATE public.places SET name='Karaca Arboretum (Canlı Ağaç Müzesi)', source_url='https://yalova.ktb.gov.tr/TR-75625/arboretum-canli-agac-muzesi.html', short_description='Çok sayıda ağaç ve bitki türünü barındıran, bitki çeşitliliği odaklı arboretum.', verified=true, trust_score=greatest(coalesce(trust_score,0),90), content_review_status='source_backed', updated_at=now()
WHERE city='Yalova' AND slug='osm-way-562677594' AND is_active=true;

UPDATE public.places SET name='Uşak Arkeoloji Müzesi', source_url='https://usak.ktb.gov.tr/TR-295228/usak-ili.html', short_description='Uşak ve çevresindeki arkeolojik buluntuları tanıtan müze.', verified=true, trust_score=greatest(coalesce(trust_score,0),89), content_review_status='source_backed', updated_at=now()
WHERE city='Uşak' AND slug='osm-way-1038716853' AND is_active=true;

UPDATE public.places SET name='Tekirdağ Müzesi', source_url='https://tekirdag.ktb.gov.tr/TR-75776/tekirdag-muzesi.html', short_description='Tekirdağ ve çevresinin arkeolojik, taş eser ve etnografya koleksiyonlarını sergileyen müze.', verified=true, trust_score=greatest(coalesce(trust_score,0),92), content_review_status='source_backed', updated_at=now()
WHERE city='Tekirdağ' AND slug='osm-node-5806715469' AND is_active=true;

UPDATE public.places SET is_active=false, content_review_status='rejected', updated_at=now()
WHERE city='Van' AND slug='osm-node-12988266925' AND is_active=true;
