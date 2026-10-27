-- Correct the canonical Çimenlik Kalesi record and curate Anadolu Hamidiye separately.
UPDATE public.places
SET name = 'Çimenlik Kalesi ve Deniz Müzesi',
    category = 'Tarihî Yapı', place_type = 'Kale ve müze',
    short_description = 'Boğaz kıyısında Osmanlı dönemi kalesi ve denizcilik koleksiyonları.',
    long_description = 'Çimenlik Kalesi ve Deniz Müzesi, Çanakkale Boğazı’nın savunma tarihiyle denizcilik geçmişini bir arada tanıtan önemli bir ziyaret noktasıdır.',
    source_url = 'https://goturkiye.com/tr/canakkale/canakkale-rotalari',
    external_source = 'GoTürkiye', verified = true,
    trust_score = greatest(coalesce(trust_score, 0), 90),
    content_review_status = 'source_backed', is_active = true, updated_at = now()
WHERE city = 'Çanakkale' AND slug = 'cimenlik-kalesi-deniz-muzesi';
UPDATE public.places
SET name = 'Anadolu Hamidiye Tabyası',
    category = 'Tarihî Yapı', place_type = 'Tabya ve tarihî alan',
    short_description = 'Çanakkale savunma tarihini anlatan tabya ve açık hava ziyaret alanı.',
    long_description = 'Anadolu Hamidiye Tabyası, Çanakkale Boğazı savunma tarihini anlamak için ziyaret edilebilecek tarihî askerî yapılardandır. Alanı gezerken tabya düzeni ve savunma mimarisi incelenebilir.',
    source_url = 'https://canakkale.ktb.gov.tr/TR-70509/muze-ve-oren-yerleri.html',
    external_source = 'T.C. Kültür ve Turizm Bakanlığı', verified = true,
    trust_score = greatest(coalesce(trust_score, 0), 90),
    content_review_status = 'source_backed', is_active = true, updated_at = now()
WHERE city = 'Çanakkale' AND slug = 'osm-way-303002619';
UPDATE public.places
SET is_active = false, content_review_status = 'rejected', updated_at = now()
WHERE city = 'Çanakkale' AND slug = 'osm-node-10216826112';
