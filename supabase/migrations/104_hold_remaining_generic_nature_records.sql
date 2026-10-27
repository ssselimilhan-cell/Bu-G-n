-- Hold remaining source-less nature records that have only boilerplate descriptions.
-- Keep sourced/curated destinations untouched; this is a review queue, not a deletion.
UPDATE public.places
SET is_active = false,
    content_review_status = 'needs_review',
    updated_at = now()
WHERE is_active = true
  AND verified = false
  AND source_url IS NULL
  AND coalesce(short_description, '') ILIKE '%doğal güzellik keşfetmek isteyenler için şehirde ziyaret edilebilecek bir noktadır%'
  AND (
    coalesce(name, '') ~* '(dağ|dag|tepe|zirve|yayla|sivrisi|kaya|şelale|selale|vadi|kanyon|göl|gol|orman|mağara|magara|doğa|doga|seyir|manzara|buzul|krater|pınar|pinar|dere|mesire|tabiat|sazlığı|sazligi)'
    OR coalesce(place_type, '') ~* '(doğal güzellik|nature|mountain|peak|hill|waterfall|lake|valley|viewpoint)'
  );

-- Remove two same-city, source-less duplicate mountain labels where the official park record is retained.
UPDATE public.places
SET is_active = false,
    content_review_status = 'needs_review',
    updated_at = now()
WHERE is_active = true
  AND city = 'Kastamonu'
  AND name = 'Ilgaz Dağı'
  AND slug IN ('osm-node-474971528', 'osm-node-1939431907')
  AND source_url ILIKE '%wikipedia.org%';
