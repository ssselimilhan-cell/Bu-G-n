-- Migration 086: Çankırı katalog gürültüsü ve kale mükerrer kaydı
-- Yalnızca açıkça turistik yer niteliği taşımayan harita POI'leri ve
-- kaynaklı katalog kaydı bulunan mükerrer kale noktası pasife alınır.

UPDATE public.places
SET is_active = false,
    content_review_status = 'rejected',
    updated_at = now()
WHERE city = 'Çankırı'
  AND slug IN (
    'osm-node-12376378529', -- "Gemi": bağlamsız, turistik yer değil
    'osm-node-12376378502', -- "Kucaklama taşı": doğrulanabilir ziyaret noktası değil
    'osm-way-1564781532'    -- Tenis kortu: genel spor POI'si
  );

UPDATE public.places
SET is_active = false,
    content_review_status = 'rejected',
    updated_at = now()
WHERE city = 'Çankırı'
  AND slug = 'osm-node-881887842'
  AND EXISTS (
    SELECT 1
    FROM public.places p
    WHERE p.city = 'Çankırı'
      AND p.slug = 'cankiri-kalesi-karatekin-bey-turbesi'
      AND p.is_active = true
  );
