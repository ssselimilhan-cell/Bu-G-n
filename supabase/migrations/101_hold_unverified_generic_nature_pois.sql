-- Audit pass: hide unverified, template-described OSM topographic features pending individual visitor-value/source verification.
-- Records are retained; this is reversible and does not delete data.
WITH candidates AS (
  SELECT id
  FROM public.places
  WHERE is_active = true
    AND external_source = 'openstreetmap'
    AND source_url IS NULL
    AND verified = false
    AND content_review_status <> 'source_backed'
    AND place_type = 'Doğal güzellik'
    AND short_description ILIKE '%ziyaret edilebilecek bir noktadır%'
    AND name ~* '(tepe|tepesi|dağ|dağı|dag|yayla|zirve|sırtı|sirt|bayır|belen|kuyu|kaya|kayalık|kayalik|göl|gol|şelale|selale|vadi|boğaz|bogaz)'
)
UPDATE public.places p
SET is_active = false,
    content_review_status = 'needs_review',
    updated_at = now()
FROM candidates c
WHERE p.id = c.id;

-- Also put active, unverified OSM attractions with purely generic generated descriptions
-- and obviously non-destination names on hold. The first pass is deliberately narrow.
WITH candidates AS (
  SELECT id
  FROM public.places
  WHERE is_active = true
    AND external_source = 'openstreetmap'
    AND source_url IS NULL
    AND verified = false
    AND content_review_status <> 'source_backed'
    AND short_description ILIKE '%ziyaret edilebilecek bir noktadır%'
    AND (
      name ~* '^(höyük|tepe|dağ|dağı|seyir terası|anıt|heykel|türbe|mağara|kale kalıntısı|sur kalıntısı)$'
      OR name ~* '(apartmanı|akaryakıt|bakkal|market|oto yıkama|eczane|sanayi sitesi|otobüs durağı|trafo|yangın gözetleme kulesi)'
    )
)
UPDATE public.places p
SET is_active = false,
    content_review_status = 'needs_review',
    updated_at = now()
FROM candidates c
WHERE p.id = c.id;