-- 081: Çorum'da bariz etiket hatası ve yinelenen OSM kayıtlarını temizle.
-- Turistik/korunmaya değer yerler olduğu belirsiz olan kayıtlar bu migration'da değiştirilmez.
UPDATE public.places
SET is_active = false,
    content_review_status = 'rejected'
WHERE city = 'Çorum'
  AND slug IN (
    'osm-node-6296118187', -- anlamsız "Simd8" etiketi
    'osm-node-2714205542', -- Çorum Saat Kulesi için daha iyi kaynaklı kayıt zaten var
    'osm-node-8646739117'  -- aynı konumdaki İtfaiye Parkı poligon kaydının yineleneni
  )
  AND is_active = true;
