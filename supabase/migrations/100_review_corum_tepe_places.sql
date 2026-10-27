-- Review Çorum entries whose names contain "tepe".
-- Unverified named hilltops are not promoted as visitor attractions merely because
-- they appear in OSM; keep their records for traceability but hide them from the app.
UPDATE public.places
SET is_active = false, content_review_status = 'rejected', updated_at = now()
WHERE city = 'Çorum'
  AND slug IN (
    'osm-node-2207857310', -- Ambardere Tepesi
    'osm-node-2208104738', -- Büyükbel Tepesi
    'osm-node-2207857313', -- Büyükgüney Tepesi
    'osm-node-2497499350', -- Güngörmez Tepesi
    'osm-node-2315554677', -- İmamönü Tepesi
    'osm-node-2497499390', -- Karakuz Tepesi
    'osm-node-2207857318', -- Kartal Tepesi
    'osm-node-2497499407', -- Kasımtaşı Tepesi
    'osm-node-2237456945', -- Kayarkuzu Tepesi
    'osm-node-2315552504', -- Kazın Tepesi
    'osm-node-2207857319', -- Kırıkbakır Tepesi
    'osm-node-2497499461', -- Kızıl Tepe
    'osm-node-2237456948', -- Sağcıyolu Tepesi
    'osm-node-2497499513'  -- Ulaştıranbaba Tepesi
  );
UPDATE public.places
SET name = 'Hamamtepe Höyüğü', category = 'Arkeoloji', place_type = 'Arkeolojik alan',
    short_description = 'Sarmaşa köyü yakınında, farklı dönemlere tarihlenen seramik buluntularıyla bilinen arkeolojik höyük.',
    long_description = 'Kültür ve Turizm Bakanlığının yayımladığı arkeolojik araştırma raporunda Çorum Merkez ilçesi Sarmaşa köyü sınırlarında tanımlanır. Raporda yüzey buluntularının MÖ 2. binyıl ve Klasik Dönem’e tarihlendiği belirtilir. Ziyaret koşulları ve sahadaki güncel koruma durumu ayrıca doğrulanmalıdır.',
    source_url = 'https://ukaas.ktb.gov.tr/Eklenti/130217%2C15arastirma2pdf.pdf?0=',
    external_source = 'T.C. Kültür ve Turizm Bakanlığı arkeolojik araştırma yayını',
    verified = true, trust_score = greatest(coalesce(trust_score, 0), 85),
    content_review_status = 'source_backed', is_active = true, updated_at = now()
WHERE city = 'Çorum' AND slug = 'osm-way-100617768';
-- Keep the two archaeological-site candidates in the database but hide them until
-- their identity, coordinates and public visitation status are confirmed.
UPDATE public.places
SET is_active = false, content_review_status = 'needs_review', updated_at = now()
WHERE city = 'Çorum' AND slug IN ('osm-node-4851703371', 'osm-way-100607426');
